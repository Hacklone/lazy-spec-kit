#!/usr/bin/env bash
set -Eeuo pipefail

# scripts/setup.sh — installs/refreshes LazySpecKit prompt files into a target repo folder.
#
# Usage:
#   ./scripts/setup.sh [--here | <path>]
#
# Env:
#   LAZYSPECKIT_REF=main|v0.5.0|<sha>   pin downloads (default: main)
#   DEBUG=1                             enable trace
#   NO_COLOR=1                          disable colors

OWNER_REPO="Hacklone/lazy-spec-kit"
REF="${LAZYSPECKIT_REF:-main}"
PROMPT_REPO_PATH="prompts/LazySpecKit.prompt.md"

# Default reviewer skill files (repo paths → installed to .lazyspeckit/reviewers/)
REVIEWER_FILES=(
  "reviewers/architecture.md"
  "reviewers/code-quality.md"
  "reviewers/spec-compliance.md"
  "reviewers/test.md"
)

DEBUG="${DEBUG:-0}"

# ---------- logging ----------
COLOR_ON="true"
if [[ ! -t 1 || -n "${NO_COLOR:-}" ]]; then COLOR_ON="false"; fi

c() {
  local code="${1:-0}"; shift || true
  if [[ "$COLOR_ON" == "true" ]]; then
    printf "\033[%sm%s\033[0m" "$code" "$*"
  else
    printf "%s" "$*"
  fi
}
info() { printf "%s %s\n" "$(c "36" "==>")" "$*"; }
ok()   { printf "%s %s\n" "$(c "32" "✅")" "$*"; }
err()  { printf "%s %s\n" "$(c "31" "✖")" "$*" >&2; }

die() { err "$*"; exit 1; }
have() { command -v "${1:-__missing__}" >/dev/null 2>&1; }

on_err() {
  local ec="$?"
  local line="${BASH_LINENO[0]:-unknown}"
  local cmd="${BASH_COMMAND:-unknown}"
  err "Failed (exit $ec) at line ${line}: ${cmd}"
  exit "$ec"
}
trap on_err ERR

[[ "$DEBUG" == "1" ]] && set -x

fetch() {
  local url="${1:-}"
  local out="${2:-}"
  [[ -n "$url" && -n "$out" ]] || die "fetch: missing url/out"
  if have curl; then
    curl -fsSL --retry 3 --retry-delay 1 --connect-timeout 10 --max-time 120 \
      -H "Cache-Control: no-cache" -H "Pragma: no-cache" "$url" -o "$out"
  elif have wget; then
    wget -qO "$out" --no-cache "$url"
  else
    die "Missing curl or wget."
  fi
}

raw_url() {
  local path="${1:-$PROMPT_REPO_PATH}"
  printf 'https://raw.githubusercontent.com/%s/%s/%s' "$OWNER_REPO" "$REF" "$path"
}

cache_bust() {
  local url="${1:-}"
  [[ -n "$url" ]] || die "cache_bust: missing url"
  printf "%s?cb=%s" "$url" "$(date +%s)"
}

infer_target() {
  local arg="${1:-}"
  if [[ "$arg" == "--here" || -z "$arg" ]]; then
    pwd
  else
    if [[ -d "$arg" ]]; then (cd "$arg" && pwd); else echo "$(pwd)/$arg"; fi
  fi
}

