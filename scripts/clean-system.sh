#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                  System Cleanup Utility                    │
# ╰────────────────────────────────────────────────────────────╯
# Interactive cleanup of trash, caches, and browser data.
# Linux desktop / WSL only.

set -e

source "$(dirname "$0")/lib/ui.sh"

# ── Helpers ───────────────────────────────────────────────────
get_dir_size() {
  local dir="$1"
  if [[ -d "$dir" ]] && [[ -n "$(ls -A "$dir" 2>/dev/null)" ]]; then
    du -sh "$dir" 2>/dev/null | cut -f1
  else
    echo "0"
  fi
}

get_num_files() {
  local dir="$1"
  if [[ -d "$dir" ]] && [[ -n "$(ls -A "$dir" 2>/dev/null)" ]]; then
    find "$dir" -type f 2>/dev/null | wc -l
  else
    echo "0"
  fi
}

clear_dir() {
  local dir="$1"
  local label="$2"

  if [[ ! -d "$dir" ]]; then
    ui_info "$label — directory does not exist"
    return 0
  fi

  if [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
    ui_success "$label — already empty"
    return 0
  fi

  local total_size
  local num_files
  total_size=$(get_dir_size "$dir")
  num_files=$(get_num_files "$dir")

  ui_info "$label: $num_files file(s), $total_size total"
  if ui_confirm "  Delete all files in $label?"; then
    rm -rf "${dir:?}"/*
    ui_success "$label cleared ($total_size freed)"
  else
    ui_info "Skipped"
  fi
}

# ── Main ──────────────────────────────────────────────────────
banner "System Cleanup" "$(hostname) · $(date +%Y-%m-%d)"

clear_dir "$HOME/.local/share/Trash/files"       "Trash"
clear_dir "$HOME/Pictures/Screenshots"            "Screenshots"
clear_dir "$HOME/.cache/thumbnails"               "Cache thumbnails"
clear_dir "$HOME/snap/chromium/common/.cache"     "Chromium cache"
clear_dir "$HOME/snap/firefox/common/.cache"      "Firefox cache"

echo
ui_success "System cleanup complete"
