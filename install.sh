#!/usr/bin/env bash
set -Eeuo pipefail

# install.sh — installs the lazyspeckit CLI into your PATH (user install).
#
# Usage:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/Hacklone/lazy-spec-kit/main/install.sh)"
#
# Env:
#   BIN_DIR=/custom/bin
#   LAZYSPECKIT_REF=main|v0.5.0|<sha>
#   DEBUG=1

OWNER_REPO="Hacklone/lazy-spec-kit"
REF="${LAZYSPECKIT_REF:-main}"
CLI_REPO_PATH="cli/lazyspeckit"

DEBUG="${DEBUG:-0}"

have() { command -v "${1:-__missing__}" >/dev/null 2>&1; }
die() { echo "install: $*" >&2; exit 1; }

on_err() {
  local ec="$?"
  local line="${BASH_LINENO[0]:-unknown}"
  local cmd="${BASH_COMMAND:-unknown}"
  echo "install: Failed (exit $ec) at line ${line}: ${cmd}" >&2
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
    die "Need curl or wget."
  fi
}

cache_bust() {
  local url="${1:-}"
  [[ -n "$url" ]] || die "cache_bust: missing url"
  printf "%s?cb=%s" "$url" "$(date +%s)"
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

UNAME="$(uname -s 2>/dev/null || true)"
if [[ "$UNAME" == MINGW* || "$UNAME" == MSYS* || "$UNAME" == CYGWIN* ]]; then
  DEFAULT_BIN="$HOME/bin"
else
  DEFAULT_BIN="$HOME/.local/bin"
fi

BIN_DIR="${BIN_DIR:-$DEFAULT_BIN}"
BIN_PATH="$BIN_DIR/lazyspeckit"

URL="$(cache_bust "https://raw.githubusercontent.com/${OWNER_REPO}/${REF}/${CLI_REPO_PATH}")"

mkdir -p "$BIN_DIR"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

echo "==> Downloading lazyspeckit (ref: $REF)..."
fetch "$URL" "$tmp"

grep -q "lazyspeckit" "$tmp" || die "Downloaded file does not look like lazyspeckit."

install_file "$tmp" "$BIN_PATH"

echo "✅ Installed: $BIN_PATH"

case ":$PATH:" in
  *":$BIN_DIR:"*) echo "✅ $BIN_DIR is on PATH" ;;
  *)
    echo
    echo "⚠️  $BIN_DIR is not on your PATH."
    echo "Add this to ~/.bashrc or ~/.zshrc, then restart your terminal:"
    echo
    echo "  export PATH=\"$BIN_DIR:\$PATH\""
    ;;
esac

echo
echo "Try:"
echo "  lazyspeckit --help"
