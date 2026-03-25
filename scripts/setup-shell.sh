#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │         💻 Zsh + Starship + Shell Enhancements Setup        │
# ╰────────────────────────────────────────────────────────────╯
# Ensures Zsh plugins, Starship, and prompt configs are in place

set -e

source "$(dirname "$0")/lib/logging.sh"

ZSHRC="$HOME/.zshrc"
ZINIT_HOME="${ZINIT_HOME:-$HOME/.zinit/bin}"
ZINIT_URL="https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh"

# ── Ensure .zshrc Exists ─────────────────────────────────────
touch "$ZSHRC"

# ── Zinit Installation ───────────────────────────────────────
if [[ ! -d "$ZINIT_HOME" ]]; then
  info "Installing Zinit plugin manager..."
  bash -c "$(curl -fsSL $ZINIT_URL)"
  success "Zinit installed."
else
  success "Zinit already installed."
fi

# ── Zinit Init Block ─────────────────────────────────────────
if ! grep -q "zinit light" "$ZSHRC"; then
  info "Adding Zinit init block to .zshrc..."
  cat <<'EOF' >> "$ZSHRC"

# Zinit Plugin Manager
source "$HOME/.zinit/bin/zinit.zsh"
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
EOF
  success "Zinit block added to .zshrc."
else
  info "Zinit block already present in .zshrc."
fi

# ── Starship Config ──────────────────────────────────────────
if ! grep -q 'starship init zsh' "$ZSHRC"; then
  info "Adding Starship init to .zshrc..."
  echo 'eval "$(starship init zsh)"' >> "$ZSHRC"
  echo 'export STARSHIP_CONFIG="$HOME/.config/starship.toml"' >> "$ZSHRC"
  success "Starship init added to .zshrc."
else
  info "Starship already configured in .zshrc."
fi

# ── Offer chsh to Zsh ────────────────────────────────────────
if [[ "$SHELL" != *zsh ]]; then
  echo
  read -p "⚙️  Make Zsh your default shell? [Y/n]: " change_shell
  change_shell=${change_shell:-Y}
  if [[ "$change_shell" =~ ^[Yy]$ ]]; then
    if command -v zsh >/dev/null 2>&1; then
      chsh -s "$(command -v zsh)"
      success "Zsh set as default shell."
    else
      warn "Zsh is not installed, cannot change shell."
    fi
  else
    info "You can change your shell later with: chsh -s \$(which zsh)"
  fi
fi

# ── Done ─────────────────────────────────────────────────────
echo
success "💻 Shell configuration complete!"
warn "Note: Restart your shell to activate plugin and prompt changes."
