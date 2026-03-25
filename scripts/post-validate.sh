#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                Post-Install Validation                     │
# ╰────────────────────────────────────────────────────────────╯
# Verifies tool versions and reminds about final manual steps

set -e

source "$(dirname "$0")/lib/logging.sh"

# ── Tool Version Checks ──────────────────────────────────────
print_version() {
  local label="$1"
  local cmd="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    local version
    version="$($cmd --version 2>/dev/null | head -n 1)"
    printf "  %-12s  %s\n" "$label" "$version"
  else
    printf "  %-12s  Not found\n" "$label"
  fi
}

echo
info "Checking installed tools..."
echo

# Core tools
print_version "Git" "git"
print_version "Zsh" "zsh"
print_version "tmux" "tmux"
print_version "Starship" "starship"

echo

# Modern CLI tools
print_version "bat" "bat"
print_version "lsd" "lsd"
print_version "fd" "fd"
print_version "ripgrep" "rg"
print_version "fzf" "fzf"
print_version "zoxide" "zoxide"
print_version "delta" "delta"
print_version "lazygit" "lazygit"
print_version "yazi" "yazi"
print_version "gh" "gh"
print_version "btop" "btop"
print_version "fastfetch" "fastfetch"

echo

# Language runtimes via mise
if command -v mise >/dev/null 2>&1; then
  info "Language runtimes (mise):"
  mise list 2>/dev/null || warn "No runtimes installed yet."
else
  warn "mise not found — language runtimes not managed."
fi

# ── Symlink Validation ────────────────────────────────────────
echo
info "Checking symlinks..."

check_symlink() {
  local target="$1"
  if [[ -L "$target" ]]; then
    printf "  %-40s  OK\n" "$target"
  elif [[ -e "$target" ]]; then
    printf "  %-40s  EXISTS (not a symlink)\n" "$target"
  else
    printf "  %-40s  MISSING\n" "$target"
  fi
}

check_symlink "$HOME/.zshrc"
check_symlink "$HOME/.tmux.conf"
check_symlink "$HOME/.gitconfig"
check_symlink "$HOME/.config/lsd/config.yaml"
check_symlink "$HOME/.config/gh/config.yml"
check_symlink "$HOME/.config/lazygit/config.yml"
check_symlink "$HOME/.config/wezterm/wezterm.lua"

# ── Final Checklist ───────────────────────────────────────────
echo
info "Things you may still want to do manually:"
echo
echo "  - Run 'gh auth login' to authenticate GitHub CLI"
echo "  - Run 'exec zsh' or open a new terminal to reload shell"
echo "  - Review ~/.gitconfig.local for correctness"

echo
success "Post-install validation complete."
