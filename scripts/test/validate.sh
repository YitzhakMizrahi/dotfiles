#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                  Install Validation Tests                  │
# ╰────────────────────────────────────────────────────────────╯
# Run after install.sh to verify everything is set up correctly.
# Used by both Docker CI and local LXC testing.
# Exit code: 0 if all pass, 1 if any fail.

set -e

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../lib/paths.sh"
source "$_SCRIPT_DIR/../lib/brew.sh"
source "$_SCRIPT_DIR/../lib/tools.sh"

# Ensure Homebrew is on PATH (needed for Docker/LXC test environments)
brew_ensure_path

PASS=0
FAIL=0

check() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    printf "  PASS  %s\n" "$label"
    PASS=$((PASS + 1))
  else
    printf "  FAIL  %s\n" "$label"
    FAIL=$((FAIL + 1))
  fi
}

check_symlink() {
  local target="$1"
  local label="symlink: $target"
  if [[ -L "$target" ]]; then
    printf "  PASS  %s\n" "$label"
    PASS=$((PASS + 1))
  else
    printf "  FAIL  %s\n" "$label"
    FAIL=$((FAIL + 1))
  fi
}

echo
echo "=== Dotfiles Install Validation ==="
echo

# ── Symlinks ──────────────────────────────────────────────────
echo "-- Symlinks --"
SYMLINKS_SCRIPT="$HOME/.dotfiles/scripts/setup/symlinks.sh"
if [[ -f "$SYMLINKS_SCRIPT" ]]; then
  while IFS= read -r target; do
    check_symlink "${target/#\~/$HOME}"
  done < <(sed -n 's/^ *"\([^|]*\)|.*/\1/p' "$SYMLINKS_SCRIPT")
else
  printf "  FAIL  symlinks.sh not found\n"
  FAIL=$((FAIL + 1))
fi
echo

# ── Installed Tools (from Brewfile) ──────────────────────────────
echo "-- Installed Tools --"
while IFS= read -r formula; do
  tool_is_skipped "$formula" && continue
  check "$formula" command -v "$(tool_cmd "$formula")"
done < <(brewfile_formulas "$DOTFILES_DIR/Brewfile")
echo

# ── Runtime Manager ───────────────────────────────────────────
echo "-- Runtime Manager --"
check "mise"      command -v mise
echo

# ── Language Runtimes ─────────────────────────────────────────
echo "-- Language Runtimes (mise) --"
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash 2>/dev/null)" || true
  while IFS= read -r runtime; do
    check "$runtime" mise which "$(runtime_cmd "$runtime")"
  done < <(mise_runtimes)
else
  printf "  SKIP  mise not installed — skipping runtime checks\n"
fi
echo

# ── Shell Config ──────────────────────────────────────────────
echo "-- Shell Config --"
check "zinit installed" test -d "$ZINIT_HOME"
check "starship config exists" test -f "$STARSHIP_CONFIG"
check "gitconfig.local exists" test -f "$GITCONFIG_LOCAL"
echo

# ── Summary ───────────────────────────────────────────────────
TOTAL=$((PASS + FAIL))
echo "=== Results: $PASS/$TOTAL passed ==="

if [[ $FAIL -gt 0 ]]; then
  echo "$FAIL test(s) failed."
  exit 1
else
  echo "All tests passed."
  exit 0
fi
