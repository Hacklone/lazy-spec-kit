#!/usr/bin/env bats
# Tests for architecture commands in cli/lazyspeckit

load test_helper

CLI="$REPO_ROOT/cli/lazyspeckit"

# ---- Smart fake curl that handles architecture template URLs ----
create_arch_smart_curl() {
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
  if [[ "$url" == *templates/architecture/decisions/* ]]; then
    printf '%s\n' "# ADR-001: Example" "" "## Status" "Accepted" "" "## Context" "Example ADR content" > "$outfile"
  elif [[ "$url" == *templates/architecture/summary.md* ]]; then
    printf '%s\n' "# Architecture Summary" "" "## System Purpose" "Describe system purpose" > "$outfile"
  elif [[ "$url" == *templates/architecture/principles.md* ]]; then
    printf '%s\n' "# Architecture Principles" "" "## Service Boundaries" "Rules here" > "$outfile"
  elif [[ "$url" == *templates/architecture/index.md* ]]; then
    printf '%s\n' "# Architecture Context Index" "" "## Services" "Keywords and docs" > "$outfile"
  elif [[ "$url" == *templates/architecture/components/example/overview.md* ]]; then
    printf '%s\n' "# Component: Example" "" "## Purpose" "Example component" > "$outfile"
  elif [[ "$url" == *templates/architecture/components/example/modules.md* ]]; then
    printf '%s\n' "# Modules: Example" "" "## Module: Core Logic" "Main logic" > "$outfile"
  elif [[ "$url" == *templates/architecture/components/example/api.md* ]]; then
    printf '%s\n' "# API: Example" "" "## Endpoints / Interfaces" "API docs" > "$outfile"
  elif [[ "$url" == *templates/architecture/components/example/ui.md* ]]; then
    printf '%s\n' "# UI: Example" "" "## Screen: Dashboard" "Main screen" > "$outfile"
  elif [[ "$url" == *setup.sh* ]]; then
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
  elif [[ "$url" == *reviewers/*.md* ]]; then
    local fname
    fname="$(echo "$url" | sed 's/.*reviewers\///' | sed 's/?.*//')"
    printf '%s\n' "---" "name: Reviewer $fname" "perspective: test perspective" "---" "Review instructions for $fname" > "$outfile"
  elif [[ "$url" == *lazyspeckit* ]]; then
    printf '%s\n' \
      '#!/usr/bin/env bash' \
      'VERSION="0.8.4"' \
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
  create_arch_smart_curl
  export ORIGINAL_PATH="$PATH"
  export PATH="$FAKE_BIN:$PATH"
  export NO_COLOR=1
  export DEBUG=0
  create_fake_uv
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# ============ architecture:init ============

@test "architecture:init creates directory structure" {
  local repo
  repo="$(create_test_repo)"

  run run_cli architecture:init "$repo"
  [ "$status" -eq 0 ]
  [ -d "$repo/.docs/architecture" ]
  [ -d "$repo/.docs/architecture/components" ]
  [ -d "$repo/.docs/architecture/integrations" ]
  [ -d "$repo/.docs/architecture/decisions" ]
}

@test "architecture:init downloads template files" {
  local repo
  repo="$(create_test_repo)"

  run run_cli architecture:init "$repo"
  [ "$status" -eq 0 ]
  [ -f "$repo/.docs/architecture/index.md" ]
  [ -f "$repo/.docs/architecture/summary.md" ]
  [ -f "$repo/.docs/architecture/principles.md" ]
  [ -f "$repo/.docs/architecture/components/example/overview.md" ]
  [ -f "$repo/.docs/architecture/components/example/modules.md" ]
  [ -f "$repo/.docs/architecture/components/example/api.md" ]
  [ -f "$repo/.docs/architecture/components/example/ui.md" ]
}

@test "architecture:init downloads ADR example" {
  local repo
  repo="$(create_test_repo)"

  run run_cli architecture:init "$repo"
  [ "$status" -eq 0 ]
  [ -f "$repo/.docs/architecture/decisions/ADR-001-example.md" ]
}

@test "architecture:init does not overwrite existing files" {
  local repo
  repo="$(create_test_repo)"
  mkdir -p "$repo/.docs/architecture"
  echo "custom content" > "$repo/.docs/architecture/summary.md"

  run run_cli architecture:init "$repo"
  [ "$status" -eq 0 ]
  [[ "$(cat "$repo/.docs/architecture/summary.md")" == "custom content" ]]
}

@test "architecture:init reports creation count" {
  local repo
  repo="$(create_test_repo)"

  run run_cli architecture:init "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Architecture docs:"* ]]
  [[ "$output" == *"created"* ]]
}

@test "architecture:init reports existing count when files already present" {
  local repo
  repo="$(create_test_repo)"
  mkdir -p "$repo/.docs/architecture/decisions"
  echo "existing" > "$repo/.docs/architecture/summary.md"
  echo "existing" > "$repo/.docs/architecture/principles.md"

  run run_cli architecture:init "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"existing (kept)"* ]]
}

@test "architecture:init runs check after init" {
  local repo
  repo="$(create_test_repo)"

  run run_cli architecture:init "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Checking architecture documentation"* ]]
}

