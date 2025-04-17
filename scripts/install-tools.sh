#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │        📦 Installing CLI Tools and Package Managers        │
# ╰────────────────────────────────────────────────────────────╯
# Handles platform detection and installs Homebrew, core tools,
# │ and other utilities needed for your dev setup.

set -e

# ── Logging helpers ──
info()    { echo -e "\033[1;34mℹ️  $1\033[0m"; }
success() { echo -e "\033[1;32m✅ $1\033[0m"; }
warn()    { echo -e "\033[1;33m⚠️  $1\033[0m"; }
fail()    { echo -e "\033[1;31m❌ $1\033[0m"; exit 1; }

# ── Detect OS ──
PLATFORM="unknown"

if [[ "$OSTYPE" == "darwin"* ]]; then
  PLATFORM="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  if grep -qi microsoft /proc/version; then
    PLATFORM="wsl"
  else
    PLATFORM="linux"
  fi
fi

info "Detected platform: $PLATFORM"

# ── Install Homebrew ──
install_homebrew() {
  if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv 2>/dev/null || /opt/homebrew/bin/brew shellenv)"
    success "Homebrew installed."
  else
    success "Homebrew already installed."
  fi
}

# ── Install Brew Tools for macOS (includes system-level) ──
install_brew_tools_for_mac() {
  local base_tools=(git zsh tmux curl wget)  # Often preinstalled, but safe to re-check
  local dev_tools=(gh lsd bat starship fd ripgrep fzf neofetch btop lazygit yazi)

  info "Updating Homebrew..."
  brew update

  info "Installing base tools via Homebrew (macOS)..."
  brew install "${base_tools[@]}"

  info "Installing dev tools via Homebrew (macOS)..."
  brew install "${dev_tools[@]}"

  success "All Homebrew tools for macOS installed."
}

# ── Install Brew Tools (dev tools only) ──
install_brew_tools() {
  local tools=(gh lsd bat starship fd ripgrep fzf neofetch btop lazygit yazi)
  info "Updating Homebrew..."
  brew update

  info "Installing tools via Homebrew..."
  if ! brew install "${tools[@]}"; then
    warn "Some tools may have failed to install — check logs."
  fi

  success "Brew tools installed."
}

# ── Install APT Tools (system-level) ──
install_apt_tools() {
  info "Installing base tools via APT..."
  sudo apt update -y
  sudo apt install -y \
    git zsh tmux curl wget

  success "APT tools installed."
}

# ── Install Python & Node environments ──
install_python_node_envs() {
  info "🐍 Installing Python/Node environments..."

  # Needed for building Python from source
  info "📦 Installing build-essential via APT..."
  sudo apt install -y build-essential

  install_pyenv
  install_nvm
  install_pnpm

  success "Python/Node environments installed."
}

install_pyenv() {
  info "📘 Installing pyenv..."
  if [[ -d "$HOME/.pyenv" ]]; then
    warn "pyenv already installed. Skipping."
    return
  fi

  git clone https://github.com/pyenv/pyenv.git ~/.pyenv
  git clone https://github.com/pyenv/pyenv-doctor.git ~/.pyenv/plugins/pyenv-doctor
  git clone https://github.com/pyenv/pyenv-update.git ~/.pyenv/plugins/pyenv-update
  git clone https://github.com/pyenv/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv

  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init - bash)"
  eval "$(pyenv virtualenv-init -)"

  success "pyenv installed and configured."

  info "📘 Installing Python 3.13.3 via pyenv..."
  pyenv install 3.13.3
  pyenv global 3.13.3
}

install_nvm() {
  info "📘 Installing nvm..."
  export NVM_DIR="$HOME/.nvm"
  if [[ ! -d "$NVM_DIR" ]]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash
  fi
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  info "📦 Installing latest LTS Node..."
  nvm install --lts
  nvm use --lts
  nvm alias default 'lts/*'
  success "nvm and Node installed."
}

install_pnpm() {
  info "📘 Installing pnpm via corepack..."
  corepack enable
  corepack prepare pnpm@latest --activate
  success "pnpm installed."
}


# ── Install per-platform ──
case "$PLATFORM" in
  macos)
    install_homebrew
    install_brew_tools_for_mac
    install_python_node_envs
    ;;
  wsl|linux)
    install_apt_tools
    install_homebrew
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv 2>/dev/null || true)"
    install_brew_tools
    install_python_node_envs

    ;;
  *)
    fail "Unsupported platform: $PLATFORM"
    ;;
esac

success "All essential tools installed. You’re good to go!"

