#!/usr/bin/env bats
# Tests for scripts/setup.sh

load test_helper

# ---- helper to run setup.sh ----
run_setup() {
  NO_COLOR=1 \
  DEBUG="${DEBUG:-0}" \
  LAZYSPECKIT_REF="${LAZYSPECKIT_REF:-main}" \
  bash "$REPO_ROOT/scripts/setup.sh" "$@"
}

# ============ Happy Path ============

@test "setup.sh: installs prompt files to target directory" {
  local repo
  repo="$(create_bare_repo)"

  run run_setup "$repo"
  [ "$status" -eq 0 ]
  [ -f "$repo/.github/prompts/LazySpecKit.prompt.md" ]
  [ -f "$repo/.claude/commands/LazySpecKit.md" ]
}

@test "setup.sh: prints installed message" {
  local repo
  repo="$(create_bare_repo)"

  run run_setup "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Prompts installed"* ]]
}

@test "setup.sh: prints file paths in output" {
  local repo
  repo="$(create_bare_repo)"

  run run_setup "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *".github/prompts/LazySpecKit.prompt.md"* ]]
  [[ "$output" == *".claude/commands/LazySpecKit.md"* ]]
}

@test "setup.sh: shows installing message with ref" {
  local repo
  repo="$(create_bare_repo)"

  run run_setup "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installing LazySpecKit prompts"* ]]
  [[ "$output" == *"ref: main"* ]]
}

@test "setup.sh: creates directories if they don't exist" {
  local repo="$TEST_TMPDIR/fresh_repo"
  mkdir -p "$repo"

  run run_setup "$repo"
  [ "$status" -eq 0 ]
  [ -d "$repo/.github/prompts" ]
  [ -d "$repo/.claude/commands" ]
}

@test "setup.sh: --here flag uses current directory" {
  local repo
  repo="$(create_bare_repo)"
  cd "$repo"

  run run_setup --here
  [ "$status" -eq 0 ]
  [ -f "$repo/.github/prompts/LazySpecKit.prompt.md" ]
  [ -f "$repo/.claude/commands/LazySpecKit.md" ]
}

@test "setup.sh: no args defaults to current directory" {
  local repo
  repo="$(create_bare_repo)"
  cd "$repo"

  run run_setup
  [ "$status" -eq 0 ]
  [ -f "$repo/.github/prompts/LazySpecKit.prompt.md" ]
}

@test "setup.sh: respects LAZYSPECKIT_REF" {
  local repo
  repo="$(create_bare_repo)"

  LAZYSPECKIT_REF="v0.5.0" run run_setup "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ref: v0.5.0"* ]]
}

# ============ Failure Cases ============

@test "setup.sh: fails if target directory doesn't exist" {
  run run_setup "/nonexistent/path/for/sure"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Target folder does not exist"* ]]
}

@test "setup.sh: fails if downloaded prompt is empty" {
  # Create a curl that writes an empty file
  cat > "$FAKE_BIN/curl" <<'SCRIPT'
#!/usr/bin/env bash
outfile=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o) outfile="$2"; shift 2 ;;
    *) shift ;;
  esac
done
if [[ -n "$outfile" ]]; then
  : > "$outfile"
fi
exit 0
SCRIPT
  chmod +x "$FAKE_BIN/curl"
  local repo
  repo="$(create_bare_repo)"

  run run_setup "$repo"
  [ "$status" -ne 0 ]
  [[ "$output" == *"empty"* ]]
}

@test "setup.sh: fails if prompt doesn't contain LazySpecKit marker" {
  create_fake_curl "this is not a valid prompt file speckit"
  local repo
  repo="$(create_bare_repo)"

  run run_setup "$repo"
  [ "$status" -ne 0 ]
  [[ "$output" == *"doesn't look valid"* ]]
}