@test "architecture:init fails if target does not exist" {
  run run_cli architecture:init "/nonexistent/path"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Target folder does not exist"* ]]
}

@test "architecture:init with --here uses cwd" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"

  run run_cli architecture:init --here
  [ "$status" -eq 0 ]
  [ -d "$repo/.docs/architecture" ]
}

# ============ architecture:check ============

@test "architecture:check reports status" {
  local repo
  repo="$(create_test_repo)"
  mkdir -p "$repo/.docs/architecture/components" "$repo/.docs/architecture/integrations" \
           "$repo/.docs/architecture/decisions"
  echo "summary" > "$repo/.docs/architecture/summary.md"

  run run_cli architecture:check "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Architecture check complete"* ]]
}

@test "architecture:check counts components" {
  local repo
  repo="$(create_test_repo)"
  mkdir -p "$repo/.docs/architecture/components/auth" "$repo/.docs/architecture/components/billing"
  echo "doc" > "$repo/.docs/architecture/components/auth/overview.md"
  echo "doc" > "$repo/.docs/architecture/components/billing/overview.md"
  touch "$repo/.docs/architecture/summary.md"

  run run_cli architecture:check "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Components: 2 documented"* ]]
}

@test "architecture:check counts nested components" {
  local repo
  repo="$(create_test_repo)"
  mkdir -p "$repo/.docs/architecture/components/payments/payment-api" "$repo/.docs/architecture/components/payments/payment-ui"
  echo "doc" > "$repo/.docs/architecture/components/payments/payment-api/overview.md"
  echo "doc" > "$repo/.docs/architecture/components/payments/payment-ui/overview.md"
  touch "$repo/.docs/architecture/summary.md"

  run run_cli architecture:check "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Components: 2 documented"* ]]
}

@test "architecture:check counts integrations" {
  local repo
  repo="$(create_test_repo)"
  mkdir -p "$repo/.docs/architecture/integrations"
  echo "stripe" > "$repo/.docs/architecture/integrations/stripe.md"
  echo "sendgrid" > "$repo/.docs/architecture/integrations/sendgrid.md"
  touch "$repo/.docs/architecture/summary.md"

  run run_cli architecture:check "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Integrations: 2 documented"* ]]
}

@test "architecture:check counts decisions excluding example" {
  local repo
  repo="$(create_test_repo)"
  mkdir -p "$repo/.docs/architecture/decisions"
  echo "example" > "$repo/.docs/architecture/decisions/ADR-001-example.md"
  echo "real" > "$repo/.docs/architecture/decisions/ADR-002-auth-pattern.md"
  touch "$repo/.docs/architecture/summary.md"

  run run_cli architecture:check "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Decisions: 1 recorded"* ]]
}

@test "architecture:check warns about missing core files" {
  local repo
  repo="$(create_test_repo)"
  mkdir -p "$repo/.docs/architecture"
  # Only create summary.md, missing others
  echo "summary" > "$repo/.docs/architecture/summary.md"

  run run_cli architecture:check "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Missing core files"* ]]
}

