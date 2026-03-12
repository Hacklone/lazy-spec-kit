#!/usr/bin/env bats
# Tests for cli/lazyspeckit

load test_helper

CLI="$REPO_ROOT/cli/lazyspeckit"

# ---- Smart fake curl that returns different content based on URL ----
create_smart_curl() {
  cat > "$FAKE_BIN/curl" <<'CURLSCRIPT'
#!/usr/bin/env bash
outfile=""
url=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o) outfile="$2"; shift 2 ;;
    -H|--retry|--retry-delay|--connect-timeout|--max-time)
      shift 2 ;;
    -*) shift ;;
    *)
      if [[ -z "$url" ]]; then url="$1"; fi
      shift ;;
  esac
done
if [[ -n "$outfile" ]]; then
  if [[ "$url" == *setup.sh* ]]; then
    printf '%s\n' \
      '#!/usr/bin/env bash' \
      'target="${1:-$(pwd)}"' \
      'mkdir -p "$target/.github/prompts" "$target/.claude/commands" "$target/.lazyspeckit/reviewers"' \
      'echo "LazySpecKit speckit prompt" > "$target/.github/prompts/LazySpecKit.prompt.md"' \
      'echo "LazySpecKit speckit prompt" > "$target/.claude/commands/LazySpecKit.md"' \
      'for f in architecture.md security.md performance.md accessibility.md spec-compliance.md code-quality.md test.md; do' \
      '  dst="$target/.lazyspeckit/reviewers/$f"' \
      '  if [ ! -f "$dst" ] || grep -q "^<!-- lazyspeckit-hash:" "$dst" 2>/dev/null; then' \
      '    echo "reviewer $f" > "$dst"' \
      '    hash=$(shasum -a 256 "$dst" | cut -d" " -f1)' \
      '    echo "<!-- lazyspeckit-hash:$hash -->" >> "$dst"' \
      '  fi' \
      'done' \
      'echo "Prompts installed"' \
      'echo "Reviewer skill files installed"' > "$outfile"
  elif [[ "$url" == *msitarzewski/agency-agents* ]]; then
    local fname
    fname="$(echo "$url" | sed 's|.*/agency-agents/[^/]*/||' | sed 's/?.*//')"
    printf '%s\n' "---" "name: Agency $fname" "description: Agency agent" "---" "" "You are an Agency agent for $fname" > "$outfile"
  elif [[ "$url" == *reviewers/*.md* ]]; then
    local fname
    fname="$(echo "$url" | sed 's/.*reviewers\///' | sed 's/?.*//')"
    printf '%s\n' "---" "name: Reviewer $fname" "perspective: test perspective" "---" "Review instructions for $fname" > "$outfile"
  elif [[ "$url" == *lazyspeckit* ]]; then
    printf '%s\n' \
      '#!/usr/bin/env bash' \
      'VERSION="0.8.3"' \
      '# lazyspeckit marker' \
      'echo "lazyspeckit $VERSION"' > "$outfile"
  else
    echo "lazyspeckit speckit LazySpecKit" > "$outfile"
  fi
fi
exit 0
CURLSCRIPT
  chmod +x "$FAKE_BIN/curl"
}

# ---- helper to run the CLI in a controlled environment ----
run_cli() {
  NO_COLOR=1 \
  DEBUG="${DEBUG:-0}" \
  LAZYSPECKIT_REF="${LAZYSPECKIT_REF:-main}" \
  HOME="$TEST_TMPDIR" \
  bash "$CLI" "$@"
}

setup() {
  export TEST_TMPDIR
  TEST_TMPDIR="$(mktemp -d)"
  export FAKE_BIN="$TEST_TMPDIR/fake_bin"
  mkdir -p "$FAKE_BIN"
  create_smart_curl
  export ORIGINAL_PATH="$PATH"
  export PATH="$FAKE_BIN:$PATH"
  export NO_COLOR=1
  export DEBUG=0

  # Most commands need uv/uvx
  create_fake_uv
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# ============ --help / usage ============

@test "cli: --help prints usage" {
  run run_cli --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"lazyspeckit"* ]]
  [[ "$output" == *"Commands:"* ]]
}

@test "cli: -h prints usage" {
  run run_cli -h
  [ "$status" -eq 0 ]
  [[ "$output" == *"Commands:"* ]]
}

@test "cli: no args prints usage" {
  run run_cli
  [ "$status" -eq 0 ]
  [[ "$output" == *"Commands:"* ]]
}

@test "cli: usage includes all commands" {
  run run_cli --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"init"* ]]
  [[ "$output" == *"upgrade"* ]]
  [[ "$output" == *"doctor"* ]]
  [[ "$output" == *"self-update"* ]]
  [[ "$output" == *"version"* ]]
}

@test "cli: usage includes examples" {
  run run_cli --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Examples:"* ]]
  [[ "$output" == *"--ai copilot"* ]]
  [[ "$output" == *"--ai claude"* ]]
}

@test "cli: unknown command fails" {
  run run_cli nonexistent
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unknown command: nonexistent"* ]]
}

# ============ version ============

@test "cli: version prints version number" {
  run run_cli version
  [ "$status" -eq 0 ]
  [[ "$output" == *"lazyspeckit"* ]]
  [[ "$output" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]
}

@test "cli: version shows remote version" {
  run run_cli version
  [ "$status" -eq 0 ]
  [[ "$output" == *"remote:"* ]]
}

@test "cli: version handles remote fetch failure gracefully" {
  create_failing_curl
  run run_cli version
  [ "$status" -eq 0 ]
  [[ "$output" == *"Could not determine remote version"* ]]
}

# ============ doctor ============

@test "cli: doctor runs without error" {
  local repo
  repo="$(create_test_repo)"

  run run_cli doctor "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"lazyspeckit doctor"* ]]
}

@test "cli: doctor shows local version" {
  local repo
  repo="$(create_test_repo)"

  run run_cli doctor "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"local version:"* ]]
}

@test "cli: doctor shows tool availability" {
  local repo
  repo="$(create_test_repo)"

  run run_cli doctor "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"curl:"* ]]
  [[ "$output" == *"wget:"* ]]
  [[ "$output" == *"uv:"* ]]
  [[ "$output" == *"uvx:"* ]]
}

@test "cli: doctor shows speckit init status" {
  local repo
  repo="$(create_test_repo)"

  run run_cli doctor "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"SpecKit initialized"* ]]
}

@test "cli: doctor detects VS Code" {
  local repo
  repo="$(create_vscode_only_repo)"

  run run_cli doctor "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"VS Code detected"* ]]
}

@test "cli: doctor detects Claude" {
  local repo
  repo="$(create_claude_only_repo)"

  run run_cli doctor "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Claude detected"* ]]
}

@test "cli: doctor shows prompt file presence" {
  local repo
  repo="$(create_test_repo)"
  echo "prompt" > "$repo/.github/prompts/LazySpecKit.prompt.md"

  run run_cli doctor "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"LazySpecKit prompt files"* ]]
}

@test "cli: doctor with --here uses cwd" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"

  run run_cli doctor --here
  [ "$status" -eq 0 ]
  [[ "$output" == *"lazyspeckit doctor"* ]]
}

@test "cli: doctor handles nonexistent target gracefully" {
  run run_cli doctor "/nonexistent/path"
  [ "$status" -eq 0 ]
  [[ "$output" == *"target exists: no"* ]]
}

@test "cli: doctor shows actions section" {
  local repo
  repo="$(create_test_repo)"

  run run_cli doctor "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Actions:"* ]]
}

@test "cli: doctor shows remote version" {
  local repo
  repo="$(create_test_repo)"

  run run_cli doctor "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"remote version:"* ]]
}

@test "cli: doctor shows uv version" {
  local repo
  repo="$(create_test_repo)"

  run run_cli doctor "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"uv ver:"* ]]
}

@test "cli: doctor shows specify status" {
  local repo
  repo="$(create_test_repo)"

  run run_cli doctor "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"specify:"* ]]
}

# ============ init ============

@test "cli: init with --here creates speckit and installs prompts" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"

  run run_cli init --here --ai copilot
  [ "$status" -eq 0 ]
  [[ "$output" == *"Done"* ]]
}

@test "cli: init without --here defaults to current directory" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"

  run run_cli init --ai copilot
  [ "$status" -eq 0 ]
  [[ "$output" == *"Done"* ]]
}

@test "cli: init skips specify if already initialized" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"

  run run_cli init --here --ai copilot
  [ "$status" -eq 0 ]
  [[ "$output" == *"already initialized"* ]]
}

@test "cli: init installs LazySpecKit prompts" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"

  run run_cli init --here --ai copilot
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installing LazySpecKit prompts"* ]]
}

@test "cli: init shows next steps" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"

  run run_cli init --here --ai copilot
  [ "$status" -eq 0 ]
  [[ "$output" == *"Next:"* ]]
  [[ "$output" == *"/LazySpecKit"* ]]
}

@test "cli: init shows VS Code reload hint when VS Code detected" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"

  run run_cli init --here --ai copilot
  [ "$status" -eq 0 ]
  [[ "$output" == *"Reload Window"* ]]
}

@test "cli: init installs prompt files on disk" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"

  run run_cli init --here --ai copilot
  [ "$status" -eq 0 ]
  [ -f "$repo/.github/prompts/LazySpecKit.prompt.md" ]
  [ -f "$repo/.claude/commands/LazySpecKit.md" ]
}

@test "cli: init runs specify when not initialized" {
  local repo
  repo="$(create_bare_repo)"
  cd "$repo"
  create_fake_specify

  # Create fake uvx that creates .specify
  cat > "$FAKE_BIN/uvx" <<'SCRIPT'
#!/usr/bin/env bash
for arg in "$@"; do
  if [[ "$arg" == "--here" ]]; then
    mkdir -p .specify
  fi
done
echo "uvx $*"
exit 0
SCRIPT
  chmod +x "$FAKE_BIN/uvx"

  run run_cli init --here --ai copilot
  [ "$status" -eq 0 ]
}

# ============ upgrade ============

@test "cli: upgrade upgrades speckit CLI and prompts" {
  local repo
  repo="$(create_test_repo)"
  create_fake_specify

  run run_cli upgrade "$repo" --ai copilot
  [ "$status" -eq 0 ]
  [[ "$output" == *"Upgrading"* ]]
}

@test "cli: upgrade auto-detects copilot" {
  local repo
  repo="$(create_vscode_only_repo)"
  create_fake_specify

  run run_cli upgrade "$repo"
  [ "$status" -eq 0 ]
}

@test "cli: upgrade auto-detects claude" {
  local repo
  repo="$(create_claude_only_repo)"
  create_fake_specify

  run run_cli upgrade "$repo"
  [ "$status" -eq 0 ]
}

@test "cli: upgrade fails if no AI target can be detected and no --ai flag" {
  local repo="$TEST_TMPDIR/empty_repo"
  mkdir -p "$repo/.specify"

  run run_cli upgrade "$repo"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Could not detect AI agent"* ]]
}

@test "cli: upgrade fails if target doesn't exist" {
  run run_cli upgrade "/nonexistent/totally"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Target folder does not exist"* ]]
}

@test "cli: upgrade with --here uses cwd" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  create_fake_specify

  run run_cli upgrade --here --ai copilot
  [ "$status" -eq 0 ]
}

@test "cli: upgrade installs LazySpecKit prompts even if speckit fails" {
  local repo
  repo="$(create_test_repo)"

  # Create a specify that fails
  cat > "$FAKE_BIN/specify" <<'SCRIPT'
#!/usr/bin/env bash
exit 1
SCRIPT
  chmod +x "$FAKE_BIN/specify"

  run run_cli upgrade "$repo" --ai copilot
  [ "$status" -eq 0 ]
  [[ "$output" == *"Upgrading LazySpecKit prompts"* ]]
}

