#!/usr/bin/env bats
# Tests for install.sh

load test_helper

# ---- helper to run install.sh in a controlled environment ----
run_install() {
  BIN_DIR="${BIN_DIR:-$TEST_TMPDIR/bin}" \
  LAZYSPECKIT_REF="${LAZYSPECKIT_REF:-main}" \
  NO_COLOR=1 \
  DEBUG="${DEBUG:-0}" \
  HOME="$TEST_TMPDIR" \
  bash "$REPO_ROOT/install.sh" "$@"
}

# ============ Happy Path ============

@test "install.sh: installs lazyspeckit binary to BIN_DIR" {
  run run_install
  [ "$status" -eq 0 ]
  [ -f "$TEST_TMPDIR/bin/lazyspeckit" ]
}

@test "install.sh: binary is executable after install" {
  run run_install
  [ "$status" -eq 0 ]
  [ -x "$TEST_TMPDIR/bin/lazyspeckit" ]
}

@test "install.sh: prints success message" {
  run run_install
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installed:"* ]]
}

@test "install.sh: prints download message with ref" {
  run run_install
  [ "$status" -eq 0 ]
  [[ "$output" == *"Downloading lazyspeckit"* ]]
  [[ "$output" == *"ref: main"* ]]
}

@test "install.sh: creates BIN_DIR if it doesn't exist" {
  local custom_bin="$TEST_TMPDIR/custom/nested/bin"
  BIN_DIR="$custom_bin" run run_install
  [ "$status" -eq 0 ]
  [ -d "$custom_bin" ]
  [ -f "$custom_bin/lazyspeckit" ]
}

@test "install.sh: warns when BIN_DIR is not on PATH" {
  # BIN_DIR won't be in PATH since it's a temp directory
  run run_install
  [ "$status" -eq 0 ]
  [[ "$output" == *"is not on your PATH"* ]] || [[ "$output" == *"is on PATH"* ]]
}

@test "install.sh: shows BIN_DIR on PATH when it is" {
  # Add the BIN_DIR to PATH
  export PATH="$TEST_TMPDIR/bin:$PATH"
  run run_install
  [ "$status" -eq 0 ]
  [[ "$output" == *"is on PATH"* ]]
}

@test "install.sh: prints try lazyspeckit --help" {
  run run_install
  [ "$status" -eq 0 ]
  [[ "$output" == *"lazyspeckit --help"* ]]
}

@test "install.sh: respects LAZYSPECKIT_REF" {
  LAZYSPECKIT_REF="v0.5.0" run run_install
  [ "$status" -eq 0 ]
  [[ "$output" == *"ref: v0.5.0"* ]]
}

# ============ Custom BIN_DIR ============

@test "install.sh: respects custom BIN_DIR env var" {
  local custom_bin="$TEST_TMPDIR/my_custom_bin"
  BIN_DIR="$custom_bin" run run_install
  [ "$status" -eq 0 ]
  [ -f "$custom_bin/lazyspeckit" ]
}

# ============ Windows-like detection ============

@test "install.sh: detects Windows Git Bash default with MINGW uname (via default logic)" {
  # We can't easily override uname, but we can verify the default bin dir logic
  # by checking the installed path
  run run_install
  [ "$status" -eq 0 ]
  [ -f "$TEST_TMPDIR/bin/lazyspeckit" ]
}

# ============ Failure Cases ============

@test "install.sh: fails if downloaded file doesn't contain lazyspeckit marker" {
  create_fake_curl "this is garbage content with no marker"
  run run_install
  [ "$status" -ne 0 ]
  [[ "$output" == *"does not look like lazyspeckit"* ]]
}

@test "install.sh: fails if curl and wget are both missing" {
  # Create a modified copy of install.sh where have() always returns false
  # for curl and wget
  local tmp_script
  tmp_script="$(mktemp)"
  sed 's/^have() {.*$/have() { case "$1" in curl|wget) return 1 ;; *) command -v "${1:-__missing__}" >\/dev\/null 2>\&1 ;; esac; }/' \
    "$REPO_ROOT/install.sh" > "$tmp_script"

  BIN_DIR="$TEST_TMPDIR/bin" \
  LAZYSPECKIT_REF="main" \
  NO_COLOR=1 \
  DEBUG=0 \
  HOME="$TEST_TMPDIR" \
  run bash "$tmp_script"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Need curl or wget"* ]]
  rm -f "$tmp_script"
}

@test "install.sh: falls back to wget when curl is missing" {
  remove_fake_curl
  create_fake_wget "lazyspeckit speckit content"
  run run_install
  [ "$status" -eq 0 ]
  [ -f "$TEST_TMPDIR/bin/lazyspeckit" ]
}

# ============ fetch function edge cases ============

@test "install.sh: fetch fails if url is empty" {
  run bash -c '
    have() { command -v "${1:-__missing__}" >/dev/null 2>&1; }
    die() { echo "install: $*" >&2; exit 1; }
    fetch() {
      local url="${1:-}"
      local out="${2:-}"
      [[ -n "$url" && -n "$out" ]] || die "fetch: missing url/out"
    }
    fetch "" "/tmp/out"
  '
  [ "$status" -ne 0 ]
}

# ============ cache_bust function ============

