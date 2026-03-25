#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                  Nerd Font Setup                           │
# ╰────────────────────────────────────────────────────────────╯
# Detects Nerd Font presence and offers optional install.
# Skipped on WSL (fonts are managed by the Windows terminal).
# Override with DOTFILES_FORCE_FONTS=1 to test this code path.

set -e

source "$(dirname "$0")/../lib/ui.sh"

# ── WSL Detection ────────────────────────────────────────────
if [[ "${DOTFILES_FORCE_FONTS:-0}" -ne 1 ]] && grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then
  ui_info "WSL detected — Nerd Fonts should be managed via your Windows terminal."
  exit 0
fi

# ── Dependency Check ───────────────────────────────────────────
if ! command -v unzip >/dev/null 2>&1; then
  ui_warn "unzip not found — cannot install fonts"
  exit 0
fi

# ── Nerd Font Check ──────────────────────────────────────────
nerd_font_installed() {
  # Linux: use fc-list
  if command -v fc-list >/dev/null 2>&1; then
    fc-list | grep -iE 'Nerd Font|NF' &>/dev/null && return 0
  fi
  # macOS: check ~/Library/Fonts directly
  if [[ "$OSTYPE" == "darwin"* ]] && ls "$HOME/Library/Fonts/"*Nerd* &>/dev/null; then
    return 0
  fi
  return 1
}

if nerd_font_installed; then
  ui_success "Nerd Font already installed"
  exit 0
else
  ui_warn "No Nerd Font detected"
fi

# ── Font Selection ───────────────────────────────────────────
FONTS=("FiraCode" "CaskaydiaCove" "JetBrainsMono" "Skip")

if [[ "$HAS_GUM" -eq 1 ]]; then
  font_choice=$(gum choose --header "Choose a Nerd Font to install:" "${FONTS[@]}")
else
  echo
  echo "  Choose a Nerd Font to install:"
  echo "    1) FiraCode"
  echo "    2) CaskaydiaCove"
  echo "    3) JetBrainsMono"
  echo "    4) Skip"
  read -p "  Enter choice [1-4]: " -r choice
  case $choice in
    1) font_choice="FiraCode" ;;
    2) font_choice="CaskaydiaCove" ;;
    3) font_choice="JetBrainsMono" ;;
    *) font_choice="Skip" ;;
  esac
fi

if [[ "$font_choice" == "Skip" ]]; then
  ui_info "Skipped font installation"
  exit 0
fi

# ── Font Installer ───────────────────────────────────────────
install_font() {
  local name="$1"
  local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${name}.zip"
  local tmp_dir="/tmp/nerdfont-install"

  mkdir -p "$tmp_dir"

  ui_info "Downloading $name Nerd Font..."
  if ! curl -fLs -o "$tmp_dir/$name.zip" "$url"; then
    ui_warn "Download failed — check your network connection"
    return 1
  fi

  if ! unzip -o "$tmp_dir/$name.zip" -d "$tmp_dir/$name" >/dev/null 2>&1; then
    ui_warn "Failed to extract font archive"
    return 1
  fi

  # macOS: ~/Library/Fonts, Linux: ~/.local/share/fonts
  local font_dir
  if [[ "$OSTYPE" == "darwin"* ]]; then
    font_dir="$HOME/Library/Fonts"
  else
    font_dir="$HOME/.local/share/fonts"
  fi

  mkdir -p "$font_dir"
  find "$tmp_dir/$name" -type f \( -name '*.ttf' -o -name '*.otf' \) -exec cp {} "$font_dir/" \;

  # Rebuild font cache (Linux only — macOS picks up fonts automatically)
  if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f &>/dev/null
  fi

  ui_success "$name Nerd Font installed"
}

install_font "$font_choice"