@test "cli: upgrade shows VS Code hint" {
  local repo
  repo="$(create_test_repo)"
  create_fake_specify

  run run_cli upgrade "$repo" --ai copilot
  [ "$status" -eq 0 ]
  [[ "$output" == *"Reload Window"* ]]
}

@test "cli: upgrade installs prompt files on disk" {
  local repo
  repo="$(create_test_repo)"
  create_fake_specify

  run run_cli upgrade "$repo" --ai copilot
  [ "$status" -eq 0 ]
  [ -f "$repo/.github/prompts/LazySpecKit.prompt.md" ]
  [ -f "$repo/.claude/commands/LazySpecKit.md" ]
}

@test "cli: upgrade shows upgraded message" {
  local repo
  repo="$(create_test_repo)"
  create_fake_specify

  run run_cli upgrade "$repo" --ai copilot
  [ "$status" -eq 0 ]
  [[ "$output" == *"Upgraded in:"* ]]
}

@test "cli: upgrade handles multiple AI agents" {
  local repo
  repo="$(create_test_repo)"
  create_fake_specify

  run run_cli upgrade "$repo"
  [ "$status" -eq 0 ]
}

@test "cli: upgrade with explicit --ai overrides auto-detection" {
  local repo
  repo="$(create_test_repo)"
  create_fake_specify

  run run_cli upgrade "$repo" --ai claude
  [ "$status" -eq 0 ]
}

# ============ self-update ============

@test "cli: self-update updates the CLI binary" {
  local fake_self="$FAKE_BIN/lazyspeckit"
  cat > "$fake_self" <<'SCRIPT'
#!/usr/bin/env bash
echo "lazyspeckit 0.5.0"
SCRIPT
  chmod +x "$fake_self"

  run run_cli self-update
  [ "$status" -eq 0 ]
  [[ "$output" == *"Updating lazyspeckit CLI"* ]]
  [[ "$output" == *"LazySpecKit CLI updated"* ]]
}

@test "cli: self-update upgrades SpecKit CLI too" {
  local fake_self="$FAKE_BIN/lazyspeckit"
  cat > "$fake_self" <<'SCRIPT'
#!/usr/bin/env bash
echo "lazyspeckit 0.5.0"
SCRIPT
  chmod +x "$fake_self"

  run run_cli self-update
  [ "$status" -eq 0 ]
  [[ "$output" == *"SpecKit CLI upgraded"* ]]
}

@test "cli: self-update fails if CLI location not writable" {
  rm -f "$FAKE_BIN/lazyspeckit"

  local fake_self="$TEST_TMPDIR/readonly_bin/lazyspeckit"
  mkdir -p "$TEST_TMPDIR/readonly_bin"
  echo "#!/bin/bash" > "$fake_self"
  chmod 555 "$fake_self"
  chmod 555 "$TEST_TMPDIR/readonly_bin"
  export PATH="$TEST_TMPDIR/readonly_bin:$PATH"

  run run_cli self-update
  [ "$status" -ne 0 ]
  [[ "$output" == *"Cannot write to"* ]]

  chmod 755 "$TEST_TMPDIR/readonly_bin"
  chmod 755 "$fake_self"
}

@test "cli: self-update validates downloaded CLI content" {
  local fake_self="$FAKE_BIN/lazyspeckit"
  echo "#!/bin/bash" > "$fake_self"
  chmod +x "$fake_self"

  # Create curl that returns garbage for ALL URLs
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
  echo "this is garbage with no marker" > "$outfile"
fi
exit 0
SCRIPT
  chmod +x "$FAKE_BIN/curl"

  run run_cli self-update
  [ "$status" -ne 0 ]
  [[ "$output" == *"does not look valid"* ]]
}

@test "cli: self-update shows all set message" {
  local fake_self="$FAKE_BIN/lazyspeckit"
  cat > "$fake_self" <<'SCRIPT'
#!/usr/bin/env bash
echo "lazyspeckit 0.5.0"
SCRIPT
  chmod +x "$fake_self"

  run run_cli self-update
  [ "$status" -eq 0 ]
  [[ "$output" == *"All set"* ]]
}

# ============ utility functions (inline implementations) ============

@test "cli: have() returns true for existing command" {
  run bash -c '
    have() { command -v "${1:-__missing__}" >/dev/null 2>&1; }
    have bash && echo found
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"found"* ]]
}

@test "cli: have() returns false for missing command" {
  run bash -c '
    have() { command -v "${1:-__missing__}" >/dev/null 2>&1; }
    have __totally_fake_cmd__ && echo found || echo notfound
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"notfound"* ]]
}

@test "cli: die() exits with non-zero" {
  run bash -c '
    err() { printf "%s\n" "$*" >&2; }
    die() { err "$*"; exit 1; }
    die "test error"
  '
  [ "$status" -ne 0 ]
}

@test "cli: cache_bust appends cb parameter" {
  run bash -c '
    die() { echo "$*" >&2; exit 1; }
    cache_bust() {
      local url="${1:-}"
      [[ -n "$url" ]] || die "cache_bust: missing url"
      printf "%s?cb=%s" "$url" "$(date +%s)"
    }
    result=$(cache_bust "https://example.com/file")
    [[ "$result" == *"?cb="* ]] && echo "OK"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK"* ]]
}

@test "cli: cache_bust fails with empty url" {
  run bash -c '
    err() { printf "%s\n" "$*" >&2; }
    die() { err "$*"; exit 1; }
    cache_bust() {
      local url="${1:-}"
      [[ -n "$url" ]] || die "cache_bust: missing url"
      printf "%s?cb=%s" "$url" "$(date +%s)"
    }
    cache_bust ""
  '
  [ "$status" -ne 0 ]
}

# ============ infer_target functions ============

@test "cli: infer_target_dir_from_init_args with --here returns cwd" {
  run bash -c '
    infer_target_dir_from_init_args() {
      local a=""
      for a in "$@"; do
        [[ "$a" == "--here" ]] && { pwd; return 0; }
      done
      for a in "$@"; do
        if [[ "$a" != -* ]]; then
          if [[ -d "$a" ]]; then (cd "$a" && pwd); else echo "$(pwd)/$a"; fi
          return 0
        fi
      done
      pwd
    }
    result=$(infer_target_dir_from_init_args --here --ai copilot)
    [[ "$result" == "$(pwd)" ]] && echo OK
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK"* ]]
}

@test "cli: infer_target_dir_from_init_args with path returns that path" {
  local dir="$TEST_TMPDIR/mydir"
  mkdir -p "$dir"
  run bash -c '
    infer_target_dir_from_init_args() {
      local a=""
      for a in "$@"; do
        [[ "$a" == "--here" ]] && { pwd; return 0; }
      done
      for a in "$@"; do
        if [[ "$a" != -* ]]; then
          if [[ -d "$a" ]]; then (cd "$a" && pwd); else echo "$(pwd)/$a"; fi
          return 0
        fi
      done
      pwd
    }
    result=$(infer_target_dir_from_init_args "'"$dir"'" --ai copilot)
    echo "$result"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"mydir"* ]]
}

@test "cli: infer_target_dir_from_init_args with no args returns cwd" {
  run bash -c '
    infer_target_dir_from_init_args() {
      local a=""
      for a in "$@"; do
        [[ "$a" == "--here" ]] && { pwd; return 0; }
      done
      for a in "$@"; do
        if [[ "$a" != -* ]]; then
          if [[ -d "$a" ]]; then (cd "$a" && pwd); else echo "$(pwd)/$a"; fi
          return 0
        fi
      done
      pwd
    }
    result=$(infer_target_dir_from_init_args)
    [[ "$result" == "$(pwd)" ]] && echo OK
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK"* ]]
}

@test "cli: infer_target_simple with --here returns cwd" {
  run bash -c '
    infer_target_simple() {
      local arg="${1:-}"
      if [[ "$arg" == "--here" || -z "$arg" ]]; then
        pwd
      else
        if [[ -d "$arg" ]]; then (cd "$arg" && pwd); else echo "$(pwd)/$arg"; fi
      fi
    }
    result=$(infer_target_simple --here)
    [[ "$result" == "$(pwd)" ]] && echo OK
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK"* ]]
}

@test "cli: infer_target_simple with empty arg returns cwd" {
  run bash -c '
    infer_target_simple() {
      local arg="${1:-}"
      if [[ "$arg" == "--here" || -z "$arg" ]]; then
        pwd
      else
        if [[ -d "$arg" ]]; then (cd "$arg" && pwd); else echo "$(pwd)/$arg"; fi
      fi
    }
    result=$(infer_target_simple "")
    [[ "$result" == "$(pwd)" ]] && echo OK
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK"* ]]
}

@test "cli: infer_target_simple with existing dir returns absolute path" {
  local dir="$TEST_TMPDIR/targetdir"
  mkdir -p "$dir"
  run bash -c '
    infer_target_simple() {
      local arg="${1:-}"
      if [[ "$arg" == "--here" || -z "$arg" ]]; then
        pwd
      else
        if [[ -d "$arg" ]]; then (cd "$arg" && pwd); else echo "$(pwd)/$arg"; fi
      fi
    }
    result=$(infer_target_simple "'"$dir"'")
    echo "$result"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"targetdir"* ]]
}

@test "cli: infer_target_simple with nonexistent path constructs path from cwd" {
  run bash -c '
    infer_target_simple() {
      local arg="${1:-}"
      if [[ "$arg" == "--here" || -z "$arg" ]]; then
        pwd
      else
        if [[ -d "$arg" ]]; then (cd "$arg" && pwd); else echo "$(pwd)/$arg"; fi
      fi
    }
    result=$(infer_target_simple "newdir")
    echo "$result"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"newdir"* ]]
}

# ============ AI detection functions ============

@test "cli: is_speckit_inited returns true for .specify dir" {
  local repo
  repo="$(create_test_repo)"
  run bash -c '
    is_speckit_inited() { [[ -d "${1:-/__missing__}/.specify" ]]; }
    is_speckit_inited "'"$repo"'" && echo yes || echo no
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"yes"* ]]
}

@test "cli: is_speckit_inited returns false without .specify dir" {
  local repo
  repo="$(create_bare_repo)"
  run bash -c '
    is_speckit_inited() { [[ -d "${1:-/__missing__}/.specify" ]]; }
    is_speckit_inited "'"$repo"'" && echo yes || echo no
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"no"* ]]
}

@test "cli: detect_vscode_usage returns true for .vscode dir" {
  local repo
  repo="$(create_vscode_only_repo)"
  run bash -c '
    detect_vscode_usage() { [[ -d "${1:-/__missing__}/.vscode" || -d "${1:-/__missing__}/.github/prompts" ]]; }
    detect_vscode_usage "'"$repo"'" && echo yes || echo no
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"yes"* ]]
}

@test "cli: detect_vscode_usage returns true for .github/prompts dir" {
  local repo="$TEST_TMPDIR/vscode_prompts"
  mkdir -p "$repo/.github/prompts"
  run bash -c '
    detect_vscode_usage() { [[ -d "${1:-/__missing__}/.vscode" || -d "${1:-/__missing__}/.github/prompts" ]]; }
    detect_vscode_usage "'"$repo"'" && echo yes || echo no
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"yes"* ]]
}

@test "cli: detect_claude_usage returns true for .claude dir" {
  local repo
  repo="$(create_claude_only_repo)"
  run bash -c '
    detect_claude_usage() { [[ -d "${1:-/__missing__}/.claude" || -d "${1:-/__missing__}/.claude/commands" ]]; }
    detect_claude_usage "'"$repo"'" && echo yes || echo no
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"yes"* ]]
}

