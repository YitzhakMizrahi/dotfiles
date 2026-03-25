#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │              UI Library (Gum + Fallback)                   │
# ╰────────────────────────────────────────────────────────────╯
# Elegant terminal output using Charmbracelet's gum when available,
# with graceful ANSI fallback. Gruvbox-themed.
#
# Source this file instead of logging.sh:
#   source "$(dirname "$0")/lib/ui.sh"

# Guard against double-sourcing
[[ -n "${__UI_SH_LOADED:-}" ]] && return 0
__UI_SH_LOADED=1

# Source logging.sh for fallback functions
_UI_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_UI_LIB_DIR/logging.sh"

# ── Gruvbox Palette ─────────────────────────────────────────
readonly GB_FG="#ebdbb2"
readonly GB_RED="#fb4934"
readonly GB_GREEN="#8ec07c"
readonly GB_YELLOW="#fabd2f"
readonly GB_BLUE="#83a598"
readonly GB_PURPLE="#d3869b"
readonly GB_ORANGE="#fe8019"
readonly GB_GRAY="#928374"

# ── Gum Detection ──────────────────────────────────────────
if command -v gum &>/dev/null; then
  HAS_GUM=1
else
  HAS_GUM=0
fi

# ── Gum Theme (env vars) ───────────────────────────────────
if [[ "$HAS_GUM" -eq 1 ]]; then
  export GUM_CONFIRM_PROMPT_FOREGROUND="$GB_FG"
  export GUM_CONFIRM_SELECTED_BACKGROUND="$GB_BLUE"
  export GUM_CONFIRM_SELECTED_FOREGROUND="#282828"
  export GUM_CONFIRM_UNSELECTED_FOREGROUND="$GB_GRAY"
  export GUM_INPUT_PROMPT_FOREGROUND="$GB_BLUE"
  export GUM_INPUT_CURSOR_FOREGROUND="$GB_ORANGE"
  export GUM_INPUT_PLACEHOLDER_FOREGROUND="$GB_GRAY"
  export GUM_CHOOSE_CURSOR_FOREGROUND="$GB_ORANGE"
  export GUM_CHOOSE_SELECTED_FOREGROUND="$GB_GREEN"
  export GUM_SPIN_SPINNER_FOREGROUND="$GB_BLUE"
fi

# ── Banner ──────────────────────────────────────────────────
# Usage: banner "Dotfiles Installer" "linux · wsl · x86_64"
banner() {
  local title="$1"
  local subtitle="${2:-}"

  if [[ "$HAS_GUM" -eq 1 ]]; then
    local body="$title"
    [[ -n "$subtitle" ]] && body=$(printf "%s\n%s" "$title" "$subtitle")
    echo
    gum style \
      --border rounded \
      --border-foreground "$GB_BLUE" \
      --foreground "$GB_FG" \
      --padding "1 4" \
      --align center \
      "$body"
    echo
  else
    echo
    divider
    echo -e "\033[1;34m  $title\033[0m"
    [[ -n "$subtitle" ]] && echo -e "\033[0;37m  $subtitle\033[0m"
    divider
    echo
  fi
}

# ── Section Header ──────────────────────────────────────────
# Usage: section "Configuration"
section() {
  local title="$1"
  if [[ "$HAS_GUM" -eq 1 ]]; then
    echo
    gum style --foreground "$GB_BLUE" --bold "── $title ──"
  else
    echo
    echo -e "\033[1;34m── $title ──\033[0m"
  fi
}

# ── Step (spinner wrapper) ──────────────────────────────────
# Runs a command with a spinner. Do NOT use for interactive commands.
# Usage: step "Installing packages" brew bundle --file=Brewfile
step() {
  local label="$1"
  shift

  if [[ "$HAS_GUM" -eq 1 ]]; then
    if gum spin --spinner dot --title "$label" -- "$@" 2>/dev/null; then
      echo "  $(gum style --foreground "$GB_GREEN" "✓") $label"
    else
      echo "  $(gum style --foreground "$GB_RED" "✗") $label"
      return 1
    fi
  else
    info "$label..."
    if "$@"; then
      success "$label"
    else
      warn "$label — failed"
      return 1
    fi
  fi
}

# ── Confirm ─────────────────────────────────────────────────
# Usage: if ui_confirm "Restart shell?"; then ...
ui_confirm() {
  local prompt="$1"
  if [[ "$HAS_GUM" -eq 1 ]]; then
    gum confirm "$prompt"
  else
    read -p "$prompt [y/N]: " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
  fi
}

# ── Input ───────────────────────────────────────────────────
# Usage: name=$(ui_input "Name:" "John Doe")
ui_input() {
  local prompt="$1"
  local placeholder="${2:-}"
  if [[ "$HAS_GUM" -eq 1 ]]; then
    gum input --prompt "$prompt " --placeholder "$placeholder"
  else
    read -p "$prompt " -r response
    echo "$response"
  fi
}

# ── Status Messages ─────────────────────────────────────────
ui_info() {
  if [[ "$HAS_GUM" -eq 1 ]]; then
    echo "  $(gum style --foreground "$GB_BLUE" "ℹ") $1"
  else
    info "$1"
  fi
}

ui_success() {
  if [[ "$HAS_GUM" -eq 1 ]]; then
    echo "  $(gum style --foreground "$GB_GREEN" "✓") $1"
  else
    success "$1"
  fi
}

ui_warn() {
  if [[ "$HAS_GUM" -eq 1 ]]; then
    echo "  $(gum style --foreground "$GB_YELLOW" "⚠") $1"
  else
    warn "$1"
  fi
}

ui_fail() {
  if [[ "$HAS_GUM" -eq 1 ]]; then
    echo "  $(gum style --foreground "$GB_RED" "✗") $1"
  else
    echo -e "\033[1;31m✗ $1\033[0m"
  fi
  exit 1
}
