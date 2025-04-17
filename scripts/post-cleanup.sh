#!/usr/bin/env bash

# ╝ Post-Cleanup Script ╜
# Cleans temp files from setup (pyenv, fonts), performs package cleanup,
# and reports disk savings in a clean visual way.

set -e

# ── Logging helpers ──
info()    { echo -e "\033[1;34mℹ️  $1\033[0m"; }
success() { echo -e "\033[1;32m✅ $1\033[0m"; }
warn()    { echo -e "\033[1;33m⚠️  $1\033[0m"; }

# ── Size helpers ──
get_size() {
  du -sh "$1" 2>/dev/null | cut -f1 || echo "0"
}
get_bytes() {
  du -sb "$1" 2>/dev/null | cut -f1 || echo 0
}

# ── Paths ──
PYENV_CACHE="$HOME/.pyenv/cache"
FONT_TMP="/tmp/nerdfont-install"

info "Performing post-bootstrap cleanup..."
echo

TOTAL_SAVED=0

# Clean pyenv cache
if [[ -d "$PYENV_CACHE" && -n "$(ls -A $PYENV_CACHE 2>/dev/null)" ]]; then
  before=$(get_bytes "$PYENV_CACHE")
  size_human=$(get_size "$PYENV_CACHE")
  rm -rf "$PYENV_CACHE"/*
  echo -e "\U0001f40d  Cleared pyenv build cache ($size_human)"
  TOTAL_SAVED=$((TOTAL_SAVED + before))
else
  echo -e "\U0001f40d  Pyenv cache already clean."
fi

# Clean Nerd Font temp dir
if [[ -d "$FONT_TMP" ]]; then
  before=$(get_bytes "$FONT_TMP")
  size_human=$(get_size "$FONT_TMP")
  rm -rf "$FONT_TMP"
  echo -e "\U0001f58c️  Removed Nerd Font temp folder ($size_human)"
  TOTAL_SAVED=$((TOTAL_SAVED + before))
else
  echo -e "\U0001f58c️  Nerd Font temp folder already removed."
fi

# Brew cleanup (if available)
if command -v brew >/dev/null 2>&1; then
  echo
  info "Running Homebrew cleanup..."
  brew cleanup -s || true
fi

# APT autoremove (Linux / WSL)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  echo
  info "Running APT autoremove..."
  sudo apt autoremove -y || true
fi

# Final disk savings report
if [[ $TOTAL_SAVED -gt 0 ]]; then
  human_saved=$(numfmt --to=iec $TOTAL_SAVED 2>/dev/null || echo "$((TOTAL_SAVED / 1024 / 1024)) MB")
  echo
  success "🎉 You reclaimed approximately $human_saved of disk space!"
else
  echo
  info "No cleanup was necessary."
fi

echo
success "✨ Post-bootstrap cleanup complete."