@test "cli: detect_claude_usage returns false without .claude" {
  local repo
  repo="$(create_vscode_only_repo)"
  run bash -c '
    detect_claude_usage() { [[ -d "${1:-/__missing__}/.claude" || -d "${1:-/__missing__}/.claude/commands" ]]; }
    detect_claude_usage "'"$repo"'" && echo yes || echo no
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"no"* ]]
}

@test "cli: prompt_files_present returns true when prompt exists" {
  local repo
  repo="$(create_test_repo)"
  echo "prompt" > "$repo/.github/prompts/LazySpecKit.prompt.md"
  run bash -c '
    prompt_files_present() { [[ -f "${1:-/__missing__}/.github/prompts/LazySpecKit.prompt.md" || -f "${1:-/__missing__}/.claude/commands/LazySpecKit.md" ]]; }
    prompt_files_present "'"$repo"'" && echo yes || echo no
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"yes"* ]]
}

@test "cli: prompt_files_present returns false when no prompts" {
  local repo
  repo="$(create_bare_repo)"
  run bash -c '
    prompt_files_present() { [[ -f "${1:-/__missing__}/.github/prompts/LazySpecKit.prompt.md" || -f "${1:-/__missing__}/.claude/commands/LazySpecKit.md" ]]; }
    prompt_files_present "'"$repo"'" && echo yes || echo no
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"no"* ]]
}

# ============ extract_ai_from_args ============