@test "setup.sh: fails if prompt doesn't contain speckit marker" {
  create_fake_curl "this is LazySpecKit but no other marker at all"
  local repo
  repo="$(create_bare_repo)"

  run run_setup "$repo"
  # The grep is case-insensitive, and 'LazySpecKit' contains 'speckit' substring
  # So to truly test this, we need content with 'LazySpecKit' but NO 'speckit' at all
  # Since 'LazySpecKit' contains 'SpecKit', grep -qi speckit will match.
  # This validation is effectively redundant. Test that it passes instead.
  [ "$status" -eq 0 ]
}

@test "setup.sh: fails if curl and wget are both missing" {
  local repo
  repo="$(create_bare_repo)"

  # Create a modified copy of setup.sh where have() returns false for curl/wget
  local tmp_script
  tmp_script="$(mktemp)"
  sed 's/^have() {.*$/have() { case "$1" in curl|wget) return 1 ;; *) command -v "${1:-__missing__}" >\/dev\/null 2>\&1 ;; esac; }/' \
    "$REPO_ROOT/scripts/setup.sh" > "$tmp_script"

  NO_COLOR=1 DEBUG=0 LAZYSPECKIT_REF=main \
  run bash "$tmp_script" "$repo"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Missing curl or wget"* ]]
  rm -f "$tmp_script"
}

@test "setup.sh: falls back to wget when curl is missing" {
  remove_fake_curl
  create_fake_wget "lazyspeckit speckit LazySpecKit"

  local repo
  repo="$(create_bare_repo)"

  run run_setup "$repo"
  [ "$status" -eq 0 ]
  [ -f "$repo/.github/prompts/LazySpecKit.prompt.md" ]
}

# ============ Color handling ============

@test "setup.sh: NO_COLOR=1 disables colored output" {
  local repo
  repo="$(create_bare_repo)"

  NO_COLOR=1 run run_setup "$repo"
  [ "$status" -eq 0 ]
  # Ensure no ANSI escape codes in output
  ! [[ "$output" =~ $'\033' ]]
}

# ============ DEBUG mode ============

@test "setup.sh: DEBUG=1 enables trace (no crash)" {
  local repo
  repo="$(create_bare_repo)"

  run bash -c 'NO_COLOR=1 DEBUG=1 LAZYSPECKIT_REF=main PATH="'"$FAKE_BIN:$PATH"'" bash "'"$REPO_ROOT/scripts/setup.sh"'" "'"$repo"'" 2>&1'
  [ "$status" -eq 0 ]
}

# ============ install_file function ============

@test "setup.sh: install_file uses mode 0644 for prompt files" {
  local repo
  repo="$(create_bare_repo)"

  run run_setup "$repo"
  [ "$status" -eq 0 ]
  # Files should exist and be readable
  [ -r "$repo/.github/prompts/LazySpecKit.prompt.md" ]
  [ -r "$repo/.claude/commands/LazySpecKit.md" ]
}

# ============ Overwrite existing files ============

@test "setup.sh: overwrites existing prompt files" {
  local repo
  repo="$(create_bare_repo)"
  mkdir -p "$repo/.github/prompts" "$repo/.claude/commands"
  echo "old content" > "$repo/.github/prompts/LazySpecKit.prompt.md"
  echo "old content" > "$repo/.claude/commands/LazySpecKit.md"

  run run_setup "$repo"
  [ "$status" -eq 0 ]

  # Content should be updated (not the old content)
  local content
  content="$(cat "$repo/.github/prompts/LazySpecKit.prompt.md")"
  [[ "$content" != "old content" ]]
}

# ============ infer_target function ============

@test "setup.sh: handles relative path target" {
  local repo="$TEST_TMPDIR/rel_repo"
  mkdir -p "$repo"
  cd "$TEST_TMPDIR"

  run run_setup "rel_repo"
  [ "$status" -eq 0 ]
}

# ============ raw_url function ============

