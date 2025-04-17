#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                🐍 Language Environment Setup                │
# ╰────────────────────────────────────────────────────────────╯
# Installs and configures Python via pyenv and Node via nvm

set -e

# ── Logging helpers ──
info()    { echo -e "\033[1;34m📘 $1\033[0m"; }
success() { echo -e "\033[1;32m✅ $1\033[0m"; }
warn()    { echo -e "\033[1;33m⚠️  $1\033[0m"; }
fail()    { echo -e "\033[1;31m❌ $1\033[0m"; exit 1; }

# ── Install pyenv ──
if ! command -v pyenv &>/dev/null; then
  info "Installing pyenv..."
  curl https://pyenv.run | bash

  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
  success "pyenv installed and configured."
else
  success "pyenv already installed."
fi

# ── Python via pyenv ──
PYTHON_VERSION="3.13.3"
if pyenv versions | grep -q "$PYTHON_VERSION"; then
  info "Python $PYTHON_VERSION already installed."
else
  info "Installing Python $PYTHON_VERSION via pyenv..."
  pyenv install "$PYTHON_VERSION"
fi

pyenv global "$PYTHON_VERSION"
success "Python $PYTHON_VERSION set as global default."

# ── Install nvm ──
if ! command -v nvm &>/dev/null; then
  info "Installing nvm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  source "$NVM_DIR/nvm.sh"
  success "nvm installed."
else
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
  success "nvm already installed."
fi

# ── Node.js via nvm ──
info "Installing latest LTS Node via nvm..."
nvm install --lts
nvm use --lts
nvm alias default 'lts/*'
success "Node.js LTS installed and set as default."

# ── pnpm via corepack ──
if ! command -v pnpm &>/dev/null; then
  info "Installing pnpm via corepack..."
  corepack enable
  corepack prepare pnpm@latest --activate
  success "pnpm installed."
else
  success "pnpm already installed."
fi

# ── Final summary ──
echo ""
echo "🔍 Installed Versions:"
echo "  🐍 Python:  $(python --version 2>&1)"
echo "  🟢 Node.js: $(node --version 2>&1)"
echo "  📦 pnpm:    $(pnpm --version 2>&1)"
echo ""
success "🚀 Language environments ready to use."
warn "Note: Restart your shell to activate pyenv/nvm globally if needed."