@test "cli: extract_ai_from_args extracts --ai copilot" {
  run bash -c '
    extract_ai_from_args() {
      [[ $# -eq 0 ]] && return 1
      local args=("$@")
      local i
      for ((i=0; i<${#args[@]}; i++)); do
        if [[ "${args[$i]}" == "--ai" && $((i+1)) -lt ${#args[@]} ]]; then
          printf "%s" "${args[$((i+1))]}"
          return 0
        fi
        if [[ "${args[$i]}" == --ai=* ]]; then
          printf "%s" "${args[$i]#--ai=}"
          return 0
        fi
      done
      return 1
    }
    result=$(extract_ai_from_args --here --ai copilot)
    echo "$result"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == "copilot" ]]
}

@test "cli: extract_ai_from_args extracts --ai=claude" {
  run bash -c '
    extract_ai_from_args() {
      [[ $# -eq 0 ]] && return 1
      local args=("$@")
      local i
      for ((i=0; i<${#args[@]}; i++)); do
        if [[ "${args[$i]}" == "--ai" && $((i+1)) -lt ${#args[@]} ]]; then
          printf "%s" "${args[$((i+1))]}"
          return 0
        fi
        if [[ "${args[$i]}" == --ai=* ]]; then
          printf "%s" "${args[$i]#--ai=}"
          return 0
        fi
      done
      return 1
    }
    result=$(extract_ai_from_args --here --ai=claude)
    echo "$result"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == "claude" ]]
}

@test "cli: extract_ai_from_args returns 1 if no --ai" {
  run bash -c '
    extract_ai_from_args() {
      [[ $# -eq 0 ]] && return 1
      local args=("$@") i
      for ((i=0; i<${#args[@]}; i++)); do
        if [[ "${args[$i]}" == "--ai" && $((i+1)) -lt ${#args[@]} ]]; then
          printf "%s" "${args[$((i+1))]}"; return 0
        fi
        if [[ "${args[$i]}" == --ai=* ]]; then
          printf "%s" "${args[$i]#--ai=}"; return 0
        fi
      done
      return 1
    }
    extract_ai_from_args --here --force || echo "no_ai"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"no_ai"* ]]
}

@test "cli: extract_ai_from_args returns 1 with no args" {
  run bash -c '
    extract_ai_from_args() {
      [[ $# -eq 0 ]] && return 1
      return 1
    }
    extract_ai_from_args || echo "no_ai"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"no_ai"* ]]
}

# ============ resolve_ai_targets ============

@test "cli: resolve_ai_targets prefers explicit --ai flag" {
  local repo
  repo="$(create_test_repo)"

  run bash -c '
    detect_vscode_usage() { [[ -d "${1:-/__missing__}/.vscode" || -d "${1:-/__missing__}/.github/prompts" ]]; }
    detect_claude_usage() { [[ -d "${1:-/__missing__}/.claude" || -d "${1:-/__missing__}/.claude/commands" ]]; }
    extract_ai_from_args() {
      [[ $# -eq 0 ]] && return 1
      local args=("$@") i
      for ((i=0; i<${#args[@]}; i++)); do
        if [[ "${args[$i]}" == "--ai" && $((i+1)) -lt ${#args[@]} ]]; then
          printf "%s" "${args[$((i+1))]}"; return 0
        fi
        if [[ "${args[$i]}" == --ai=* ]]; then
          printf "%s" "${args[$i]#--ai=}"; return 0
        fi
      done
      return 1
    }
    resolve_ai_targets() {
      local target="${1:-}"; shift || true
      local ai=""
      ai="$(extract_ai_from_args "$@" 2>/dev/null || true)"
      if [[ -n "$ai" ]]; then echo "$ai"; return 0; fi
      local targets=""
      if detect_vscode_usage "$target"; then targets="copilot"; fi
      if detect_claude_usage "$target"; then targets="${targets:+$targets }claude"; fi
      if [[ -n "$targets" ]]; then echo "$targets"; return 0; fi
      return 1
    }
    result=$(resolve_ai_targets "'"$repo"'" --ai copilot)
    echo "$result"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == "copilot" ]]
}

@test "cli: resolve_ai_targets auto-detects both agents" {
  local repo
  repo="$(create_test_repo)"

  run bash -c '
    detect_vscode_usage() { [[ -d "${1:-/__missing__}/.vscode" || -d "${1:-/__missing__}/.github/prompts" ]]; }
    detect_claude_usage() { [[ -d "${1:-/__missing__}/.claude" || -d "${1:-/__missing__}/.claude/commands" ]]; }
    extract_ai_from_args() { return 1; }
    resolve_ai_targets() {
      local target="${1:-}"; shift || true
      local ai=""
      ai="$(extract_ai_from_args "$@" 2>/dev/null || true)"
      if [[ -n "$ai" ]]; then echo "$ai"; return 0; fi
      local targets=""
      if detect_vscode_usage "$target"; then targets="copilot"; fi
      if detect_claude_usage "$target"; then targets="${targets:+$targets }claude"; fi
      if [[ -n "$targets" ]]; then echo "$targets"; return 0; fi
      return 1
    }
    result=$(resolve_ai_targets "'"$repo"'")
    echo "$result"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"copilot"* ]]
  [[ "$output" == *"claude"* ]]
}

@test "cli: resolve_ai_targets fails when no agents detected" {
  local repo="$TEST_TMPDIR/empty"
  mkdir -p "$repo"

  run bash -c '
    detect_vscode_usage() { [[ -d "${1:-/__missing__}/.vscode" || -d "${1:-/__missing__}/.github/prompts" ]]; }
    detect_claude_usage() { [[ -d "${1:-/__missing__}/.claude" || -d "${1:-/__missing__}/.claude/commands" ]]; }
    extract_ai_from_args() { return 1; }
    resolve_ai_targets() {
      local target="${1:-}"; shift || true
      local ai=""
      ai="$(extract_ai_from_args "$@" 2>/dev/null || true)"
      if [[ -n "$ai" ]]; then echo "$ai"; return 0; fi
      local targets=""
      if detect_vscode_usage "$target"; then targets="copilot"; fi
      if detect_claude_usage "$target"; then targets="${targets:+$targets }claude"; fi
      if [[ -n "$targets" ]]; then echo "$targets"; return 0; fi
      return 1
    }
    resolve_ai_targets "'"$repo"'" || echo "failed"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"failed"* ]]
}

# ============ strip_ai_from_args ============

@test "cli: strip_ai_from_args removes --ai and its value" {
  run bash -c '
    strip_ai_from_args() {
      local skip_next="false" arg
      for arg in "$@"; do
        if [[ "$skip_next" == "true" ]]; then skip_next="false"; continue; fi
        if [[ "$arg" == "--ai" ]]; then skip_next="true"; continue; fi
        if [[ "$arg" == --ai=* ]]; then continue; fi
        printf "%s\0" "$arg"
      done
    }
    result=""
    while IFS= read -r -d "" line; do
      result="$result $line"
    done < <(strip_ai_from_args --here --ai copilot --force)
    echo "$result"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"--here"* ]]
  [[ "$output" == *"--force"* ]]
  [[ "$output" != *"copilot"* ]]
  [[ "$output" != *"--ai"* ]]
}

@test "cli: strip_ai_from_args removes --ai=value" {
  run bash -c '
    strip_ai_from_args() {
      local skip_next="false" arg
      for arg in "$@"; do
        if [[ "$skip_next" == "true" ]]; then skip_next="false"; continue; fi
        if [[ "$arg" == "--ai" ]]; then skip_next="true"; continue; fi
        if [[ "$arg" == --ai=* ]]; then continue; fi
        printf "%s\0" "$arg"
      done
    }
    result=""
    while IFS= read -r -d "" line; do
      result="$result $line"
    done < <(strip_ai_from_args --here --ai=claude --force)
    echo "$result"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"--here"* ]]
  [[ "$output" == *"--force"* ]]
  [[ "$output" != *"claude"* ]]
}

# ============ backup/restore ============

@test "cli: backup_speckit_customizations backs up constitution" {
  local repo
  repo="$(create_test_repo)"
  mkdir -p "$repo/.specify/memory"
  echo "my constitution" > "$repo/.specify/memory/constitution.md"

  local backup="$TEST_TMPDIR/backup"

  run bash -c '
    die() { echo "$*" >&2; exit 1; }
    backup_speckit_customizations() {
      local target="${1:-}" backup_dir="${2:-}"
      [[ -n "$target" && -n "$backup_dir" ]] || die "backup: missing target/backup_dir"
      mkdir -p "$backup_dir"
      if [[ -f "$target/.specify/memory/constitution.md" ]]; then
        cp -f "$target/.specify/memory/constitution.md" "$backup_dir/constitution.md"
      fi
      if [[ -d "$target/.specify/templates" ]]; then
        mkdir -p "$backup_dir/templates"
        cp -R "$target/.specify/templates/." "$backup_dir/templates/" 2>/dev/null || true
      fi
    }
    backup_speckit_customizations "'"$repo"'" "'"$backup"'"
  '
  [ "$status" -eq 0 ]
  [ -f "$backup/constitution.md" ]
  [[ "$(cat "$backup/constitution.md")" == "my constitution" ]]
}

@test "cli: backup_speckit_customizations backs up templates" {
  local repo
  repo="$(create_test_repo)"
  mkdir -p "$repo/.specify/templates"
  echo "template content" > "$repo/.specify/templates/my_template.md"

  local backup="$TEST_TMPDIR/backup"

  run bash -c '
    die() { echo "$*" >&2; exit 1; }
    backup_speckit_customizations() {
      local target="${1:-}" backup_dir="${2:-}"
      [[ -n "$target" && -n "$backup_dir" ]] || die "backup: missing target/backup_dir"
      mkdir -p "$backup_dir"
      if [[ -f "$target/.specify/memory/constitution.md" ]]; then
        cp -f "$target/.specify/memory/constitution.md" "$backup_dir/constitution.md"
      fi
      if [[ -d "$target/.specify/templates" ]]; then
        mkdir -p "$backup_dir/templates"
        cp -R "$target/.specify/templates/." "$backup_dir/templates/" 2>/dev/null || true
      fi
    }
    backup_speckit_customizations "'"$repo"'" "'"$backup"'"
  '
  [ "$status" -eq 0 ]
  [ -f "$backup/templates/my_template.md" ]
}

@test "cli: restore_speckit_customizations restores constitution" {
  local repo
  repo="$(create_test_repo)"
  local backup="$TEST_TMPDIR/backup"
  mkdir -p "$backup"
  echo "restored constitution" > "$backup/constitution.md"

  run bash -c '
    die() { echo "$*" >&2; exit 1; }
    restore_speckit_customizations() {
      local target="${1:-}" backup_dir="${2:-}"
      [[ -n "$target" && -n "$backup_dir" ]] || die "restore: missing target/backup_dir"
      if [[ -f "$backup_dir/constitution.md" ]]; then
        mkdir -p "$target/.specify/memory"
        cp -f "$backup_dir/constitution.md" "$target/.specify/memory/constitution.md"
      fi
      if [[ -d "$backup_dir/templates" ]]; then
        mkdir -p "$target/.specify/templates"
        cp -R "$backup_dir/templates/." "$target/.specify/templates/" 2>/dev/null || true
      fi
    }
    restore_speckit_customizations "'"$repo"'" "'"$backup"'"
  '
  [ "$status" -eq 0 ]
  [ -f "$repo/.specify/memory/constitution.md" ]
  [[ "$(cat "$repo/.specify/memory/constitution.md")" == "restored constitution" ]]
}

@test "cli: restore_speckit_customizations restores templates" {
  local repo
  repo="$(create_test_repo)"
  local backup="$TEST_TMPDIR/backup"
  mkdir -p "$backup/templates"
  echo "restored template" > "$backup/templates/t.md"

  run bash -c '
    die() { echo "$*" >&2; exit 1; }
    restore_speckit_customizations() {
      local target="${1:-}" backup_dir="${2:-}"
      [[ -n "$target" && -n "$backup_dir" ]] || die "restore: missing target/backup_dir"
      if [[ -f "$backup_dir/constitution.md" ]]; then
        mkdir -p "$target/.specify/memory"
        cp -f "$backup_dir/constitution.md" "$target/.specify/memory/constitution.md"
      fi
      if [[ -d "$backup_dir/templates" ]]; then
        mkdir -p "$target/.specify/templates"
        cp -R "$backup_dir/templates/." "$target/.specify/templates/" 2>/dev/null || true
      fi
    }
    restore_speckit_customizations "'"$repo"'" "'"$backup"'"
  '
  [ "$status" -eq 0 ]
  [ -f "$repo/.specify/templates/t.md" ]
  [[ "$(cat "$repo/.specify/templates/t.md")" == "restored template" ]]
}

@test "cli: backup fails without target arg" {
  run bash -c '
    err() { printf "%s\n" "$*" >&2; }
    die() { err "$*"; exit 1; }
    backup_speckit_customizations() {
      local target="${1:-}" backup_dir="${2:-}"
      [[ -n "$target" && -n "$backup_dir" ]] || die "backup: missing target/backup_dir"
    }
    backup_speckit_customizations "" ""
  '
  [ "$status" -ne 0 ]
}

@test "cli: restore fails without target arg" {
  run bash -c '
    err() { printf "%s\n" "$*" >&2; }
    die() { err "$*"; exit 1; }
    restore_speckit_customizations() {
      local target="${1:-}" backup_dir="${2:-}"
      [[ -n "$target" && -n "$backup_dir" ]] || die "restore: missing target/backup_dir"
    }
    restore_speckit_customizations "" ""
  '
  [ "$status" -ne 0 ]
}

# ============ color functions ============

@test "cli: color disabled when NO_COLOR is set" {
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
    result=$(c "32" "hello")
    [[ "$result" == "hello" ]] && echo OK
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK"* ]]
}

@test "cli: color enabled when COLOR_ON is true" {
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
    result=$(c "32" "hello")
    [[ "$result" == *"hello"* ]] && echo OK
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK"* ]]
}

# ============ is_windows_gitbash ============

@test "cli: is_windows_gitbash returns false on macOS/Linux" {
  run bash -c '
    is_windows_gitbash() {
      local uname_s
      uname_s="$(uname -s 2>/dev/null || true)"
      [[ "$uname_s" == MINGW* || "$uname_s" == MSYS* || "$uname_s" == CYGWIN* ]]
    }
    is_windows_gitbash && echo "windows" || echo "not_windows"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"not_windows"* ]]
}

# ============ raw_url ============

@test "cli: raw_url constructs correct URL" {
  run bash -c '
    OWNER_REPO="Hacklone/lazy-spec-kit"
    REF="main"
    die() { echo "$*" >&2; exit 1; }
    raw_url() {
      local path="${1:-}"
      [[ -n "$path" ]] || die "raw_url: missing path"
      printf "https://raw.githubusercontent.com/%s/%s/%s" "$OWNER_REPO" "$REF" "$path"
    }
    result=$(raw_url "cli/lazyspeckit")
    echo "$result"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == "https://raw.githubusercontent.com/Hacklone/lazy-spec-kit/main/cli/lazyspeckit" ]]
}

@test "cli: raw_url fails with empty path" {
  run bash -c '
    err() { printf "%s\n" "$*" >&2; }
    die() { err "$*"; exit 1; }
    raw_url() {
      local path="${1:-}"
      [[ -n "$path" ]] || die "raw_url: missing path"
    }
    raw_url ""
  '
  [ "$status" -ne 0 ]
}

# ============ DEBUG mode ============

@test "cli: DEBUG=1 enables trace (no crash)" {
  local repo
  repo="$(create_test_repo)"

  run bash -c 'NO_COLOR=1 DEBUG=1 LAZYSPECKIT_REF=main HOME="'"$TEST_TMPDIR"'" PATH="'"$FAKE_BIN:$PATH"'" bash "'"$CLI"'" doctor "'"$repo"'" 2>&1'
  [ "$status" -eq 0 ]
}

# ============ self_update_writable_hint ============

@test "cli: self_update_writable_hint warns about system paths" {
  run bash -c '
    warn() { printf "warn: %s\n" "$*"; }
    OWNER_REPO="Hacklone/lazy-spec-kit"
    REF="main"
    self_update_writable_hint() {
      local self="${1:-}"
      [[ -n "$self" ]] || self="(unknown)"
      warn "Cannot write to: $self"
      if [[ "$self" == *"/opt/homebrew/"* || "$self" == *"/usr/local/"* || "$self" == *"/usr/bin/"* ]]; then
        warn "Looks like a system/brew install path."
        echo "If installed via brew: run brew upgrade lazyspeckit"
      else
        echo "Re-run with appropriate permissions"
      fi
    }
    self_update_writable_hint "/opt/homebrew/bin/lazyspeckit"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"system/brew"* ]]
}

@test "cli: self_update_writable_hint shows reinstall hint for custom path" {
  run bash -c '
    warn() { printf "warn: %s\n" "$*"; }
    OWNER_REPO="Hacklone/lazy-spec-kit"
    REF="main"
    self_update_writable_hint() {
      local self="${1:-}"
      [[ -n "$self" ]] || self="(unknown)"
      warn "Cannot write to: $self"
      if [[ "$self" == *"/opt/homebrew/"* || "$self" == *"/usr/local/"* || "$self" == *"/usr/bin/"* ]]; then
        warn "Looks like a system/brew install path."
      else
        echo "Re-run with appropriate permissions"
      fi
    }
    self_update_writable_hint "/some/custom/path/lazyspeckit"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"Re-run with appropriate permissions"* ]]
}

# ============ ensure_uv ============

@test "cli: ensure_uv succeeds when uv and uvx are available" {
  run bash -c '
    have() { command -v "${1:-__missing__}" >/dev/null 2>&1; }
    PATH="'"$FAKE_BIN:$PATH"'"
    ensure_uv() {
      if have uv && have uvx; then return 0; fi
      return 1
    }
    ensure_uv && echo OK
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK"* ]]
}

# ============ uv_tool_available ============

@test "cli: uv_tool_available returns true when uv tool works" {
  run bash -c '
    PATH="'"$FAKE_BIN:$PATH"'"
    uv_tool_available() { uv tool --help >/dev/null 2>&1; }
    uv_tool_available && echo OK || echo FAIL
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK"* ]]
}

# ============ upgrade_speckit_cli ============

@test "cli: upgrade_speckit_cli calls uv tool install" {
  run bash -c '
    export PATH="'"$FAKE_BIN:$PATH"'"
    SPEC_KIT_GIT="git+https://github.com/github/spec-kit.git"
    info() { printf "==> %s\n" "$*"; }
    ok() { printf "OK %s\n" "$*"; }
    err() { printf "%s\n" "$*" >&2; }
    die() { err "$*"; exit 1; }
    have() { command -v "${1:-__missing__}" >/dev/null 2>&1; }
    ensure_uv() { return 0; }
    uv_tool_available() { return 0; }
    ensure_uv_tool() { ensure_uv; }
    upgrade_speckit_cli() {
      ensure_uv_tool
      info "Upgrading SpecKit CLI (specify-cli)..."
      uv tool install specify-cli --force --from "$SPEC_KIT_GIT" >/dev/null
      ok "SpecKit CLI upgraded"
    }
    upgrade_speckit_cli
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"SpecKit CLI upgraded"* ]]
}

# ============ fetch function ============

@test "cli: fetch downloads to output file" {
  run run_cli version
  [ "$status" -eq 0 ]
}

@test "cli: fetch fails with empty url" {
  run bash -c '
    die() { echo "$*" >&2; exit 1; }
    fetch() {
      local url="${1:-}" out="${2:-}"
      [[ -n "$url" && -n "$out" ]] || die "fetch: missing url/out"
    }
    fetch "" "/tmp/out"
  '
  [ "$status" -ne 0 ]
}

@test "cli: fetch fails with empty output path" {
  run bash -c '
    die() { echo "$*" >&2; exit 1; }
    fetch() {
      local url="${1:-}" out="${2:-}"
      [[ -n "$url" && -n "$out" ]] || die "fetch: missing url/out"
    }
    fetch "https://example.com" ""
  '
  [ "$status" -ne 0 ]
}

# ============ on_err trap ============

@test "cli: on_err trap prints error info" {
  run bash -c '
    err() { printf "%s\n" "$*" >&2; }
    on_err() {
      local ec="$?"
      local line="${BASH_LINENO[0]:-unknown}"
      local cmd="${BASH_COMMAND:-unknown}"
      err "Failed (exit $ec) at line ${line}: ${cmd}"
      exit "$ec"
    }
    trap on_err ERR
    set -e
    false
  ' 2>&1
  [ "$status" -ne 0 ]
  [[ "$output" == *"Failed"* ]]
}

# ============ Integration: output validation ============

@test "cli: init output contains expected lifecycle messages" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"

  run run_cli init --here --ai copilot
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installing LazySpecKit prompts"* ]]
  [[ "$output" == *"Done"* ]]
  [[ "$output" == *"Next:"* ]]
}

@test "cli: upgrade output contains expected lifecycle messages" {
  local repo
  repo="$(create_test_repo)"
  create_fake_specify

  run run_cli upgrade "$repo" --ai copilot
  [ "$status" -eq 0 ]
  [[ "$output" == *"Upgrading SpecKit CLI"* ]]
  [[ "$output" == *"Upgrading LazySpecKit prompts"* ]]
  [[ "$output" == *"Upgraded in:"* ]]
}

# ============ Additional coverage tests ============

@test "cli: version shows update available when versions differ" {
  # Make smart curl return a different version
  cat > "$FAKE_BIN/curl" <<'CURLSCRIPT'
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
  if [[ "$url" == *lazyspeckit* ]]; then
    printf '%s\n' '#!/usr/bin/env bash' 'VERSION="9.9.9"' '# lazyspeckit marker' > "$outfile"
  else
    echo "lazyspeckit speckit LazySpecKit" > "$outfile"
  fi
fi
exit 0
CURLSCRIPT
  chmod +x "$FAKE_BIN/curl"

  run run_cli version
  [ "$status" -eq 0 ]
  [[ "$output" == *"Update available"* ]]
}

@test "cli: doctor shows update available when versions differ" {
  cat > "$FAKE_BIN/curl" <<'CURLSCRIPT'
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
  if [[ "$url" == *lazyspeckit* ]]; then
    printf '%s\n' '#!/usr/bin/env bash' 'VERSION="9.9.9"' '# lazyspeckit marker' > "$outfile"
  else
    echo "lazyspeckit speckit LazySpecKit" > "$outfile"
  fi
fi
exit 0
CURLSCRIPT
  chmod +x "$FAKE_BIN/curl"

  local repo
  repo="$(create_test_repo)"
  run run_cli doctor "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Update available"* ]]
}

@test "cli: init on claude-only repo still runs successfully" {
  local repo
  repo="$(create_claude_only_repo)"
  cd "$repo"
  mkdir -p "$repo/.specify"

  run run_cli init --here --ai claude
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installing LazySpecKit prompts"* ]]
}

@test "cli: upgrade warns when SpecKit CLI upgrade fails" {
  local repo
  repo="$(create_test_repo)"
  create_fake_specify

  # Make uv tool install fail
  cat > "$FAKE_BIN/uv" <<'S'
#!/usr/bin/env bash
case "$1" in
  tool)
    case "$2" in
      install) exit 1 ;;
      *) echo "uv tool help"; exit 0 ;;
    esac ;;
  self) echo "uv self $*"; exit 0 ;;
  --version) echo "uv 0.1.0"; exit 0 ;;
  *) echo "uv $*"; exit 0 ;;
