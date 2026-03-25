#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                   Dotfiles Installer                       │
# ╰────────────────────────────────────────────────────────────╯
# Thin orchestrator: Homebrew → Brewfile → mise → symlinks → shell

set -e

source "$(dirname "$0")/lib/ui.sh"

# ── Root Check ────────────────────────────────────────────────
if [[ "$EUID" -eq 0 ]]; then
  ui_fail "Please do not run as root."
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

banner "Dotfiles Installer" "$PLATFORM · $(uname -m)"

# ── 1. Install APT Base Tools (Linux/WSL only) ───────────────
install_apt_base() {
  if [[ "$PLATFORM" == "macos" ]]; then
    return 0
  fi
  sudo apt-get update -y
  sudo apt-get install -y git zsh tmux curl wget build-essential gocryptfs
}

# ── 2. Install Homebrew ───────────────────────────────────────
install_homebrew() {
  if command -v brew &>/dev/null; then
    ui_success "Homebrew already installed"
    return 0
  fi

  ui_info "Installing Homebrew..."
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

  ui_success "Homebrew installed"
}

# ── 3. Brew Bundle ────────────────────────────────────────────
install_brew_tools() {
  if ! command -v brew &>/dev/null; then
    ui_warn "Homebrew not found — skipping brew bundle"
    return 0
  fi
  brew bundle --file="$DOTFILES_DIR/Brewfile"
}

# ── 4. mise Install ──────────────────────────────────────────
install_runtimes() {
  if ! command -v mise &>/dev/null; then
    ui_warn "mise not found — skipping runtime installation"
    return 0
  fi
  export MISE_GLOBAL_CONFIG_FILE="$DOTFILES_DIR/.mise.toml"
  mise install --yes
}

# ── Install Flow ─────────────────────────────────────────────

section "System Packages"

if [[ "$PLATFORM" != "macos" ]]; then
  step "APT base tools" install_apt_base
fi
install_homebrew

# Ensure Homebrew is on PATH for brew bundle
if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Re-detect gum after brew bundle (it was just installed)
step "Brew bundle" install_brew_tools
if [[ "$DOTFILES_CI" -eq 0 ]] && command -v gum &>/dev/null; then
  HAS_GUM=1
fi

step "Language runtimes (mise)" install_runtimes

section "Configuration"

step "Dotfile symlinks" bash "$DOTFILES_DIR/scripts/setup-symlinks.sh"
step "Font setup" bash "$DOTFILES_DIR/scripts/setup-fonts.sh"

section "Shell & Identity"

# Interactive scripts — run directly, no spinner
bash "$DOTFILES_DIR/scripts/setup-shell.sh"
bash "$DOTFILES_DIR/scripts/setup-git-ssh.sh"

section "Validation"

if [[ -f "$DOTFILES_DIR/scripts/post-cleanup.sh" ]]; then
  step "Post-install cleanup" bash "$DOTFILES_DIR/scripts/post-cleanup.sh"
fi
if [[ -f "$DOTFILES_DIR/scripts/post-validate.sh" ]]; then
  bash "$DOTFILES_DIR/scripts/post-validate.sh"
fi

# ── Legacy Runtime Cleanup ─────────────────────────────────────
LEGACY_DIRS=("$HOME/.pyenv" "$HOME/.nvm" "$HOME/.goenv")
FOUND_LEGACY=()
for dir in "${LEGACY_DIRS[@]}"; do
  [[ -d "$dir" ]] && FOUND_LEGACY+=("$dir")
done

if [[ ${#FOUND_LEGACY[@]} -gt 0 ]] && command -v mise &>/dev/null; then
  echo
  ui_warn "Legacy runtime managers detected:"
  for dir in "${FOUND_LEGACY[@]}"; do
    echo "    $(basename "$dir")  →  $dir"
  done
  echo
  ui_info "mise is now managing your runtimes (Python, Node, Go, Rust)."
  if ui_confirm "Remove legacy runtime directories?"; then
    for dir in "${FOUND_LEGACY[@]}"; do
      rm -rf "$dir"
      ui_success "Removed $dir"
    done
  else
    ui_info "Kept legacy dirs. You can remove them later manually."
  fi
fi

# ── Offer Shell Restart ───────────────────────────────────────
echo
if ui_confirm "Install complete! Restart shell?"; then
  if command -v zsh >/dev/null 2>&1; then
    exec zsh
  else
    exec bash
  fi
else
  ui_info "Run 'source ~/.zshrc' to apply changes."
fi