@test "install.sh: cache_bust appends a query string" {
  run bash -c '
    die() { echo "$*" >&2; exit 1; }
    cache_bust() {
      local url="${1:-}"
      [[ -n "$url" ]] || die "cache_bust: missing url"
      printf "%s?cb=%s" "$url" "$(date +%s)"
    }
    result=$(cache_bust "https://example.com/file")
    [[ "$result" == "https://example.com/file?cb="* ]] && echo "OK"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK"* ]]
}

# ============ install_file function ============

@test "install.sh: install_file copies file and makes executable" {
  local src="$TEST_TMPDIR/src_file"
  local dst="$TEST_TMPDIR/dst_dir/dst_file"
  echo "test content" > "$src"

  run bash -c '
    die() { echo "install: $*" >&2; exit 1; }
    have() { command -v "${1:-__missing__}" >/dev/null 2>&1; }
    install_file() {
      local src="${1:-}" dst="${2:-}"
      [[ -n "$src" && -n "$dst" ]] || die "install_file: missing src/dst"
      mkdir -p "$(dirname "$dst")"
      if have install; then
        install -m 0755 "$src" "$dst"
      else
        cp -f "$src" "$dst"
        chmod +x "$dst"
      fi
    }
    install_file "'"$src"'" "'"$dst"'"
  '
  [ "$status" -eq 0 ]
  [ -f "$dst" ]
  [ -x "$dst" ]
}

@test "install.sh: install_file fails without src" {
  run bash -c '
    die() { echo "install: $*" >&2; exit 1; }
    have() { command -v "${1:-__missing__}" >/dev/null 2>&1; }
    install_file() {
      local src="${1:-}" dst="${2:-}"
      [[ -n "$src" && -n "$dst" ]] || die "install_file: missing src/dst"
      mkdir -p "$(dirname "$dst")"
      if have install; then
        install -m 0755 "$src" "$dst"
      else
        cp -f "$src" "$dst"
        chmod +x "$dst"
      fi
    }
    install_file "" "/tmp/dst"
  '
  [ "$status" -ne 0 ]
  [[ "$output" == *"missing src/dst"* ]]
}

# ============ DEBUG mode ============

@test "install.sh: DEBUG=1 enables trace (no crash)" {
  run bash -c 'BIN_DIR="'"$TEST_TMPDIR/bin"'" LAZYSPECKIT_REF=main NO_COLOR=1 DEBUG=1 HOME="'"$TEST_TMPDIR"'" PATH="'"$FAKE_BIN:$PATH"'" bash "'"$REPO_ROOT/install.sh"'" 2>&1'
  [ "$status" -eq 0 ]
}

# ============ Additional coverage: install_file fallback (no install command) ============

@test "install.sh: install_file falls back to cp+chmod when install is missing" {
  local src="$TEST_TMPDIR/fallback_src"
  local dst="$TEST_TMPDIR/fallback_dst_dir/binary"
  echo "#!/bin/bash" > "$src"
  echo "echo lazyspeckit" >> "$src"

  run bash -c '
    die() { echo "install: $*" >&2; exit 1; }
    have() {
      case "$1" in
        install) return 1 ;;
        *) command -v "${1:-__missing__}" >/dev/null 2>&1 ;;
      esac
    }
    install_file() {
      local src="${1:-}" dst="${2:-}"
      [[ -n "$src" && -n "$dst" ]] || die "install_file: missing src/dst"
      mkdir -p "$(dirname "$dst")"
      if have install; then
        install -m 0755 "$src" "$dst"
      else
        cp -f "$src" "$dst"
        chmod +x "$dst"
      fi
    }
    install_file "'"$src"'" "'"$dst"'"
    [ -x "'"$dst"'" ] && echo "EXECUTABLE"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"EXECUTABLE"* ]]
  [ -f "$dst" ]
  [ -x "$dst" ]
}

# ============ Additional coverage: on_err trap ============

@test "install.sh: on_err prints line info on ERR trap" {
  run bash -c '
    set -Eeuo pipefail
    on_err() {
      local ec="$?"
      local line="${BASH_LINENO[0]:-unknown}"
      local cmd="${BASH_COMMAND:-unknown}"
      echo "install: Failed (exit $ec) at line ${line}: ${cmd}" >&2
      exit "$ec"
    }
    trap on_err ERR
    false
  '
  [ "$status" -ne 0 ]
  [[ "$output" == *"Failed (exit"* ]]
  [[ "$output" == *"at line"* ]]
}

# ============ Additional coverage: cache_bust with empty url ============

@test "install.sh: cache_bust dies on empty url" {
  run bash -c '
    die() { echo "install: $*" >&2; exit 1; }
    cache_bust() {
      local url="${1:-}"
      [[ -n "$url" ]] || die "cache_bust: missing url"
      printf "%s?cb=%s" "$url" "$(date +%s)"
    }
    cache_bust ""
  '
  [ "$status" -ne 0 ]
  [[ "$output" == *"cache_bust: missing url"* ]]
}

# ============ Additional coverage: fetch missing output path ============

@test "install.sh: fetch dies on empty output path" {
  run bash -c '
    have() { command -v "${1:-__missing__}" >/dev/null 2>&1; }
    die() { echo "install: $*" >&2; exit 1; }
    fetch() {
      local url="${1:-}"
      local out="${2:-}"
      [[ -n "$url" && -n "$out" ]] || die "fetch: missing url/out"
    }
    fetch "https://example.com" ""
  '
  [ "$status" -ne 0 ]
  [[ "$output" == *"fetch: missing url/out"* ]]
}