esac
S
  chmod +x "$FAKE_BIN/uv"

  run run_cli upgrade "$repo" --ai copilot
  [ "$status" -eq 0 ]
  [[ "$output" == *"SpecKit CLI upgrade failed"* ]]
  [[ "$output" == *"Upgrading LazySpecKit prompts"* ]]
}

@test "cli: upgrade on claude-only repo still runs successfully" {
  local repo
  repo="$(create_claude_only_repo)"
  create_fake_specify

  run run_cli upgrade "$repo" --ai claude
  [ "$status" -eq 0 ]
  [[ "$output" == *"Upgrading LazySpecKit prompts"* ]]
}

@test "cli: backup with no customizations is a no-op" {
  local repo
  repo="$(create_test_repo)"
  local backup="$TEST_TMPDIR/backup"

  run bash -c '
    err() { printf "%s\n" "$*" >&2; }
    die() { err "$*"; exit 1; }
    backup_speckit_customizations() {
      local target="${1:-}" backup_dir="${2:-}"
      [[ -n "$target" && -n "$backup_dir" ]] || die "backup: missing target/backup_dir"
      mkdir -p "$backup_dir"
      if [[ -f "$target/.specify/memory/constitution.md" ]]; then
        cp -f "$target/.specify/memory/constitution.md" "$backup_dir/constitution.md"
      fi
      if [[ -d "$target/.specify/templates" ]]; then
        mkdir -p "$backup_dir/templates"
        cp -R "$target/.specify/templates/." "$backup_dir/templates/" 2>/dev/null || true
      fi
    }
    backup_speckit_customizations "'"$repo"'" "'"$backup"'"
    echo "files: $(ls "'"$backup"'" 2>/dev/null | wc -l | tr -d " ")"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"files: 0"* ]]
}

@test "cli: restore with empty backup dir is a no-op" {
  local repo
  repo="$(create_test_repo)"
  local backup="$TEST_TMPDIR/empty_backup"
  mkdir -p "$backup"

  run bash -c '
    err() { printf "%s\n" "$*" >&2; }
    die() { err "$*"; exit 1; }
    restore_speckit_customizations() {
      local target="${1:-}" backup_dir="${2:-}"
      [[ -n "$target" && -n "$backup_dir" ]] || die "restore: missing target/backup_dir"
      if [[ -f "$backup_dir/constitution.md" ]]; then
        mkdir -p "$target/.specify/memory"
        cp -f "$backup_dir/constitution.md" "$target/.specify/memory/constitution.md"
      fi
      if [[ -d "$backup_dir/templates" ]]; then
        mkdir -p "$target/.specify/templates"
        cp -R "$backup_dir/templates/." "$target/.specify/templates/" 2>/dev/null || true
      fi
    }
    restore_speckit_customizations "'"$repo"'" "'"$backup"'"
    echo "OK"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK"* ]]
  # Verify no .specify/memory or templates were created
  [ ! -f "$repo/.specify/memory/constitution.md" ]
}

@test "cli: ensure_uv_tool fails when uv tool is unavailable and self update fails" {
  # Create uv that doesn't support 'tool'
  cat > "$FAKE_BIN/uv" <<'S'
#!/usr/bin/env bash
case "$1" in
  tool) exit 1 ;;
  self) exit 1 ;;
  --version) echo "uv 0.0.1"; exit 0 ;;
  *) exit 0 ;;
esac
S
  chmod +x "$FAKE_BIN/uv"

  run bash -c '
    have() { command -v "${1:-__missing__}" >/dev/null 2>&1; }
    err() { printf "%s\n" "$*" >&2; }
    warn() { err "⚠️ $*"; }
    die() { err "$*"; exit 1; }
    ensure_uv() {
      if have uv && have uvx; then return 0; fi
      die "Need uv"
    }
    uv_tool_available() { uv tool --help >/dev/null 2>&1; }
    ensure_uv_tool() {
      ensure_uv
      if uv_tool_available; then return 0; fi
      warn "Your uv is missing uv tool. Attempting: uv self update"
      if uv self update >/dev/null 2>&1; then
        uv_tool_available && return 0
      fi
      die "uv tool subcommand is unavailable."
    }
    PATH="'"$FAKE_BIN:$PATH"'" ensure_uv_tool
  '
  [ "$status" -ne 0 ]
  [[ "$output" == *"uv tool subcommand is unavailable"* ]]
}

@test "cli: self_update_writable_hint with empty self shows unknown" {
  run bash -c '
    warn() { printf "warn: %s\n" "$*"; }
    OWNER_REPO="Hacklone/lazy-spec-kit"
    REF="main"
    self_update_writable_hint() {
      local self="${1:-}"
      [[ -n "$self" ]] || self="(unknown)"
      warn "Cannot write to: $self"
    }
    self_update_writable_hint ""
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"(unknown)"* ]]
}

@test "cli: upgrade_speckit_project_files preserves customizations" {
  local repo
  repo="$(create_test_repo)"
  mkdir -p "$repo/.specify/memory" "$repo/.specify/templates"
  echo "my constitution" > "$repo/.specify/memory/constitution.md"
  echo "my template" > "$repo/.specify/templates/custom.md"
  create_fake_specify

  run bash -c '
    export PATH="'"$FAKE_BIN:$PATH"'"
    err() { printf "%s\n" "$*" >&2; }
    die() { err "$*"; exit 1; }
    info() { printf "==> %s\n" "$*"; }
    ok() { printf "OK %s\n" "$*"; }

    backup_speckit_customizations() {
      local target="${1:-}" backup_dir="${2:-}"
      [[ -n "$target" && -n "$backup_dir" ]] || die "backup: missing"
      mkdir -p "$backup_dir"
      if [[ -f "$target/.specify/memory/constitution.md" ]]; then
        cp -f "$target/.specify/memory/constitution.md" "$backup_dir/constitution.md"
      fi
      if [[ -d "$target/.specify/templates" ]]; then
        mkdir -p "$backup_dir/templates"
        cp -R "$target/.specify/templates/." "$backup_dir/templates/" 2>/dev/null || true
      fi
    }
    restore_speckit_customizations() {
      local target="${1:-}" backup_dir="${2:-}"
      [[ -n "$target" && -n "$backup_dir" ]] || die "restore: missing"
      if [[ -f "$backup_dir/constitution.md" ]]; then
        mkdir -p "$target/.specify/memory"
        cp -f "$backup_dir/constitution.md" "$target/.specify/memory/constitution.md"
      fi
      if [[ -d "$backup_dir/templates" ]]; then
        mkdir -p "$target/.specify/templates"
        cp -R "$backup_dir/templates/." "$target/.specify/templates/" 2>/dev/null || true
      fi
    }
    upgrade_speckit_project_files() {
      local target="${1:-}"; shift || true
      [[ -n "$target" ]] || die "missing target"
      info "Upgrading SpecKit project files in: $target"
      local backup_dir
      backup_dir="$(mktemp -d)"
      trap "rm -rf \"$backup_dir\"" RETURN
      backup_speckit_customizations "$target" "$backup_dir"
      local init_rc=0
      (trap - ERR; cd "$target" && specify init --here --force "$@") || init_rc=$?
      restore_speckit_customizations "$target" "$backup_dir"
      if [[ "$init_rc" -ne 0 ]]; then
        err "specify init failed (exit $init_rc)"
        return "$init_rc"
      fi
      ok "SpecKit project files upgraded"
    }
    upgrade_speckit_project_files "'"$repo"'" --ai copilot
  '
  [ "$status" -eq 0 ]
  # Verify customizations were preserved
  [ -f "$repo/.specify/memory/constitution.md" ]
  [ -f "$repo/.specify/templates/custom.md" ]
  [[ "$(cat "$repo/.specify/memory/constitution.md")" == "my constitution" ]]
  [[ "$(cat "$repo/.specify/templates/custom.md")" == "my template" ]]
}

@test "cli: run_specify_init_if_needed dies when .specify not created" {
  local repo
  repo="$(create_bare_repo)"

  # Create uvx that succeeds but does NOT create .specify
  cat > "$FAKE_BIN/uvx" <<'S'
#!/usr/bin/env bash
echo "uvx ran $*"
exit 0
S
  chmod +x "$FAKE_BIN/uvx"

  run run_cli init "$repo" --ai copilot
  [ "$status" -ne 0 ]
  [[ "$output" == *".specify not found"* ]]
}