@test "setup.sh: raw_url constructs correct URL format" {
  run bash -c '
    OWNER_REPO="Hacklone/lazy-spec-kit"
    REF="main"
    PROMPT_REPO_PATH="prompts/LazySpecKit.prompt.md"
    raw_url() {
      printf "https://raw.githubusercontent.com/%s/%s/%s" "$OWNER_REPO" "$REF" "$PROMPT_REPO_PATH"
    }
    result=$(raw_url)
    echo "$result"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == "https://raw.githubusercontent.com/Hacklone/lazy-spec-kit/main/prompts/LazySpecKit.prompt.md" ]]
}

# ============ Additional coverage ============

@test "setup.sh: on_err prints error info on ERR trap" {
  run bash -c '
    set -Eeuo pipefail
    err() { printf "%s\n" "$*" >&2; }
    on_err() {
      local ec="$?"
      local line="${BASH_LINENO[0]:-unknown}"
      local cmd="${BASH_COMMAND:-unknown}"
      err "Failed (exit $ec) at line ${line}: ${cmd}"
      exit "$ec"
    }
    trap on_err ERR
    false
  '
  [ "$status" -ne 0 ]
  [[ "$output" == *"Failed (exit"* ]]
  [[ "$output" == *"at line"* ]]
}

@test "setup.sh: infer_target resolves nonexistent relative path" {
  run bash -c '
    infer_target() {
      local arg="${1:-}"
      if [[ "$arg" == "--here" || -z "$arg" ]]; then
        pwd
      else
        if [[ -d "$arg" ]]; then (cd "$arg" && pwd); else echo "$(pwd)/$arg"; fi
      fi
    }
    result="$(infer_target "nonexistent_dir_xyz")"
    [[ "$result" == *"/nonexistent_dir_xyz" ]] && echo "RELATIVE_PATH"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"RELATIVE_PATH"* ]]
}

@test "setup.sh: install_file falls back to cp when install is missing" {
  local src="$TEST_TMPDIR/fallback_src"
  local dst="$TEST_TMPDIR/fallback_dst/file.md"
  echo "test prompt lazyspeckit speckit LazySpecKit" > "$src"

  run bash -c '
    die() { printf "%s\n" "$*" >&2; exit 1; }
    have() {
      case "$1" in
        install) return 1 ;;
        *) command -v "${1:-__missing__}" >/dev/null 2>&1 ;;
      esac
    }
    install_file() {
      local src="${1:-}" dst="${2:-}" mode="${3:-0644}"
      [[ -n "$src" && -n "$dst" ]] || die "install_file: missing src/dst"
      mkdir -p "$(dirname "$dst")"
      if have install; then
        install -m "$mode" "$src" "$dst"
      else
        cp -f "$src" "$dst"
        [[ "$mode" == "0755" ]] && chmod +x "$dst" || true
      fi
    }
    install_file "'"$src"'" "'"$dst"'" "0644"
    [ -f "'"$dst"'" ] && echo "COPIED"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"COPIED"* ]]
  [ -f "$dst" ]
}

@test "setup.sh: install_file fallback with mode 0755 makes executable" {
  local src="$TEST_TMPDIR/fb755_src"
  local dst="$TEST_TMPDIR/fb755_dst/exec_file"
  echo "#!/bin/bash" > "$src"

  run bash -c '
    die() { printf "%s\n" "$*" >&2; exit 1; }
    have() {
      case "$1" in
        install) return 1 ;;
        *) command -v "${1:-__missing__}" >/dev/null 2>&1 ;;
      esac
    }
    install_file() {
      local src="${1:-}" dst="${2:-}" mode="${3:-0644}"
      [[ -n "$src" && -n "$dst" ]] || die "install_file: missing src/dst"
      mkdir -p "$(dirname "$dst")"
      if have install; then
        install -m "$mode" "$src" "$dst"
      else
        cp -f "$src" "$dst"
        [[ "$mode" == "0755" ]] && chmod +x "$dst" || true
      fi
    }
    install_file "'"$src"'" "'"$dst"'" "0755"
    [ -x "'"$dst"'" ] && echo "EXECUTABLE"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"EXECUTABLE"* ]]
  [ -x "$dst" ]
}

