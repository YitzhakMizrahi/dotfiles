#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                Post-Install Validation                     │
# ╰────────────────────────────────────────────────────────────╯
# Verifies tool versions and reminds about final manual steps

set -e

source "$(dirname "$0")/lib/ui.sh"

# ── Tool Version Checks ──────────────────────────────────────
print_version() {
  local label="$1"
  local cmd="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    local version
    version="$($cmd --version 2>/dev/null | head -n 1)"
    if [[ "$HAS_GUM" -eq 1 ]]; then
      printf "  $(gum style --foreground "$GB_GREEN" "✓") %-12s  %s\n" "$label" "$version"
    else
      printf "  %-12s  %s\n" "$label" "$version"
    fi
  else
    if [[ "$HAS_GUM" -eq 1 ]]; then
      printf "  $(gum style --foreground "$GB_RED" "✗") %-12s  Not found\n" "$label"
    else
      printf "  %-12s  Not found\n" "$label"
    fi
  fi
}

section "Installed Tools"
echo

# Core tools
print_version "Git" "git"
print_version "Zsh" "zsh"
print_version "tmux" "tmux"
print_version "Starship" "starship"
print_version "gum" "gum"

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

# ── Language Runtimes ────────────────────────────────────────
section "Language Runtimes"
echo
if command -v mise >/dev/null 2>&1; then
  mise list 2>/dev/null || ui_warn "No runtimes installed yet"
else
  ui_warn "mise not found — language runtimes not managed"
fi

# ── Symlink Validation ────────────────────────────────────────
section "Symlinks"
echo

check_symlink() {
  local target="$1"
  if [[ -L "$target" ]]; then
    if [[ "$HAS_GUM" -eq 1 ]]; then
      echo "  $(gum style --foreground "$GB_GREEN" "✓") $target"
    else
      printf "  %-40s  OK\n" "$target"
    fi
  elif [[ -e "$target" ]]; then
    if [[ "$HAS_GUM" -eq 1 ]]; then
      echo "  $(gum style --foreground "$GB_YELLOW" "⚠") $target (not a symlink)"
    else
      printf "  %-40s  EXISTS (not a symlink)\n" "$target"
    fi
  else
    if [[ "$HAS_GUM" -eq 1 ]]; then
      echo "  $(gum style --foreground "$GB_RED" "✗") $target (missing)"
    else
      printf "  %-40s  MISSING\n" "$target"
    fi
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
section "Next Steps"
echo
echo "    gh auth login                          Authenticate GitHub CLI"
echo "    exec zsh                               Reload shell"
echo "    cat ~/.gitconfig.local                 Review Git identity"

echo
ui_success "Post-install validation complete"
