#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                  Post-Install Cleanup                      │
# ╰────────────────────────────────────────────────────────────╯
# Cleans temp files from setup (fonts), runs brew/apt cleanup,
# and reports disk savings.

set -e

source "$(dirname "$0")/lib/ui.sh"

# ── Size helpers ──────────────────────────────────────────────
get_bytes() {
  du -sb "$1" 2>/dev/null | cut -f1 || echo 0
}

ui_info "Performing post-install cleanup..."
echo

TOTAL_SAVED=0

# Clean Nerd Font temp dir
FONT_TMP="/tmp/nerdfont-install"
if [[ -d "$FONT_TMP" ]]; then
  before=$(get_bytes "$FONT_TMP")
  rm -rf "$FONT_TMP"
  ui_success "Removed Nerd Font temp folder"
  TOTAL_SAVED=$((TOTAL_SAVED + before))
else
  ui_info "Nerd Font temp folder already clean"
fi

# Brew cleanup
if command -v brew >/dev/null 2>&1; then
  ui_info "Running Homebrew cleanup..."
  brew cleanup -s 2>/dev/null || true
fi

# APT autoremove (Linux/WSL only)
if command -v apt-get &>/dev/null; then
  ui_info "Running APT autoremove..."
  sudo apt-get autoremove -y 2>/dev/null || true
fi

echo
ui_success "Post-install cleanup complete"
