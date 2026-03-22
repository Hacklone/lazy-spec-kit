#!/usr/bin/env bash
# test_helper.bash — shared setup for all BATS tests.

# Root of the repo
export REPO_ROOT
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Create a fresh temp dir for each test
setup() {
  export TEST_TMPDIR
  TEST_TMPDIR="$(mktemp -d)"

  # Provide a fake curl/wget that always succeeds
  export FAKE_BIN="$TEST_TMPDIR/fake_bin"
  mkdir -p "$FAKE_BIN"

  # Default fake curl — writes a recognizable lazyspeckit marker file
  create_fake_curl "lazyspeckit speckit LazySpecKit"

  # Ensure fake_bin is first on PATH
  export ORIGINAL_PATH="$PATH"
  export PATH="$FAKE_BIN:$PATH"

  # Disable colors in all tests
  export NO_COLOR=1
  export DEBUG=0
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# ---- helpers ----

# Create a fake curl that writes given content to the output file
create_fake_curl() {
  local content="${1:-lazyspeckit speckit LazySpecKit}"
  cat > "$FAKE_BIN/curl" <<SCRIPT
#!/usr/bin/env bash
# Fake curl: parse -o <outfile> and write content
outfile=""
while [[ \$# -gt 0 ]]; do
  case "\$1" in
    -o) outfile="\$2"; shift 2 ;;
    *) shift ;;
  esac
done
if [[ -n "\$outfile" ]]; then
  echo "$content" > "\$outfile"
fi
exit 0
SCRIPT
  chmod +x "$FAKE_BIN/curl"
}

# Create a fake curl that fails
create_failing_curl() {
  cat > "$FAKE_BIN/curl" <<'SCRIPT'
#!/usr/bin/env bash
exit 1
SCRIPT
  chmod +x "$FAKE_BIN/curl"
}

# Create a fake wget that writes given content
create_fake_wget() {
  local content="${1:-lazyspeckit speckit LazySpecKit}"
  cat > "$FAKE_BIN/wget" <<SCRIPT
#!/usr/bin/env bash
# Fake wget: parse -qO <outfile> and write content
outfile=""
while [[ \$# -gt 0 ]]; do
  case "\$1" in
    -qO) outfile="\$2"; shift 2 ;;
    *) shift ;;
  esac
done
if [[ -n "\$outfile" ]]; then
  echo "$content" > "\$outfile"
fi
exit 0
SCRIPT
  chmod +x "$FAKE_BIN/wget"
}

# Remove curl from fake bin so it's "not found"
remove_fake_curl() {
  rm -f "$FAKE_BIN/curl"
}

# Remove wget from fake bin so it's "not found"
remove_fake_wget() {
  rm -f "$FAKE_BIN/wget"
}

# Create a fake install command
create_fake_install() {
  cat > "$FAKE_BIN/install" <<'SCRIPT'
#!/usr/bin/env bash
# Fake install: parse -m <mode> <src> <dst>
mode=""
src=""
dst=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -m) mode="$2"; shift 2 ;;
    *)
      if [[ -z "$src" ]]; then src="$1"
      elif [[ -z "$dst" ]]; then dst="$1"
      fi
      shift ;;
  esac
done
if [[ -n "$src" && -n "$dst" ]]; then
  mkdir -p "$(dirname "$dst")"
  cp -f "$src" "$dst"
  chmod "$mode" "$dst" 2>/dev/null || true
fi
SCRIPT
  chmod +x "$FAKE_BIN/install"
}

# Create a fake uv/uvx that succeeds
create_fake_uv() {
  cat > "$FAKE_BIN/uv" <<'SCRIPT'
#!/usr/bin/env bash
case "$1" in
  tool)
    case "$2" in
      install) echo "Installed specify-cli" ;;
      --help)  echo "uv tool help" ;;
      *)       echo "uv tool $*" ;;
    esac
    ;;
  self)
    echo "uv self $*"
    ;;
  --version)
    echo "uv 0.6.0"
    ;;
  *)
    echo "uv $*"
    ;;
esac
exit 0
SCRIPT
  chmod +x "$FAKE_BIN/uv"

  cat > "$FAKE_BIN/uvx" <<'SCRIPT'
#!/usr/bin/env bash
echo "uvx $*"
exit 0
SCRIPT
  chmod +x "$FAKE_BIN/uvx"
}

# Create a fake specify command
create_fake_specify() {
  cat > "$FAKE_BIN/specify" <<'SCRIPT'
#!/usr/bin/env bash
# Fake specify: on "init --here", create .specify dir
for arg in "$@"; do
  if [[ "$arg" == "--here" ]]; then
    mkdir -p .specify
  fi
done
echo "specify $*"
exit 0
SCRIPT
  chmod +x "$FAKE_BIN/specify"
}

# Create a minimal repo structure for testing
create_test_repo() {
  local dir="${1:-$TEST_TMPDIR/repo}"
  mkdir -p "$dir/.specify" "$dir/.vscode" "$dir/.github/prompts" "$dir/.claude/commands"
  echo "$dir"
}

# Create a test repo with only .claude (no .vscode/.github)
create_claude_only_repo() {
  local dir="${1:-$TEST_TMPDIR/repo}"
  mkdir -p "$dir/.specify" "$dir/.claude/commands"
  echo "$dir"
}

# Create a test repo with only .vscode/.github (no .claude)
create_vscode_only_repo() {
  local dir="${1:-$TEST_TMPDIR/repo}"
  mkdir -p "$dir/.specify" "$dir/.vscode" "$dir/.github/prompts"
  echo "$dir"
}

# Create a bare repo (no .specify, no AI dirs)
create_bare_repo() {
  local dir="${1:-$TEST_TMPDIR/repo}"
  mkdir -p "$dir"
  echo "$dir"
}

# Create a test repo with .cursor/ dir (simulating a Cursor project)
create_cursor_repo() {
  local dir="${1:-$TEST_TMPDIR/repo}"
  mkdir -p "$dir/.specify" "$dir/.cursor"
  echo "$dir"
}

# Create a test repo with .opencode/ dir (simulating an OpenCode project)
create_opencode_repo() {
  local dir="${1:-$TEST_TMPDIR/repo}"
  mkdir -p "$dir/.specify" "$dir/.opencode"
  echo "$dir"
}

# Create a test repo with both .cursor/ and .opencode/
create_cursor_opencode_repo() {
  local dir="${1:-$TEST_TMPDIR/repo}"
  mkdir -p "$dir/.specify" "$dir/.cursor" "$dir/.opencode"
  echo "$dir"
}

# Create a test repo with .codex/ dir (simulating a Codex project)
create_codex_repo() {
  local dir="${1:-$TEST_TMPDIR/repo}"
  mkdir -p "$dir/.specify" "$dir/.codex"
  echo "$dir"
}

# Create a test repo with .cursor/, .opencode/, and .codex/
create_all_extra_repo() {
  local dir="${1:-$TEST_TMPDIR/repo}"
  mkdir -p "$dir/.specify" "$dir/.cursor" "$dir/.opencode" "$dir/.codex"
  echo "$dir"
}
