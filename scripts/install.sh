#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                   Dotfiles Installer                       │
# ╰────────────────────────────────────────────────────────────╯
# Thin orchestrator: Homebrew → Brewfile → mise → symlinks → shell

set -e

source "$(dirname "$0")/lib/ui.sh"
source "$(dirname "$0")/lib/paths.sh"
source "$(dirname "$0")/lib/brew.sh"

# ── Root Check ────────────────────────────────────────────────
if [[ "$EUID" -eq 0 ]]; then
  ui_fail "Please do not run as root."
fi
chmod +x "$DOTFILES_DIR/scripts/"*.sh "$DOTFILES_DIR/scripts/"**/*.sh 2>/dev/null || true
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

# ── Welcome ──────────────────────────────────────────────────
banner "Dotfiles Installer" "$PLATFORM · $(uname -m)"

echo "  This will install and configure:"
echo "    • System packages (APT + Homebrew)"
echo "    • CLI tools (bat, fzf, ripgrep, lsd, etc.)"
echo "    • Language runtimes (Python, Node, Go, Rust)"
echo "    • Shell config (Zsh + Zinit + Starship)"
echo "    • Git identity & SSH keys"
echo

if ! ui_confirm "Proceed with installation?" "yes"; then
  ui_info "Installation cancelled."
  exit 0
fi

# Initialize install log
ui_log_init
ui_info "Logging to $DOTFILES_LOG"
echo

_timer_start
INSTALL_START=$_TIMER_START

# ── Install Homebrew ─────────────────────────────────────────
install_homebrew() {
  if command -v brew &>/dev/null; then
    ui_success "Homebrew already installed"
    return 0
  fi

  _log_header "Homebrew install"
  if [[ "$HAS_GUM" -eq 1 ]]; then
    gum spin --spinner dot --title "Installing Homebrew..." -- \
      bash -c 'NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >> "'"$DOTFILES_LOG"'" 2>&1'
  else
    ui_info "Installing Homebrew..."
    NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >> "$DOTFILES_LOG" 2>&1
  fi

  # Activate Homebrew in current session
  brew_ensure_path

  ui_success "Homebrew installed"
}

# ── Install Flow ─────────────────────────────────────────────

timed_section "System Packages"

if [[ "$PLATFORM" != "macos" ]]; then
  step "APT update" sudo apt-get update -y
  step "APT base tools" sudo apt-get install -y git zsh tmux curl wget unzip build-essential gocryptfs
fi
install_homebrew

# Ensure Homebrew is on PATH
brew_ensure_path

# Install gum first for polished UI in remaining steps
if [[ "$DOTFILES_CI" -eq 0 ]] && command -v brew &>/dev/null && ! command -v gum &>/dev/null; then
  ui_info "Installing gum for UI..."
  brew install gum >> "$DOTFILES_LOG" 2>&1
  if command -v gum &>/dev/null; then
    HAS_GUM=1
    ui_success "gum ready"
  fi
fi

# Brew bundle — show each package as it installs
_log_header "Brew bundle"
ui_info "Installing Homebrew packages..."
set -o pipefail
brew bundle --file="$DOTFILES_DIR/Brewfile" 2>&1 | while IFS= read -r line; do
  echo "$line" >> "$DOTFILES_LOG"
  if [[ "$line" == Installing* ]]; then
    echo -e "  ${_C_GREEN}✓${_C_RESET} $line"
  elif [[ "$line" == *"already installed"* || "$line" == Using* ]]; then
    echo -e "  ${_C_GRAY}· ${line}${_C_RESET}"
  fi
done
set +o pipefail
ui_success "Brew bundle complete"

# mise — run directly since it needs shell env
if command -v mise &>/dev/null; then
  step "Language runtimes (mise)" mise install --yes || true
else
  ui_warn "mise not found — skipping runtime installation"
fi

timed_section "Configuration"

step "Dotfile symlinks" bash "$DOTFILES_DIR/scripts/setup/symlinks.sh"

# Zinit install (automated — no user interaction)
if [[ -d "$ZINIT_HOME" ]]; then
  ui_success "Zinit already installed"
else
  step "Zinit plugin manager" git clone --depth 1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Pre-download Zinit plugins (needs .zshrc symlink + TTY, no gum spin)
if command -v zsh >/dev/null 2>&1 && [[ -d "$ZINIT_HOME" ]]; then
  ui_info "Pre-downloading Zinit plugins..."
  zsh -ic "exit" || true
  ui_success "Zinit plugins ready"
fi

timed_section "Validation"

if [[ -f "$DOTFILES_DIR/scripts/doctor.sh" ]]; then
  bash "$DOTFILES_DIR/scripts/doctor.sh"
fi

timed_section_end

# ── Personalization (interactive — not timed) ──────────────────
section "Personalization"
echo

# Default shell
bash "$DOTFILES_DIR/scripts/setup/shell.sh"

# Fonts
bash "$DOTFILES_DIR/scripts/setup/fonts.sh" || true

# Git identity & SSH keys
bash "$DOTFILES_DIR/scripts/setup/git-ssh.sh"

# Legacy runtime cleanup
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

# ── Done ──────────────────────────────────────────────────────
_TIMER_START=$INSTALL_START
echo
ui_success "Installation complete in $(_timer_elapsed)"
echo
if ui_confirm "Restart shell?"; then
  if command -v zsh >/dev/null 2>&1; then
    exec zsh
  else
    exec bash
  fi
else
  ui_info "Run 'source ~/.zshrc' to apply changes."
fi