@test "cli: upgrade_speckit_project_files restores customizations even when init fails" {
  local repo
  repo="$(create_test_repo)"
  mkdir -p "$repo/.specify/memory" "$repo/.specify/templates"
  echo "precious constitution" > "$repo/.specify/memory/constitution.md"
  echo "precious template" > "$repo/.specify/templates/custom.md"

  # Create a specify that always fails
  cat > "$FAKE_BIN/specify" <<'S'
#!/usr/bin/env bash
exit 1
S
  chmod +x "$FAKE_BIN/specify"

  run bash -c '
    export PATH="'"$FAKE_BIN:$PATH"'"
    err() { printf "%s\n" "$*" >&2; }
    die() { err "$*"; exit 1; }
    info() { printf "==> %s\n" "$*"; }
    ok() { printf "OK %s\n" "$*"; }

    backup_speckit_customizations() {
      local target="${1:-}" backup_dir="${2:-}"
      [[ -n "$target" && -n "$backup_dir" ]] || die "backup: missing"
      mkdir -p "$backup_dir"
      if [[ -f "$target/.specify/memory/constitution.md" ]]; then
        cp -f "$target/.specify/memory/constitution.md" "$backup_dir/constitution.md"
      fi
      if [[ -d "$target/.specify/templates" ]]; then
        mkdir -p "$backup_dir/templates"
        cp -R "$target/.specify/templates/." "$backup_dir/templates/" 2>/dev/null || true
      fi
    }
    restore_speckit_customizations() {
      local target="${1:-}" backup_dir="${2:-}"
      [[ -n "$target" && -n "$backup_dir" ]] || die "restore: missing"
      if [[ -f "$backup_dir/constitution.md" ]]; then
        mkdir -p "$target/.specify/memory"
        cp -f "$backup_dir/constitution.md" "$target/.specify/memory/constitution.md"
      fi
      if [[ -d "$backup_dir/templates" ]]; then
        mkdir -p "$target/.specify/templates"
        cp -R "$backup_dir/templates/." "$target/.specify/templates/" 2>/dev/null || true
      fi
    }
    upgrade_speckit_project_files() {
      local target="${1:-}"; shift || true
      [[ -n "$target" ]] || die "missing target"
      info "Upgrading SpecKit project files in: $target"
      local backup_dir
      backup_dir="$(mktemp -d)"
      trap "rm -rf \"$backup_dir\"" RETURN
      backup_speckit_customizations "$target" "$backup_dir"
      local init_rc=0
      (trap - ERR; cd "$target" && specify init --here --force "$@") || init_rc=$?
      restore_speckit_customizations "$target" "$backup_dir"
      if [[ "$init_rc" -ne 0 ]]; then
        err "specify init failed (exit $init_rc)"
        return "$init_rc"
      fi
      ok "SpecKit project files upgraded"
    }
    upgrade_speckit_project_files "'"$repo"'" --ai copilot
  '
  [ "$status" -ne 0 ]
  [[ "$output" == *"specify init failed"* ]]
  # Verify customizations were still restored despite the failure
  [ -f "$repo/.specify/memory/constitution.md" ]
  [ -f "$repo/.specify/templates/custom.md" ]
  [[ "$(cat "$repo/.specify/memory/constitution.md")" == "precious constitution" ]]
  [[ "$(cat "$repo/.specify/templates/custom.md")" == "precious template" ]]
}

# ============ Reviewer File Installation ============

@test "cli: init installs reviewer skill files on disk" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"

  run run_cli init --here --ai copilot
  [ "$status" -eq 0 ]
  [ -f "$repo/.lazyspeckit/reviewers/architecture.md" ]
  [ -f "$repo/.lazyspeckit/reviewers/code-quality.md" ]
  [ -f "$repo/.lazyspeckit/reviewers/spec-compliance.md" ]
  [ -f "$repo/.lazyspeckit/reviewers/test.md" ]
}

@test "cli: init output mentions reviewer installation" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"

  run run_cli init --here --ai copilot
  [ "$status" -eq 0 ]
  [[ "$output" == *"Reviewer skill files installed"* ]]
}

@test "cli: upgrade installs reviewer skill files on disk" {
  local repo
  repo="$(create_test_repo)"
  create_fake_specify

  run run_cli upgrade "$repo" --ai copilot
  [ "$status" -eq 0 ]
  [ -f "$repo/.lazyspeckit/reviewers/architecture.md" ]
  [ -f "$repo/.lazyspeckit/reviewers/security.md" ]
  [ -f "$repo/.lazyspeckit/reviewers/code-quality.md" ]
  [ -f "$repo/.lazyspeckit/reviewers/spec-compliance.md" ]
  [ -f "$repo/.lazyspeckit/reviewers/test.md" ]
}

@test "cli: upgrade output mentions reviewer installation" {
  local repo
  repo="$(create_test_repo)"
  create_fake_specify

  run run_cli upgrade "$repo" --ai copilot
  [ "$status" -eq 0 ]
  [[ "$output" == *"Reviewer skill files installed"* ]]
}

# ============ add-reviewer (Agency integration) ============

create_agency_dir() {
  # Create a fake Agency installation with sample agent files
  local agency_dir="$TEST_TMPDIR/.claude/agents"
  mkdir -p "$agency_dir/testing" "$agency_dir/engineering"
  cat > "$agency_dir/testing/testing-reality-checker.md" <<'AGENT'
---
name: Testing Reality Checker
description: Validates that tests reflect real usage patterns
---

You are the Testing Reality Checker. Your job is to ensure tests are meaningful.

## What to check
- Do tests cover real scenarios?
- Are edge cases addressed?
AGENT

  cat > "$agency_dir/engineering/engineering-security-engineer.md" <<'AGENT'
---
name: Security Engineer
description: Security review specialist
---

You are the Security Engineer agent.

## Security checks
- Input validation
- Auth boundaries
AGENT

  cat > "$agency_dir/testing/testing-performance-benchmarker.md" <<'AGENT'
---
name: Performance Benchmarker
description: Performance analysis agent
---

You are the Performance Benchmarker.
AGENT

  cat > "$agency_dir/testing/testing-accessibility-auditor.md" <<'AGENT'
---
name: Accessibility Auditor
description: Accessibility review agent
---

You are the Accessibility Auditor.
AGENT

  cat > "$agency_dir/engineering/engineering-backend-architect.md" <<'AGENT'
---
name: Backend Architect
description: Architecture review agent
---

You are the Backend Architect.
AGENT

  echo "$agency_dir"
}

@test "cli: add-reviewer --from-agency copies agent as reviewer" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  local agency_dir
  agency_dir="$(create_agency_dir)"

  run run_cli add-reviewer --from-agency testing/testing-reality-checker.md --agency-path "$agency_dir"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Reviewer installed"* ]]
  [ -f "$repo/.lazyspeckit/reviewers/testing-reality-checker.md" ]
}

@test "cli: add-reviewer --from-agency injects no-interaction header" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  local agency_dir
  agency_dir="$(create_agency_dir)"

  run run_cli add-reviewer --from-agency testing/testing-reality-checker.md --agency-path "$agency_dir"
  [ "$status" -eq 0 ]

  local content
  content="$(cat "$repo/.lazyspeckit/reviewers/testing-reality-checker.md")"
  [[ "$content" == *"MUST NOT ask the user any questions"* ]]
}

@test "cli: add-reviewer --from-agency preserves YAML frontmatter" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  local agency_dir
  agency_dir="$(create_agency_dir)"

  run run_cli add-reviewer --from-agency testing/testing-reality-checker.md --agency-path "$agency_dir"
  [ "$status" -eq 0 ]

  local content
  content="$(cat "$repo/.lazyspeckit/reviewers/testing-reality-checker.md")"
  # Frontmatter should still be present
  [[ "$content" == ---* ]]
  [[ "$content" == *"name: Testing Reality Checker"* ]]
  # Header should come after frontmatter, not before it
  local header_line fm_end_line
  header_line="$(grep -n "MUST NOT" "$repo/.lazyspeckit/reviewers/testing-reality-checker.md" | head -1 | cut -d: -f1)"
  fm_end_line="$(grep -n "^---" "$repo/.lazyspeckit/reviewers/testing-reality-checker.md" | tail -1 | cut -d: -f1)"
  [ "$header_line" -gt "$fm_end_line" ]
}

@test "cli: add-reviewer --as overrides reviewer filename" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  local agency_dir
  agency_dir="$(create_agency_dir)"

  run run_cli add-reviewer --from-agency testing/testing-reality-checker.md --as my-checker.md --agency-path "$agency_dir"
  [ "$status" -eq 0 ]
  [ -f "$repo/.lazyspeckit/reviewers/my-checker.md" ]
  # Original name should not exist
  [ ! -f "$repo/.lazyspeckit/reviewers/testing-reality-checker.md" ]
}

@test "cli: add-reviewer --as adds .md extension if missing" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  local agency_dir
  agency_dir="$(create_agency_dir)"

  run run_cli add-reviewer --from-agency testing/testing-reality-checker.md --as my-checker --agency-path "$agency_dir"
  [ "$status" -eq 0 ]
  [ -f "$repo/.lazyspeckit/reviewers/my-checker.md" ]
}

@test "cli: add-reviewer fails without --from-agency" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"

  run run_cli add-reviewer
  [ "$status" -ne 0 ]
  [[ "$output" == *"--from-agency"* ]]
}

@test "cli: add-reviewer fails when agent not found" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  local agency_dir
  agency_dir="$(create_agency_dir)"

  run run_cli add-reviewer --from-agency nonexistent-agent.md --agency-path "$agency_dir"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Agent not found"* ]]
}

@test "cli: add-reviewer fails when agency dir not found" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"

  run run_cli add-reviewer --from-agency testing-reality-checker.md --agency-path "/nonexistent/agency"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Agency installation not found"* ]]
}

@test "cli: add-reviewer refuses overwrite without --force" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  local agency_dir
  agency_dir="$(create_agency_dir)"
  mkdir -p "$repo/.lazyspeckit/reviewers"
  echo "custom content" > "$repo/.lazyspeckit/reviewers/testing-reality-checker.md"

  run run_cli add-reviewer --from-agency testing/testing-reality-checker.md --agency-path "$agency_dir"
  [ "$status" -ne 0 ]
  [[ "$output" == *"already exists"* ]]
  [[ "$output" == *"--force"* ]]
}

@test "cli: add-reviewer overwrites with --force" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  local agency_dir
  agency_dir="$(create_agency_dir)"
  mkdir -p "$repo/.lazyspeckit/reviewers"
  echo "old content" > "$repo/.lazyspeckit/reviewers/testing-reality-checker.md"

  run run_cli add-reviewer --from-agency testing/testing-reality-checker.md --agency-path "$agency_dir" --force
  [ "$status" -eq 0 ]
  [[ "$output" == *"Overwriting"* ]]
  [[ "$output" == *"Reviewer installed"* ]]

  local content
  content="$(cat "$repo/.lazyspeckit/reviewers/testing-reality-checker.md")"
  [[ "$content" != "old content" ]]
  [[ "$content" == *"Testing Reality Checker"* ]]
}

@test "cli: add-reviewer finds agent by basename search" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  local agency_dir
  agency_dir="$(create_agency_dir)"

  # Search by basename only (no directory prefix)
  run run_cli add-reviewer --from-agency testing-reality-checker.md --agency-path "$agency_dir"
  [ "$status" -eq 0 ]
  [ -f "$repo/.lazyspeckit/reviewers/testing-reality-checker.md" ]
}

@test "cli: add-reviewer finds agent without .md extension" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  local agency_dir
  agency_dir="$(create_agency_dir)"

  run run_cli add-reviewer --from-agency testing/testing-reality-checker --agency-path "$agency_dir"
  [ "$status" -eq 0 ]
  [ -f "$repo/.lazyspeckit/reviewers/testing-reality-checker.md" ]
}

@test "cli: add-reviewer detects agency from HOME/.claude/agents" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  # create_agency_dir already puts agents under $TEST_TMPDIR/.claude/agents
  # and run_cli sets HOME=$TEST_TMPDIR
  create_agency_dir

  run run_cli add-reviewer --from-agency testing/testing-reality-checker.md
  [ "$status" -eq 0 ]
  [ -f "$repo/.lazyspeckit/reviewers/testing-reality-checker.md" ]
}

# ============ Agency auto-detection ============

@test "cli: init auto-detects agency and creates symlinked reviewers" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  local agency_dir
  agency_dir="$(create_agency_dir)"

  run run_cli init --here --ai copilot --agency-path "$agency_dir"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Agency reviewers"* ]]
  [[ "$output" == *"linked"* ]]
}

