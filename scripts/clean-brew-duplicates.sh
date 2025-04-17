#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │      🧹 Clean Brew Tools Already Installed via APT          │
# ╰────────────────────────────────────────────────────────────╯

set -e

info()    { echo -e "\033[1;34mℹ️  $1\033[0m"; }
success() { echo -e "\033[1;32m✅ $1\033[0m"; }
warn()    { echo -e "\033[1;33m⚠️  $1\033[0m"; }

declare -A APT_EQUIVALENTS=(
  [fd]="fdfind"
  [bat]="batcat"
)

TOOLS=(git gh zsh tmux wget lazygit fd bat)

# Check if apt is present
if ! command -v apt &>/dev/null; then
  warn "APT not detected on this system. Exiting."
  exit 0
fi

info "Cross-checking APT vs Brew installed tools..."

for tool in "${TOOLS[@]}"; do
  apt_name="${APT_EQUIVALENTS[$tool]:-$tool}"
  brew_installed=false
  apt_installed=false

  # Check Brew
  if brew list "$tool" &>/dev/null; then
    brew_installed=true
  fi

  # Check APT
  if dpkg -s "$apt_name" &>/dev/null; then
    apt_installed=true
  fi

  # Only uninstall if both exist
  if [[ "$brew_installed" == true && "$apt_installed" == true ]]; then
    info "Removing $tool from Brew (APT handles $apt_name)..."
    brew uninstall "$tool"
    success "$tool removed from Brew."
  elif [[ "$brew_installed" == true ]]; then
    warn "$tool is installed with Brew but not found via APT — skipping."
  else
    info "$tool not installed with Brew — skipping."
  fi
done

echo
success "Brew duplicate cleanup complete."
