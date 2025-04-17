#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                🐍 Language Environment Setup                │
# ╰────────────────────────────────────────────────────────────╯
# Ensures Python, Node, and pnpm are configured and usable.
# Assumes tools are already installed via install-tools.sh

set -e

# ── Logging helpers ──
info()    { echo -e "\033[1;34m📘 $1\033[0m"; }
success() { echo -e "\033[1;32m✅ $1\033[0m"; }
warn()    { echo -e "\033[1;33m⚠️  $1\033[0m"; }
fail()    { echo -e "\033[1;31m❌ $1\033[0m"; exit 1; }

# ── pyenv setup ──
if [[ -d "$HOME/.pyenv" ]]; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"

  info "🔎 Detecting latest stable Python version..."
  latest_stable=$(pyenv install --list | grep -E "^\s*3\.[0-9]+\.[0-9]+$" | grep -v - | tail -1 | tr -d '[:space:]')

  if [[ -z "$latest_stable" ]]; then
    warn "Could not detect latest Python version. Skipping Python setup."
  elif pyenv versions | grep -q "$latest_stable"; then
    info "Python $latest_stable already installed."
  else
    info "Installing Python $latest_stable via pyenv..."
    pyenv install "$latest_stable"
  fi

  pyenv global "$latest_stable"
  success "Python $latest_stable set as global default."
else
  warn "pyenv not found. Skipping Python setup."
fi

# ── nvm setup ──
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  source "$NVM_DIR/nvm.sh"

  info "Ensuring latest LTS Node.js is installed via nvm..."
  nvm install --lts
  nvm use --lts
  nvm alias default 'lts/*'
  success "Node.js LTS installed and set as default."
else
  warn "nvm not found. Skipping Node.js setup."
fi

# ── pnpm check ──
if command -v pnpm &>/dev/null; then
  success "pnpm is available."
else
  warn "pnpm not found in PATH. Skipping pnpm setup."
fi

# ── Final summary ──
echo ""
echo "🔍 Installed Versions:"
echo "  🐍 Python:  $(command -v python >/dev/null && python --version 2>&1 || echo 'Not found')"
echo "  🟢 Node.js: $(command -v node >/dev/null && node --version 2>&1 || echo 'Not found')"
echo "  📦 pnpm:    $(command -v pnpm >/dev/null && pnpm --version 2>&1 || echo 'Not found')"
echo ""
success "🚀 Language environments verified and ready to use."
warn "Note: Restart your shell to activate pyenv/nvm globally if needed."