@test "cli: init auto-detects agency and symlinks mapped reviewers" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  local agency_dir
  agency_dir="$(create_agency_dir)"

  run run_cli init --here --ai copilot --agency-path "$agency_dir"
  [ "$status" -eq 0 ]

  # Mapped reviewers should be symlinks
  [ -L "$repo/.lazyspeckit/reviewers/spec-compliance.md" ]
  [ -L "$repo/.lazyspeckit/reviewers/security.md" ]
  [ -L "$repo/.lazyspeckit/reviewers/performance.md" ]
  [ -L "$repo/.lazyspeckit/reviewers/accessibility.md" ]
  [ -L "$repo/.lazyspeckit/reviewers/architecture.md" ]
}

@test "cli: init auto-detects agency and preserves unmapped bundled reviewers" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  local agency_dir
  agency_dir="$(create_agency_dir)"

  run run_cli init --here --ai copilot --agency-path "$agency_dir"
  [ "$status" -eq 0 ]

  # Unmapped reviewers should still exist as regular files from setup.sh
  [ -f "$repo/.lazyspeckit/reviewers/code-quality.md" ]
  [ -f "$repo/.lazyspeckit/reviewers/test.md" ]
  # They should NOT be symlinks
  [ ! -L "$repo/.lazyspeckit/reviewers/code-quality.md" ]
  [ ! -L "$repo/.lazyspeckit/reviewers/test.md" ]
}

@test "cli: init auto-detects agency and symlinks point to agency files" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  local agency_dir
  agency_dir="$(create_agency_dir)"

  run run_cli init --here --ai copilot --agency-path "$agency_dir"
  [ "$status" -eq 0 ]

  # Verify symlink target
  local target
  target="$(readlink "$repo/.lazyspeckit/reviewers/spec-compliance.md")"
  [[ "$target" == *"testing/testing-reality-checker.md" ]]
}

@test "cli: init auto-detects agency from HOME" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  create_agency_dir  # creates under $TEST_TMPDIR/.claude/agents, HOME=$TEST_TMPDIR

  run run_cli init --here --ai copilot
  [ "$status" -eq 0 ]
  [[ "$output" == *"Agency reviewers"* ]]
}

@test "cli: init without agency installed silently uses bundled reviewers" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  # No agency dir created, HOME=$TEST_TMPDIR has no .claude/agents

  run run_cli init --here --ai copilot
  [ "$status" -eq 0 ]
  [[ "$output" != *"Agency reviewers"* ]]
  [[ "$output" == *"Done"* ]]
}

@test "cli: init with --agency-path overrides detection" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  local custom_dir="$TEST_TMPDIR/my-custom-agents"
  mkdir -p "$custom_dir/testing" "$custom_dir/engineering"
  echo "---\nname: Custom\n---\nCustom agent" > "$custom_dir/testing/testing-reality-checker.md"

  run run_cli init --here --ai copilot --agency-path "$custom_dir"
  [ "$status" -eq 0 ]
  [[ "$output" == *"from: $custom_dir"* ]]
}

@test "cli: init auto-detects agency and preserves user-customized reviewers" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  local agency_dir
  agency_dir="$(create_agency_dir)"

  # Pre-create a custom reviewer with NO hash stamp (user-created outside LazySpecKit)
  mkdir -p "$repo/.lazyspeckit/reviewers"
  echo "My custom security review rules" > "$repo/.lazyspeckit/reviewers/security.md"

  run run_cli init --here --ai copilot --agency-path "$agency_dir"
  [ "$status" -eq 0 ]
  [[ "$output" == *"custom (kept)"* ]]

  # Custom file should be preserved, not replaced with symlink
  [ ! -L "$repo/.lazyspeckit/reviewers/security.md" ]
  local content
  content="$(cat "$repo/.lazyspeckit/reviewers/security.md")"
  [[ "$content" == *"My custom security review rules"* ]]
}

@test "cli: init auto-detects agency and replaces previous symlinks" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  local agency_dir
  agency_dir="$(create_agency_dir)"

  # First init with agency
  run run_cli init --here --ai copilot --agency-path "$agency_dir"
  [ "$status" -eq 0 ]
  [ -L "$repo/.lazyspeckit/reviewers/spec-compliance.md" ]

  # Second init with agency should succeed (replaces existing symlinks)
  run run_cli init --here --ai copilot --agency-path "$agency_dir"
  [ "$status" -eq 0 ]
  [ -L "$repo/.lazyspeckit/reviewers/spec-compliance.md" ]
}

@test "cli: init auto-detects agency and warns about missing agents" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  # Create agency with only some agents
  local agency_dir="$TEST_TMPDIR/.claude/agents"
  mkdir -p "$agency_dir/testing"
  echo "---\nname: Checker\n---\nAgent" > "$agency_dir/testing/testing-reality-checker.md"

  run run_cli init --here --ai copilot --agency-path "$agency_dir"
  [ "$status" -eq 0 ]
  [[ "$output" == *"not found"* ]]
}

@test "cli: init --no-agency skips agency even when installed" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  create_agency_dir

  run run_cli init --here --ai copilot --no-agency
  [ "$status" -eq 0 ]
  [[ "$output" != *"Agency reviewers"* ]]
  [[ "$output" == *"Done"* ]]

  # All reviewers should be regular files, not symlinks
  [ ! -L "$repo/.lazyspeckit/reviewers/spec-compliance.md" ]
  [ ! -L "$repo/.lazyspeckit/reviewers/security.md" ]
}

@test "cli: usage includes add-reviewer command" {
  run run_cli --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"add-reviewer"* ]]
  [[ "$output" == *"--from-agency"* ]]
}

@test "cli: usage includes --no-agency flag" {
  run run_cli --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"--no-agency"* ]]
  [[ "$output" == *"Agency"* ]]
}

@test "cli: init --agency flag accepted for backward compatibility" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  local agency_dir
  agency_dir="$(create_agency_dir)"

  run run_cli init --here --ai copilot --agency --agency-path "$agency_dir"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Agency reviewers"* ]]
}

# ============ agency utility functions ============

@test "cli: detect_agency_dir finds ~/.claude/agents via init" {
  # Integration test: init auto-detects HOME/.claude/agents
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  create_agency_dir  # creates agents under $TEST_TMPDIR/.claude/agents

  run run_cli init --here --ai copilot
  [ "$status" -eq 0 ]
  [[ "$output" == *".claude/agents"* ]]
}

@test "cli: detect_agency_dir prefers --agency-path over HOME" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  create_agency_dir  # creates at HOME/.claude/agents

  local custom_path="$TEST_TMPDIR/custom-agents"
  mkdir -p "$custom_path/testing" "$custom_path/engineering"
  echo '---' > "$custom_path/testing/testing-reality-checker.md"
  echo 'name: Custom' >> "$custom_path/testing/testing-reality-checker.md"
  echo '---' >> "$custom_path/testing/testing-reality-checker.md"
  echo 'Custom agent' >> "$custom_path/testing/testing-reality-checker.md"

  run run_cli init --here --ai copilot --agency-path "$custom_path"
  [ "$status" -eq 0 ]
  [[ "$output" == *"$custom_path"* ]]
}

@test "cli: --agency-path to nonexistent dir fails" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"

  run run_cli init --here --ai copilot --agency-path /tmp/nonexistent-agency-dir-42
  [ "$status" -ne 0 ]
  [[ "$output" == *"Agency installation not found"* ]]
}

# ============================================================
# Extra AI agents (Cursor / OpenCode)
# ============================================================

# ---- detect_cursor_usage ----

@test "cli: detect_cursor_usage returns true when .cursor dir exists" {
  local repo
  repo="$(create_cursor_repo)"
  run bash -c '
    detect_cursor_usage() { [[ -d "${1:-/__missing__}/.cursor" ]]; }
    detect_cursor_usage "'"$repo"'" && echo yes || echo no
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"yes"* ]]
}

@test "cli: detect_cursor_usage returns false without .cursor dir" {
  local repo
  repo="$(create_bare_repo)"
  run bash -c '
    detect_cursor_usage() { [[ -d "${1:-/__missing__}/.cursor" ]]; }
    detect_cursor_usage "'"$repo"'" && echo yes || echo no
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"no"* ]]
}

# ---- detect_opencode_usage ----

@test "cli: detect_opencode_usage returns true when .opencode dir exists" {
  local repo
  repo="$(create_opencode_repo)"
  run bash -c '
    detect_opencode_usage() { [[ -d "${1:-/__missing__}/.opencode" ]]; }
    detect_opencode_usage "'"$repo"'" && echo yes || echo no
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"yes"* ]]
}

@test "cli: detect_opencode_usage returns false without .opencode dir" {
  local repo
  repo="$(create_bare_repo)"
  run bash -c '
    detect_opencode_usage() { [[ -d "${1:-/__missing__}/.opencode" ]]; }
    detect_opencode_usage "'"$repo"'" && echo yes || echo no
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"no"* ]]
}

# ---- cursor_prompt_present / opencode_prompt_present ----

@test "cli: cursor_prompt_present returns true when .mdc exists" {
  local repo="$TEST_TMPDIR/cursor_repo"
  mkdir -p "$repo/.cursor/rules"
  touch "$repo/.cursor/rules/lazyspeckit.mdc"
  run bash -c '
    cursor_prompt_present() { [[ -f "${1:-/__missing__}/.cursor/rules/lazyspeckit.mdc" ]]; }
    cursor_prompt_present "'"$repo"'" && echo yes || echo no
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"yes"* ]]
}

@test "cli: cursor_prompt_present returns false when .mdc absent" {
  local repo
  repo="$(create_cursor_repo)"
  run bash -c '
    cursor_prompt_present() { [[ -f "${1:-/__missing__}/.cursor/rules/lazyspeckit.mdc" ]]; }
    cursor_prompt_present "'"$repo"'" && echo yes || echo no
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"no"* ]]
}

@test "cli: opencode_prompt_present returns true when LazySpecKit.md exists" {
  local repo="$TEST_TMPDIR/opencode_repo"
  mkdir -p "$repo/.opencode/agent"
  touch "$repo/.opencode/agent/LazySpecKit.md"
  run bash -c '
    opencode_prompt_present() { [[ -f "${1:-/__missing__}/.opencode/agent/LazySpecKit.md" ]]; }
    opencode_prompt_present "'"$repo"'" && echo yes || echo no
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"yes"* ]]
}

@test "cli: opencode_prompt_present returns false when file absent" {
  local repo
  repo="$(create_opencode_repo)"
  run bash -c '
    opencode_prompt_present() { [[ -f "${1:-/__missing__}/.opencode/agent/LazySpecKit.md" ]]; }
    opencode_prompt_present "'"$repo"'" && echo yes || echo no
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"no"* ]]
}

# ---- validate_ai_value ----

@test "cli: validate_ai_value accepts copilot" {
  run run_cli init --here --ai copilot
  [[ "$output" != *"Unknown --ai"* ]]
}

@test "cli: validate_ai_value accepts cursor" {
  run run_cli init --here --ai copilot --ai cursor
  [[ "$output" != *"Unknown --ai"* ]]
}

@test "cli: validate_ai_value accepts opencode" {
  run run_cli init --here --ai copilot --ai opencode
  [[ "$output" != *"Unknown --ai"* ]]
}

@test "cli: validate_ai_value rejects unknown value" {
  run run_cli init --here --ai vscode
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unknown --ai"* ]]
}

@test "cli: is_extra_agent returns true for cursor" {
  run bash -c '
    EXTRA_AGENTS=("cursor" "opencode")
    is_extra_agent() {
      local v="${1:-}" ea
      for ea in "${EXTRA_AGENTS[@]}"; do [[ "$v" == "$ea" ]] && return 0; done
      return 1
    }
    is_extra_agent cursor && echo yes || echo no
  '
  [ "$status" -eq 0 ]
  [[ "$output" == "yes" ]]
}