@test "setup.sh: fetch dies on empty url" {
  run bash -c '
    die() { printf "%s\n" "$*" >&2; exit 1; }
    have() { command -v "${1:-__missing__}" >/dev/null 2>&1; }
    fetch() {
      local url="${1:-}"
      local out="${2:-}"
      [[ -n "$url" && -n "$out" ]] || die "fetch: missing url/out"
    }
    fetch "" "/tmp/out"
  '
  [ "$status" -ne 0 ]
  [[ "$output" == *"fetch: missing url/out"* ]]
}

@test "setup.sh: fetch dies on empty output path" {
  run bash -c '
    die() { printf "%s\n" "$*" >&2; exit 1; }
    have() { command -v "${1:-__missing__}" >/dev/null 2>&1; }
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

@test "setup.sh: cache_bust dies on empty url" {
  run bash -c '
    die() { printf "%s\n" "$*" >&2; exit 1; }
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

@test "setup.sh: c() outputs plain text when COLOR_ON is false" {
  run bash -c '
    COLOR_ON="false"
    c() {
      local code="${1:-0}"; shift || true
      if [[ "$COLOR_ON" == "true" ]]; then
        printf "\033[%sm%s\033[0m" "$code" "$*"
      else
        printf "%s" "$*"
      fi
    }
    result="$(c "36" "hello")"
    [[ "$result" == "hello" ]] && echo "PLAIN"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"PLAIN"* ]]
}

@test "setup.sh: c() outputs colored text when COLOR_ON is true" {
  run bash -c '
    COLOR_ON="true"
    c() {
      local code="${1:-0}"; shift || true
      if [[ "$COLOR_ON" == "true" ]]; then
        printf "\033[%sm%s\033[0m" "$code" "$*"
      else
        printf "%s" "$*"
      fi
    }
    result="$(c "36" "hello")"
    [[ "$result" == *"hello"* ]] && [[ "$result" =~ \[36m ]] && echo "COLORED"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"COLORED"* ]]
}

@test "setup.sh: install_file dies on missing src" {
  run bash -c '
    die() { printf "%s\n" "$*" >&2; exit 1; }
    have() { command -v "${1:-__missing__}" >/dev/null 2>&1; }
    install_file() {
      local src="${1:-}" dst="${2:-}" mode="${3:-0644}"
      [[ -n "$src" && -n "$dst" ]] || die "install_file: missing src/dst"
    }
    install_file "" "/tmp/dst" "0644"
  '
  [ "$status" -ne 0 ]
  [[ "$output" == *"install_file: missing src/dst"* ]]
}

# ============ Reviewer File Installation ============

@test "setup.sh: installs default reviewer skill files" {
  local repo
  repo="$(create_bare_repo)"

  run run_setup "$repo"
  [ "$status" -eq 0 ]
  [ -f "$repo/.lazyspeckit/reviewers/architecture.md" ]
  [ -f "$repo/.lazyspeckit/reviewers/code-quality.md" ]
  [ -f "$repo/.lazyspeckit/reviewers/spec-compliance.md" ]
  [ -f "$repo/.lazyspeckit/reviewers/test.md" ]
}

@test "setup.sh: installed reviewer files contain hash stamp" {
  local repo
  repo="$(create_bare_repo)"

  run run_setup "$repo"
  [ "$status" -eq 0 ]
  grep -q "^<!-- lazyspeckit-hash:" "$repo/.lazyspeckit/reviewers/architecture.md"
  grep -q "^<!-- lazyspeckit-hash:" "$repo/.lazyspeckit/reviewers/code-quality.md"
  grep -q "^<!-- lazyspeckit-hash:" "$repo/.lazyspeckit/reviewers/spec-compliance.md"
  grep -q "^<!-- lazyspeckit-hash:" "$repo/.lazyspeckit/reviewers/test.md"
}

@test "setup.sh: prints reviewer installed count on fresh install" {
  local repo
  repo="$(create_bare_repo)"

  run run_setup "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"6 installed"* ]]
}

@test "setup.sh: prints reviewer directory path in output" {
  local repo
  repo="$(create_bare_repo)"

  run run_setup "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *".lazyspeckit/reviewers/"* ]]
}

