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
  printf 'https://raw.githubusercontent.com/%s/%s/%s' "$OWNER_REPO" "$REF" "$PROMPT_REPO_PATH"
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
}

main "${1:-}"
