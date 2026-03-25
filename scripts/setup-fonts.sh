#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                  Nerd Font Setup                           │
# ╰────────────────────────────────────────────────────────────╯
# Detects Nerd Font presence and offers optional install

set -e

source "$(dirname "$0")/lib/ui.sh"

# ── WSL Detection ────────────────────────────────────────────
if grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then
  ui_info "WSL detected — Nerd Fonts should be managed via your Windows terminal."
  exit 0
fi

# ── Nerd Font Check ──────────────────────────────────────────
if fc-list 2>/dev/null | grep -iE 'Nerd Font|NF' &>/dev/null; then
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
  echo "Choose a Nerd Font to install:"
  echo "  1) FiraCode"
  echo "  2) CaskaydiaCove"
  echo "  3) JetBrainsMono"
  echo "  4) Skip"
  read -p "Enter choice [1-4]: " -r choice
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
  curl -Ls -o "$tmp_dir/$name.zip" "$url"
  unzip -o "$tmp_dir/$name.zip" -d "$tmp_dir" >/dev/null
  mkdir -p "$HOME/.local/share/fonts"
  cp "$tmp_dir"/*.ttf "$HOME/.local/share/fonts/" 2>/dev/null || true
  fc-cache -fv &>/dev/null
  ui_success "$name Nerd Font installed"
}

if [[ "$HAS_GUM" -eq 1 ]]; then
  gum spin --spinner dot --title "Installing $font_choice Nerd Font..." -- install_font "$font_choice"
else
  install_font "$font_choice"
fi