install_file() {
  # install_file <src> <dst> <mode>
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

# ---------- reviewer hash stamping ----------
HASH_PREFIX="<!-- lazyspeckit-hash:"
HASH_SUFFIX=" -->"

content_hash() {
  # Compute SHA-256 of a file's content (excluding any existing hash stamp line).
  local file="${1:-}"
  [[ -n "$file" && -f "$file" ]] || { echo ""; return 1; }
  grep -v "^${HASH_PREFIX}" "$file" | shasum -a 256 | cut -d' ' -f1
}

stamp_file() {
  # Append a hash stamp to a file (removes any existing stamp first).
  local file="${1:-}"
  [[ -n "$file" && -f "$file" ]] || return 1
  local hash
  hash="$(content_hash "$file")"
  # Remove old stamp if present, then append new one
  local tmp_stamp
  tmp_stamp="$(mktemp)"
  grep -v "^${HASH_PREFIX}" "$file" > "$tmp_stamp" || true
  printf '%s%s%s\n' "$HASH_PREFIX" "$hash" "$HASH_SUFFIX" >> "$tmp_stamp"
  mv -f "$tmp_stamp" "$file"
}

stored_hash() {
  # Extract the hash value from a file's stamp line, or empty string if none.
  local file="${1:-}"
  [[ -n "$file" && -f "$file" ]] || { echo ""; return 0; }
  local line
  line="$(grep "^${HASH_PREFIX}" "$file" 2>/dev/null | tail -n1)" || true
  if [[ -z "$line" ]]; then echo ""; return 0; fi
  echo "$line" | sed "s/^${HASH_PREFIX}//" | sed "s/${HASH_SUFFIX}$//" | tr -d ' '
}

is_default_unmodified() {
  # Returns 0 if the file is an unmodified default (stamp present + hash matches).
  local file="${1:-}"
  [[ -n "$file" && -f "$file" ]] || return 1
  local stored current
  stored="$(stored_hash "$file")"
  [[ -n "$stored" ]] || return 1   # no stamp → not a default or user removed it
  current="$(content_hash "$file")"
  [[ "$stored" == "$current" ]]
}

main() {
  local target
  target="$(infer_target "${1:-}")"
  [[ -d "$target" ]] || die "Target folder does not exist: $target"

  info "Installing LazySpecKit prompts into: $target (ref: $REF)"

  local tmp
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' RETURN

  local url
  url="$(cache_bust "$(raw_url)")"
  fetch "$url" "$tmp"

  [[ -s "$tmp" ]] || die "Downloaded prompt is empty."
  grep -qi "LazySpecKit" "$tmp" || die "Downloaded prompt doesn't look valid (missing LazySpecKit)."
  grep -qi "speckit" "$tmp" || die "Downloaded prompt doesn't look valid (missing speckit)."

  install_file "$tmp" "$target/.github/prompts/LazySpecKit.prompt.md" "0644"
  install_file "$tmp" "$target/.claude/commands/LazySpecKit.md" "0644"

  ok "Prompts installed:"
  echo "  - $target/.github/prompts/LazySpecKit.prompt.md"
  echo "  - $target/.claude/commands/LazySpecKit.md"

  # Install default reviewer skill files
  # - Missing       → install + stamp
  # - Unmodified    → update  + stamp  (hash matches → safe to overwrite)
  # - User-modified → skip             (hash mismatch or no stamp → preserve)
  info "Installing default reviewer skill files..."
  local reviewer_path reviewer_tmp reviewer_url reviewer_name
  local reviewers_installed=0 reviewers_updated=0 reviewers_skipped=0
  for reviewer_path in "${REVIEWER_FILES[@]}"; do
    reviewer_name="$(basename "$reviewer_path")"
    local dst="$target/.lazyspeckit/reviewers/$reviewer_name"
    if [[ -f "$dst" ]]; then
      if is_default_unmodified "$dst"; then
        # Unmodified default → download new version and overwrite
        reviewer_tmp="$(mktemp)"
        reviewer_url="$(cache_bust "$(raw_url "$reviewer_path")")"
        if fetch "$reviewer_url" "$reviewer_tmp" 2>/dev/null && [[ -s "$reviewer_tmp" ]]; then
          install_file "$reviewer_tmp" "$dst" "0644"
          stamp_file "$dst"
          reviewers_updated=$((reviewers_updated + 1))
        else
          err "Failed to download reviewer: $reviewer_name (skipping)"
        fi
        rm -f "$reviewer_tmp"
      else
        # User-modified or no stamp → preserve
        reviewers_skipped=$((reviewers_skipped + 1))
      fi
      continue
    fi
    # Missing → install fresh
    reviewer_tmp="$(mktemp)"
    reviewer_url="$(cache_bust "$(raw_url "$reviewer_path")")"
    if fetch "$reviewer_url" "$reviewer_tmp" 2>/dev/null && [[ -s "$reviewer_tmp" ]]; then
      install_file "$reviewer_tmp" "$dst" "0644"
      stamp_file "$dst"
      reviewers_installed=$((reviewers_installed + 1))
    else
      err "Failed to download reviewer: $reviewer_name (skipping)"
    fi
    rm -f "$reviewer_tmp"
  done

  local summary=""
  [[ "$reviewers_installed" -gt 0 ]] && summary="${reviewers_installed} installed"
  [[ "$reviewers_updated" -gt 0 ]]  && summary="${summary:+$summary, }${reviewers_updated} updated"
  [[ "$reviewers_skipped" -gt 0 ]]  && summary="${summary:+$summary, }${reviewers_skipped} customized (kept)"
  ok "Reviewer skill files: ${summary:-up to date}"
  echo "  - $target/.lazyspeckit/reviewers/"
}

main "${1:-}"