@test "architecture:check suggests undocumented project dirs" {
  local repo
  repo="$(create_test_repo)"
  mkdir -p "$repo/.docs/architecture/components"
  mkdir -p "$repo/backend" "$repo/frontend"
  touch "$repo/.docs/architecture/summary.md"

  run run_cli architecture:check "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Suggested"* ]]
  [[ "$output" == *"backend"* ]]
  [[ "$output" == *"frontend"* ]]
}

@test "architecture:check skips hidden and vendor dirs in suggestions" {
  local repo
  repo="$(create_test_repo)"
  mkdir -p "$repo/.docs/architecture/components"
  mkdir -p "$repo/.hidden" "$repo/node_modules" "$repo/vendor" "$repo/dist"
  mkdir -p "$repo/src"
  touch "$repo/.docs/architecture/summary.md"

  run run_cli architecture:check "$repo"
  [ "$status" -eq 0 ]
  # Should not suggest hidden/vendor dirs
  [[ "$output" != *"node_modules"* ]]
  [[ "$output" != *"vendor"* ]]
  [[ "$output" != *"dist"* ]]
  # Should suggest real project dirs
  [[ "$output" == *"src"* ]]
}

@test "architecture:check warns if no architecture docs found" {
  local repo
  repo="$(create_test_repo)"

  run run_cli architecture:check "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No architecture docs found"* ]]
}

@test "architecture:check does not suggest already-documented dirs" {
  local repo
  repo="$(create_test_repo)"
  mkdir -p "$repo/.docs/architecture/components/backend"
  echo "doc" > "$repo/.docs/architecture/components/backend/overview.md"
  mkdir -p "$repo/backend" "$repo/frontend"
  touch "$repo/.docs/architecture/summary.md"

  run run_cli architecture:check "$repo"
  [ "$status" -eq 0 ]
  # Should not suggest backend (already documented)
  # Should suggest frontend
  [[ "$output" == *"frontend"* ]]
}

@test "architecture:check does not suggest dirs documented under domain group" {
  local repo
  repo="$(create_test_repo)"
  mkdir -p "$repo/.docs/architecture/components/payments/payment-api"
  echo "doc" > "$repo/.docs/architecture/components/payments/payment-api/overview.md"
  mkdir -p "$repo/payments" "$repo/identity"
  touch "$repo/.docs/architecture/summary.md"

  run run_cli architecture:check "$repo"
  [ "$status" -eq 0 ]
  # payments/ should not be suggested (has a documented sub-component)
  [[ "$output" == *"identity"* ]]
}

@test "architecture:check fails if target does not exist" {
  run run_cli architecture:check "/nonexistent/path"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Target folder does not exist"* ]]
}

@test "architecture:sync alias works (backward compat)" {
  local repo
  repo="$(create_test_repo)"
  mkdir -p "$repo/.docs/architecture/components" "$repo/.docs/architecture/integrations" \
           "$repo/.docs/architecture/decisions"
  echo "summary" > "$repo/.docs/architecture/summary.md"

  run run_cli architecture:sync "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Architecture check complete"* ]]
}

# ============ architecture:show ============

@test "architecture:show displays core file status" {
  local repo
  repo="$(create_test_repo)"
  mkdir -p "$repo/.docs/architecture"
  echo "summary" > "$repo/.docs/architecture/summary.md"
  echo "index" > "$repo/.docs/architecture/index.md"

  run run_cli architecture:show "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Core files:"* ]]
  [[ "$output" == *"summary.md"* ]]
  [[ "$output" == *"index.md"* ]]
}

@test "architecture:show marks missing core files" {
  local repo
  repo="$(create_test_repo)"
  mkdir -p "$repo/.docs/architecture"
  echo "summary" > "$repo/.docs/architecture/summary.md"

  run run_cli architecture:show "$repo"
  [ "$status" -eq 0 ]
  # principles.md should be marked as missing
  [[ "$output" == *"principles.md"* ]]
  [[ "$output" == *"missing"* ]]
}

@test "architecture:show lists components" {
  local repo
  repo="$(create_test_repo)"
  mkdir -p "$repo/.docs/architecture/components/auth"
  echo "doc" > "$repo/.docs/architecture/components/auth/overview.md"
  echo "doc" > "$repo/.docs/architecture/components/auth/api.md"

  run run_cli architecture:show "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Components:"* ]]
  [[ "$output" == *"auth"* ]]
  [[ "$output" == *"2 docs"* ]]
}