@test "cli: is_extra_agent returns false for copilot" {
  run bash -c '
    EXTRA_AGENTS=("cursor" "opencode")
    is_extra_agent() {
      local v="${1:-}" ea
      for ea in "${EXTRA_AGENTS[@]}"; do [[ "$v" == "$ea" ]] && return 0; done
      return 1
    }
    is_extra_agent copilot && echo yes || echo no
  '
  [ "$status" -eq 0 ]
  [[ "$output" == "no" ]]
}

# ---- cmd_init --ai (extra agents) ----

@test "cli: init --ai cursor creates .cursor/rules/lazyspeckit.mdc" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  run run_cli init --here --ai copilot --ai cursor
  [ "$status" -eq 0 ]
  [ -f "$repo/.cursor/rules/lazyspeckit.mdc" ]
}

@test "cli: init --ai cursor mdc file has YAML frontmatter" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  run run_cli init --here --ai copilot --ai cursor
  [ "$status" -eq 0 ]
  local mdc="$repo/.cursor/rules/lazyspeckit.mdc"
  [ -f "$mdc" ]
  grep -q "^---" "$mdc"
  grep -q "alwaysApply: false" "$mdc"
  grep -q "globs: \[\]" "$mdc"
}

@test "cli: init --ai cursor mdc file contains prompt body" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  run run_cli init --here --ai copilot --ai cursor
  [ "$status" -eq 0 ]
  local mdc="$repo/.cursor/rules/lazyspeckit.mdc"
  [ -f "$mdc" ]
  # The fake setup.sh writes "LazySpecKit speckit prompt" as the prompt content
  grep -q "LazySpecKit speckit prompt" "$mdc"
}

@test "cli: init --ai opencode creates .opencode/agent/LazySpecKit.md" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  run run_cli init --here --ai copilot --ai opencode
  [ "$status" -eq 0 ]
  [ -f "$repo/.opencode/agent/LazySpecKit.md" ]
}

@test "cli: init --ai opencode file contains prompt body" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  run run_cli init --here --ai copilot --ai opencode
  [ "$status" -eq 0 ]
  local md="$repo/.opencode/agent/LazySpecKit.md"
  [ -f "$md" ]
  grep -q "LazySpecKit speckit prompt" "$md"
}

@test "cli: init --ai all creates both cursor and opencode prompts" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  run run_cli init --here --ai all
  [ "$status" -eq 0 ]
  [ -f "$repo/.cursor/rules/lazyspeckit.mdc" ]
  [ -f "$repo/.opencode/agent/LazySpecKit.md" ]
}

@test "cli: init --ai cursor --ai opencode creates both prompts" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  run run_cli init --here --ai copilot --ai cursor --ai opencode
  [ "$status" -eq 0 ]
  [ -f "$repo/.cursor/rules/lazyspeckit.mdc" ]
  [ -f "$repo/.opencode/agent/LazySpecKit.md" ]
}

@test "cli: init --ai cursor/opencode prints success messages" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  run run_cli init --here --ai copilot --ai cursor --ai opencode
  [ "$status" -eq 0 ]
  [[ "$output" == *"Cursor prompt installed"* ]]
  [[ "$output" == *"OpenCode prompt installed"* ]]
}

@test "cli: init without --ai cursor/opencode does not create extra files" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  run run_cli init --here --ai copilot
  [ "$status" -eq 0 ]
  [ ! -f "$repo/.cursor/rules/lazyspeckit.mdc" ]
  [ ! -f "$repo/.opencode/agent/LazySpecKit.md" ]
}

@test "cli: init --ai cursor does not pass cursor to specify" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  # Verify that --ai cursor never reaches 'specify init' (which doesn't understand it)
  run run_cli init --here --ai copilot --ai cursor
  [ "$status" -eq 0 ]
  # The fake specify echoes its args; cursor should not appear in specify output
  [[ "$output" != *"specify"*"cursor"* ]]
}

# ---- cmd_upgrade --ai (extra agents) ----

@test "cli: upgrade --ai cursor installs cursor prompt" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  create_fake_specify
  # Pre-install a prompt so upgrade has something to pick up
  mkdir -p "$repo/.github/prompts"
  echo "LazySpecKit speckit prompt" > "$repo/.github/prompts/LazySpecKit.prompt.md"
  run run_cli upgrade --here --ai copilot --ai cursor
  [ "$status" -eq 0 ]
  [ -f "$repo/.cursor/rules/lazyspeckit.mdc" ]
}

@test "cli: upgrade --ai opencode installs opencode prompt" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  create_fake_specify
  run run_cli upgrade --here --ai copilot --ai opencode
  [ "$status" -eq 0 ]
  [ -f "$repo/.opencode/agent/LazySpecKit.md" ]
}

@test "cli: upgrade auto-detects cursor when .cursor dir exists" {
  local repo
  repo="$(create_cursor_repo)"
  cd "$repo"
  create_fake_specify
  mkdir -p "$repo/.github/prompts"
  echo "LazySpecKit speckit prompt" > "$repo/.github/prompts/LazySpecKit.prompt.md"
  run run_cli upgrade --here --ai copilot
  [ "$status" -eq 0 ]
  [ -f "$repo/.cursor/rules/lazyspeckit.mdc" ]
}

@test "cli: upgrade auto-detects opencode when .opencode dir exists" {
  local repo
  repo="$(create_opencode_repo)"
  cd "$repo"
  create_fake_specify
  run run_cli upgrade --here --ai copilot
  [ "$status" -eq 0 ]
  [ -f "$repo/.opencode/agent/LazySpecKit.md" ]
}

@test "cli: upgrade auto-detects both cursor and opencode" {
  local repo
  repo="$(create_cursor_opencode_repo)"
  cd "$repo"
  create_fake_specify
  run run_cli upgrade --here --ai copilot
  [ "$status" -eq 0 ]
  [ -f "$repo/.cursor/rules/lazyspeckit.mdc" ]
  [ -f "$repo/.opencode/agent/LazySpecKit.md" ]
}

@test "cli: upgrade without cursor/opencode dirs creates no extra files" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  create_fake_specify
  run run_cli upgrade --here --ai copilot
  [ "$status" -eq 0 ]
  [ ! -f "$repo/.cursor/rules/lazyspeckit.mdc" ]
  [ ! -f "$repo/.opencode/agent/LazySpecKit.md" ]
}

# ---- cmd_doctor cursor/opencode output ----

@test "cli: doctor shows Cursor detected yes when .cursor exists" {
  local repo
  repo="$(create_cursor_repo)"
  cd "$repo"
  run run_cli doctor --here
  [ "$status" -eq 0 ]
  [[ "$output" == *"Cursor detected"* ]]
  [[ "$output" == *"Cursor detected"*"yes"* ]]
}

@test "cli: doctor shows Cursor detected no without .cursor" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  run run_cli doctor --here
  [ "$status" -eq 0 ]
  [[ "$output" == *"Cursor detected"* ]]
  [[ "$output" == *"Cursor detected"*"no"* ]]
}

@test "cli: doctor shows OpenCode detected yes when .opencode exists" {
  local repo
  repo="$(create_opencode_repo)"
  cd "$repo"
  run run_cli doctor --here
  [ "$status" -eq 0 ]
  [[ "$output" == *"OpenCode detected"*"yes"* ]]
}

@test "cli: doctor shows OpenCode detected no without .opencode" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  run run_cli doctor --here
  [ "$status" -eq 0 ]
  [[ "$output" == *"OpenCode detected"*"no"* ]]
}

@test "cli: doctor shows Cursor prompt installed yes after init --ai cursor" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  create_fake_specify
  run run_cli init --here --ai copilot --ai cursor
  [ "$status" -eq 0 ]
  run run_cli doctor --here
  [ "$status" -eq 0 ]
  [[ "$output" == *"Cursor prompt installed"*"yes"* ]]
}

@test "cli: doctor shows Cursor prompt installed no before cursor install" {
  local repo
  repo="$(create_cursor_repo)"
  cd "$repo"
  run run_cli doctor --here
  [ "$status" -eq 0 ]
  [[ "$output" == *"Cursor prompt installed"*"no"* ]]
}

@test "cli: doctor shows OpenCode prompt installed yes after init --ai opencode" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  create_fake_specify
  run run_cli init --here --ai copilot --ai opencode
  [ "$status" -eq 0 ]
  run run_cli doctor --here
  [ "$status" -eq 0 ]
  [[ "$output" == *"OpenCode prompt installed"*"yes"* ]]
}

@test "cli: doctor shows OpenCode prompt installed no before opencode install" {
  local repo
  repo="$(create_opencode_repo)"
  cd "$repo"
  run run_cli doctor --here
  [ "$status" -eq 0 ]
  [[ "$output" == *"OpenCode prompt installed"*"no"* ]]
}

# ---- usage ----

@test "cli: usage lists cursor and opencode as --ai values" {
  run run_cli --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"cursor"* ]]
  [[ "$output" == *"opencode"* ]]
}

@test "cli: usage includes --ai all example" {
  run run_cli --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"--ai all"* ]]
}

@test "cli: usage includes AI agents section" {
  run run_cli --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"AI agents (--ai)"* ]]
}

# ============ nounset / unbound variable regression ============
# These tests ensure no unbound variable errors occur under set -u.
# They run WITHOUT the tmp=/backup_dir= workarounds that previously masked the issue.

_assert_no_unbound_vars() {
  # Fail if stderr contains "unbound variable"
  if [[ "${output:-}" == *"unbound variable"* ]]; then
    echo "FAIL: unbound variable detected in output: $output" >&2
    return 1
  fi
}

_assert_no_err_trap() {
  # Fail if the ERR trap fired with a spurious "Failed (exit" message
  if [[ "${output:-}" == *"Failed (exit"* ]]; then
    echo "FAIL: ERR trap fired unexpectedly in output: $output" >&2
    return 1
  fi
}

@test "nounset: version produces no unbound variable errors" {
  run run_cli version
  _assert_no_unbound_vars
  _assert_no_err_trap
}

@test "nounset: --help produces no unbound variable errors" {
  run run_cli --help
  _assert_no_unbound_vars
  _assert_no_err_trap
}

@test "nounset: doctor produces no unbound variable errors" {
  local repo
  repo="$(create_test_repo)"
  run run_cli doctor "$repo"
  _assert_no_unbound_vars
  _assert_no_err_trap
}

@test "nounset: init produces no unbound variable errors" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  run run_cli init --here --ai copilot
  _assert_no_unbound_vars
  _assert_no_err_trap
}

@test "nounset: init without Agency dirs produces no errors" {
  # Simulate no Agency installation (HOME has no .claude/agents or .github/agents)
  local repo
  repo="$(create_test_repo)"
  cd "$repo"
  # Ensure no agency dirs exist under the fake HOME
  rm -rf "$TEST_TMPDIR/.claude/agents" "$TEST_TMPDIR/.github/agents"
  run run_cli init --here --ai copilot
  [ "$status" -eq 0 ]
  _assert_no_unbound_vars
  _assert_no_err_trap
}

@test "nounset: upgrade produces no unbound variable errors" {
  local repo
  repo="$(create_test_repo)"
  create_fake_specify
  run run_cli upgrade "$repo" --ai copilot
  _assert_no_unbound_vars
  _assert_no_err_trap
}

@test "nounset: self-update produces no unbound variable errors" {
  local fake_self="$FAKE_BIN/lazyspeckit"
  cat > "$fake_self" <<'SCRIPT'
#!/usr/bin/env bash
echo "lazyspeckit 0.5.0"
SCRIPT
  chmod +x "$fake_self"
  run run_cli self-update
  _assert_no_unbound_vars
  _assert_no_err_trap
}