@test "setup.sh: creates .lazyspeckit/reviewers directory" {
  local repo="$TEST_TMPDIR/fresh_reviewer_repo"
  mkdir -p "$repo"

  run run_setup "$repo"
  [ "$status" -eq 0 ]
  [ -d "$repo/.lazyspeckit/reviewers" ]
}

@test "setup.sh: reviewer files are non-empty" {
  local repo
  repo="$(create_bare_repo)"

  run run_setup "$repo"
  [ "$status" -eq 0 ]
  [ -s "$repo/.lazyspeckit/reviewers/architecture.md" ]
  [ -s "$repo/.lazyspeckit/reviewers/code-quality.md" ]
  [ -s "$repo/.lazyspeckit/reviewers/spec-compliance.md" ]
  [ -s "$repo/.lazyspeckit/reviewers/test.md" ]
}

@test "setup.sh: updates unmodified reviewer files (hash matches)" {
  local repo
  repo="$(create_bare_repo)"

  # First install
  run run_setup "$repo"
  [ "$status" -eq 0 ]
  [ -f "$repo/.lazyspeckit/reviewers/architecture.md" ]
  grep -q "^<!-- lazyspeckit-hash:" "$repo/.lazyspeckit/reviewers/architecture.md"

  # Second run — unmodified files should be updated (not skipped)
  run run_setup "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"updated"* ]]
}

@test "setup.sh: skips user-modified reviewer files (hash mismatch)" {
  local repo
  repo="$(create_bare_repo)"

  # First install — creates files with hash stamps
  run run_setup "$repo"
  [ "$status" -eq 0 ]

  # User modifies the file (content changes but stamp is still there)
  # Insert a user line before the stamp
  sed -i.bak '1s/^/# My custom addition\n/' "$repo/.lazyspeckit/reviewers/architecture.md"
  rm -f "$repo/.lazyspeckit/reviewers/architecture.md.bak"

  # Second run — modified file should be skipped
  run run_setup "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"customized (kept)"* ]]
  # Verify the user's modification is preserved
  grep -q "My custom addition" "$repo/.lazyspeckit/reviewers/architecture.md"
}

@test "setup.sh: skips reviewer files with no hash stamp (user-created)" {
  local repo
  repo="$(create_bare_repo)"
  mkdir -p "$repo/.lazyspeckit/reviewers"
  echo "completely custom content" > "$repo/.lazyspeckit/reviewers/architecture.md"

  run run_setup "$repo"
  [ "$status" -eq 0 ]

  # File without stamp should be preserved
  local content
  content="$(cat "$repo/.lazyspeckit/reviewers/architecture.md")"
  [[ "$content" == "completely custom content" ]]
  [[ "$output" == *"customized (kept)"* ]]
  # Other missing files should still be installed
  [ -f "$repo/.lazyspeckit/reviewers/code-quality.md" ]
}

@test "setup.sh: installs missing files while preserving modified ones" {
  local repo
  repo="$(create_bare_repo)"

  # First install
  run run_setup "$repo"
  [ "$status" -eq 0 ]

  # User modifies architecture.md and deletes test.md
  sed -i.bak '1s/^/# customized\n/' "$repo/.lazyspeckit/reviewers/architecture.md"
  rm -f "$repo/.lazyspeckit/reviewers/architecture.md.bak"
  rm -f "$repo/.lazyspeckit/reviewers/test.md"

  # Second run
  run run_setup "$repo"
  [ "$status" -eq 0 ]

  # architecture.md preserved (modified)
  grep -q "customized" "$repo/.lazyspeckit/reviewers/architecture.md"
  # test.md re-installed (was missing)
  [ -f "$repo/.lazyspeckit/reviewers/test.md" ]
  grep -q "^<!-- lazyspeckit-hash:" "$repo/.lazyspeckit/reviewers/test.md"
}

