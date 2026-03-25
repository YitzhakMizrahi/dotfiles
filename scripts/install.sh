#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                   Dotfiles Installer                       │
# ╰────────────────────────────────────────────────────────────╯
# Thin orchestrator: Homebrew → Brewfile → mise → symlinks → shell

set -e

source "$(dirname "$0")/lib/logging.sh"

# ── Root Check ────────────────────────────────────────────────
if [[ "$EUID" -eq 0 ]]; then
  fail "Please do not run as root."
fi

DOTFILES_DIR="$HOME/.dotfiles"
chmod +x "$DOTFILES_DIR/scripts/"*.sh 2>/dev/null || true
chmod +x "$DOTFILES_DIR/bin/"* 2>/dev/null || true

# ── Platform Detection ────────────────────────────────────────
detect_platform() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macos"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if grep -qi microsoft /proc/version 2>/dev/null; then
      echo "wsl"
    else
      echo "linux"
    fi
  else
    echo "unknown"
  fi
}

PLATFORM=$(detect_platform)
info "Detected platform: $PLATFORM"

# ── Step Runner ───────────────────────────────────────────────
run_step() {
  local script="$1"
  local label="$2"
  if [[ -f "$DOTFILES_DIR/scripts/$script" ]]; then
    info "$label..."
    bash "$DOTFILES_DIR/scripts/$script"
    success "$label complete."
  else
    warn "$label script not found: $script"
  fi
  echo
}

# ── 1. Install Homebrew ───────────────────────────────────────
install_homebrew() {
  if command -v brew &>/dev/null; then
    success "Homebrew already installed."
    return 0
  fi

  info "Installing Homebrew..."
  NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Activate Homebrew in current session
  if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
    eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
  elif [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  success "Homebrew installed."
}

# ── 2. Install APT Base Tools (Linux/WSL only) ───────────────
install_apt_base() {
  if [[ "$PLATFORM" == "macos" ]]; then
    return 0
  fi

  info "Installing base tools via APT..."
  sudo apt update -y
  sudo apt install -y git zsh tmux curl wget build-essential gocryptfs
  success "APT base tools installed."
}

# ── 3. Brew Bundle ────────────────────────────────────────────
install_brew_tools() {
  if ! command -v brew &>/dev/null; then
    warn "Homebrew not found. Skipping brew bundle."
    return 0
  fi

  info "Installing tools from Brewfile..."
  brew bundle --file="$DOTFILES_DIR/Brewfile" --no-lock
  success "Brew tools installed."
}

# ── 4. mise Install ──────────────────────────────────────────
install_runtimes() {
  if ! command -v mise &>/dev/null; then
    warn "mise not found. Skipping runtime installation."
    return 0
  fi

  info "Installing language runtimes via mise..."
  export MISE_GLOBAL_CONFIG_FILE="$DOTFILES_DIR/.mise.toml"
  mise install --yes
  success "Language runtimes installed."
}

# ── Install Flow ─────────────────────────────────────────────
install_apt_base
install_homebrew

# Ensure Homebrew is on PATH for brew bundle
if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

install_brew_tools
install_runtimes
echo

run_step "setup-symlinks.sh"   "Setting up dotfile symlinks"
run_step "setup-fonts.sh"      "Checking/installing fonts"
run_step "setup-shell.sh"      "Configuring shell (Zsh, Zinit)"
run_step "setup-git-ssh.sh"    "Git identity and SSH setup"
run_step "post-cleanup.sh"     "Post-install cleanup"
run_step "post-validate.sh"    "Running post-install validation"

# ── Offer Shell Restart ───────────────────────────────────────
echo
read -p $'Install complete! Restart shell to apply changes? [Y/n]: ' restart
restart=${restart:-Y}
if [[ "$restart" =~ ^[Yy]$ ]]; then
  if command -v zsh >/dev/null 2>&1; then
    exec zsh
  else
    exec bash
  fi
else
  info "You can run 'source ~/.zshrc' manually to apply changes."
fi
