#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │              Zsh + Zinit Shell Setup                       │
# ╰────────────────────────────────────────────────────────────╯
# Installs Zinit plugin manager and offers chsh to Zsh.
# Does NOT modify .zshrc — it is managed declaratively via the repo.

set -e

source "$(dirname "$0")/lib/ui.sh"

# ── Zinit Installation ───────────────────────────────────────
ZINIT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

if [[ -d "$ZINIT_DIR" ]]; then
  ui_success "Zinit already installed"
else
  ui_info "Installing Zinit plugin manager..."
  mkdir -p "$(dirname "$ZINIT_DIR")"
  git clone --depth 1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_DIR"
  ui_success "Zinit installed"
fi

# ── Offer chsh to Zsh ────────────────────────────────────────
if [[ "$SHELL" != *zsh ]]; then
  echo
  if ui_confirm "Make Zsh your default shell?"; then
    if command -v zsh >/dev/null 2>&1; then
      chsh -s "$(command -v zsh)"
      ui_success "Zsh set as default shell"
    else
      ui_warn "Zsh is not installed — cannot change shell"
    fi
  else
    ui_info "You can change your shell later with: chsh -s \$(which zsh)"
  fi
fi

echo
ui_success "Shell configuration complete"