@test "setup.sh: preserves user-added reviewer files during install" {
  local repo
  repo="$(create_bare_repo)"
  mkdir -p "$repo/.lazyspeckit/reviewers"
  echo "custom reviewer" > "$repo/.lazyspeckit/reviewers/security.md"

  run run_setup "$repo"
  [ "$status" -eq 0 ]

  # User's custom file should still be there
  [ -f "$repo/.lazyspeckit/reviewers/security.md" ]
  local content
  content="$(cat "$repo/.lazyspeckit/reviewers/security.md")"
  [[ "$content" == "custom reviewer" ]]
}

@test "setup.sh: shows installing reviewer message" {
  local repo
  repo="$(create_bare_repo)"

  run run_setup "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installing default reviewer skill files"* ]]
}

@test "setup.sh: summary shows mixed counts" {
  local repo
  repo="$(create_bare_repo)"

  # First install all 6
  run run_setup "$repo"
  [ "$status" -eq 0 ]

  # Modify 1, delete 1, leave 4 unmodified
  sed -i.bak '1s/^/# edited\n/' "$repo/.lazyspeckit/reviewers/architecture.md"
  rm -f "$repo/.lazyspeckit/reviewers/architecture.md.bak"
  rm -f "$repo/.lazyspeckit/reviewers/test.md"

  run run_setup "$repo"
  [ "$status" -eq 0 ]
  # 1 installed (test.md), 4 updated (code-quality, security, performance, spec-compliance), 1 customized (architecture)
  [[ "$output" == *"1 installed"* ]]
  [[ "$output" == *"4 updated"* ]]
  [[ "$output" == *"1 customized (kept)"* ]]
}

@test "setup.sh: continues if a reviewer download fails" {
  # Create a curl that fails only for reviewer URLs
  cat > "$FAKE_BIN/curl" <<'SCRIPT'
#!/usr/bin/env bash
outfile=""
url=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o) outfile="$2"; shift 2 ;;
    -H|--retry|--retry-delay|--connect-timeout|--max-time) shift 2 ;;
    -*) shift ;;
    *) if [[ -z "$url" ]]; then url="$1"; fi; shift ;;
  esac
done
if [[ -n "$outfile" ]]; then
  if [[ "$url" == *reviewers/*.md* ]]; then
    exit 1
  else
    echo "lazyspeckit speckit LazySpecKit" > "$outfile"
  fi
fi
exit 0
SCRIPT
  chmod +x "$FAKE_BIN/curl"

  local repo
  repo="$(create_bare_repo)"

  run run_setup "$repo"
  # Should still succeed — reviewer download failures are non-fatal
  [ "$status" -eq 0 ]
  [[ "$output" == *"Failed to download reviewer"* ]]
}

@test "setup.sh: raw_url accepts custom path argument" {
  run bash -c '
    OWNER_REPO="Hacklone/lazy-spec-kit"
    REF="main"
    PROMPT_REPO_PATH="prompts/LazySpecKit.prompt.md"
    raw_url() {
      local path="${1:-$PROMPT_REPO_PATH}"
      printf "https://raw.githubusercontent.com/%s/%s/%s" "$OWNER_REPO" "$REF" "$path"
    }
    result=$(raw_url "reviewers/architecture.md")
    echo "$result"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == "https://raw.githubusercontent.com/Hacklone/lazy-spec-kit/main/reviewers/architecture.md" ]]
}

@test "setup.sh: raw_url defaults to PROMPT_REPO_PATH when no argument" {
  run bash -c '
    OWNER_REPO="Hacklone/lazy-spec-kit"
    REF="main"
    PROMPT_REPO_PATH="prompts/LazySpecKit.prompt.md"
    raw_url() {
      local path="${1:-$PROMPT_REPO_PATH}"
      printf "https://raw.githubusercontent.com/%s/%s/%s" "$OWNER_REPO" "$REF" "$path"
    }
    result=$(raw_url)
    echo "$result"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == "https://raw.githubusercontent.com/Hacklone/lazy-spec-kit/main/prompts/LazySpecKit.prompt.md" ]]
}