@test "architecture:show lists nested components" {
  local repo
  repo="$(create_test_repo)"
  mkdir -p "$repo/.docs/architecture/components/payments/payment-api"
  echo "doc" > "$repo/.docs/architecture/components/payments/payment-api/overview.md"
  echo "doc" > "$repo/.docs/architecture/components/payments/payment-api/api.md"

  run run_cli architecture:show "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"payments/payment-api"* ]]
  [[ "$output" == *"2 docs"* ]]
}

@test "architecture:show lists integrations" {
  local repo
  repo="$(create_test_repo)"
  mkdir -p "$repo/.docs/architecture/integrations"
  echo "doc" > "$repo/.docs/architecture/integrations/stripe.md"

  run run_cli architecture:show "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Integrations:"* ]]
  [[ "$output" == *"stripe"* ]]
}

@test "architecture:show lists decisions excluding example" {
  local repo
  repo="$(create_test_repo)"
  mkdir -p "$repo/.docs/architecture/decisions"
  echo "example" > "$repo/.docs/architecture/decisions/ADR-001-example.md"
  echo "real" > "$repo/.docs/architecture/decisions/ADR-002-auth-pattern.md"

  run run_cli architecture:show "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Decisions:"* ]]
  [[ "$output" == *"ADR-002-auth-pattern"* ]]
  [[ "$output" != *"ADR-001-example"* ]]
}

@test "architecture:show shows (none) when empty" {
  local repo
  repo="$(create_test_repo)"
  mkdir -p "$repo/.docs/architecture/components" "$repo/.docs/architecture/integrations" \
           "$repo/.docs/architecture/decisions"

  run run_cli architecture:show "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"(none)"* ]]
}

@test "architecture:show warns if no architecture docs" {
  local repo
  repo="$(create_test_repo)"

  run run_cli architecture:show "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No architecture docs found"* ]]
}

@test "architecture:show fails if target does not exist" {
  run run_cli architecture:show "/nonexistent/path"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Target folder does not exist"* ]]
}

# ============ --no-architecture flag ============

@test "init --no-architecture skips architecture docs" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"

  run run_cli init --here --no-architecture --ai copilot
  [ "$status" -eq 0 ]
  [ ! -d "$repo/.docs/architecture" ]
}

@test "init without --no-architecture creates architecture docs" {
  local repo
  repo="$(create_test_repo)"
  cd "$repo"

  run run_cli init --here --ai copilot
  [ "$status" -eq 0 ]
  [ -d "$repo/.docs/architecture" ]
}

# ============ doctor integration ============

@test "doctor shows architecture docs status when present" {
  local repo
  repo="$(create_test_repo)"
  mkdir -p "$repo/.docs/architecture"

  run run_cli doctor "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Architecture docs:"* ]]
  [[ "$output" == *"yes"* ]]
}

@test "doctor shows architecture docs status when absent" {
  local repo
  repo="$(create_test_repo)"

  run run_cli doctor "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Architecture docs:"* ]]
  [[ "$output" == *"no"* ]]
}

# ============ upgrade integration ============

@test "upgrade runs architecture check when docs exist" {
  local repo
  repo="$(create_test_repo)"
  create_fake_specify
  mkdir -p "$repo/.docs/architecture"
  touch "$repo/.docs/architecture/summary.md"

  run run_cli upgrade "$repo" --ai copilot
  [ "$status" -eq 0 ]
  [[ "$output" == *"Checking architecture documentation"* ]]
}

@test "upgrade skips architecture check when no docs" {
  local repo
  repo="$(create_test_repo)"
  create_fake_specify

  run run_cli upgrade "$repo" --ai copilot
  [ "$status" -eq 0 ]
  [[ "$output" != *"Checking architecture documentation"* ]]
}

# ============ usage ============

@test "usage includes architecture commands" {
  run run_cli --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"architecture:init"* ]]
  [[ "$output" == *"architecture:check"* ]]
  [[ "$output" == *"architecture:show"* ]]
}

@test "usage includes --no-architecture flag" {
  run run_cli --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"--no-architecture"* ]]
}
