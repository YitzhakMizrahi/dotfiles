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

# ── Python via pyenv ──
PYTHON_VERSION="3.13.3"
if command -v pyenv &>/dev/null; then
  if pyenv versions | grep -q "$PYTHON_VERSION"; then
    info "Python $PYTHON_VERSION already installed."
  else
    info "Installing Python $PYTHON_VERSION via pyenv..."
    pyenv install "$PYTHON_VERSION"
  fi
  pyenv global "$PYTHON_VERSION"
  success "Python $PYTHON_VERSION set as global default."
else
  warn "pyenv not found. Skipping Python setup."
fi

# ── Node.js via nvm ──
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \
  source "$NVM_DIR/nvm.sh"

if command -v nvm &>/dev/null; then
  info "Installing latest LTS Node via nvm..."
  nvm install --lts
  nvm use --lts
  nvm alias default 'lts/*'
  success "Node.js LTS installed and set as default."
else
  warn "nvm not found. Skipping Node.js setup."
fi

# ── pnpm ──
if command -v pnpm &>/dev/null; then
  success "pnpm already installed."
else
  if command -v npm &>/dev/null; then
    info "Installing pnpm via npm..."
    npm install -g pnpm
    success "pnpm installed."
  else
    warn "npm not found. Skipping pnpm installation."
  fi
fi

# ── Final summary ──
echo ""
echo "🔍 Installed Versions:"
echo "  🐍 Python:  $(command -v python >/dev/null && python --version 2>&1 || echo 'Not available')"
echo "  🟢 Node.js: $(command -v node >/dev/null && node --version 2>&1 || echo 'Not available')"
echo "  📦 pnpm:    $(command -v pnpm >/dev/null && pnpm --version 2>&1 || echo 'Not available')"
echo ""
success "🚀 Language environments ready to use."
warn "Note: Restart your shell to activate pyenv/nvm globally if needed."

