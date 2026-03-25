#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                  Default Shell Setup                       │
# ╰────────────────────────────────────────────────────────────╯
# Offers to change the default shell to Zsh.
# Zinit install and plugin download are handled by install.sh.

set -e

source "$(dirname "$0")/../lib/ui.sh"

if [[ "$SHELL" == *zsh ]]; then
  ui_success "Zsh is already the default shell"
  exit 0
fi

if ui_confirm "Make Zsh your default shell?"; then
  if command -v zsh >/dev/null 2>&1; then
    zsh_path="$(command -v zsh)"
    # Ensure zsh is in /etc/shells (Homebrew zsh won't be by default)
    if ! grep -qF "$zsh_path" /etc/shells 2>/dev/null; then
      echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi
    sudo chsh -s "$zsh_path" "$(whoami)"
    ui_success "Zsh set as default shell"
  else
    ui_warn "Zsh is not installed — cannot change shell"
  fi
else
  ui_info "You can change your shell later with: chsh -s \$(which zsh)"
fi
