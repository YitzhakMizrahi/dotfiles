#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                 🔤 Nerd Font Setup Script                  │
# ╰────────────────────────────────────────────────────────────╯
# Detects Nerd Font presence and offers optional install

set -e

source "$(dirname "$0")/lib/logging.sh"

# ── OS & WSL Detection ────────────────────────────────────────
is_wsl=false
if grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then
  is_wsl=true
fi

# ── Nerd Font Check ───────────────────────────────────────────
if $is_wsl; then
  info "Detected WSL — Nerd Fonts should be managed via your Windows Terminal profile."
  exit 0
fi

if fc-list | grep -iE 'Nerd Font|NF' &>/dev/null; then
  success "Nerd Font already installed."
  exit 0
else
  warn "No Nerd Font detected."
fi

# ── Prompt for Installation ───────────────────────────────────
echo -e "\nChoose a Nerd Font to install:"
echo "  1) FiraCode NF"
echo "  2) CaskaydiaCove NF"
echo "  3) JetBrainsMono NF"
echo "  4) Skip installation"
echo -n "Enter your choice [1-4]: "
read -r font_choice

# ── Font Installer ────────────────────────────────────────────
install_font() {
  local font_name="$1"
  local zip_url="$2"
  local tmp_dir="/tmp/nerdfont-install"
  mkdir -p "$tmp_dir"
  curl -Ls -o "$tmp_dir/$font_name.zip" "$zip_url"
  unzip -o "$tmp_dir/$font_name.zip" -d "$tmp_dir"
  mkdir -p "$HOME/.local/share/fonts"
  cp "$tmp_dir"/*.ttf "$HOME/.local/share/fonts/" || true
  fc-cache -fv &>/dev/null
  success "$font_name NF installed."
}

case $font_choice in
  1)
    install_font "FiraCode" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
    ;;
  2)
    install_font "CaskaydiaCove" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CaskaydiaCove.zip"
    ;;
  3)
    install_font "JetBrainsMono" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    ;;
  *)
    info "Skipped font installation."
    ;;
esac