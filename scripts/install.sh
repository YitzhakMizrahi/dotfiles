#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                   Dotfiles Installer                       │
# ╰────────────────────────────────────────────────────────────╯
# Thin orchestrator: Homebrew → Brewfile → mise → symlinks → shell

set -e

source "$(dirname "$0")/lib/ui.sh"
source "$(dirname "$0")/lib/paths.sh"
source "$(dirname "$0")/lib/brew.sh"
source "$(dirname "$0")/lib/platform.sh"
source "$(dirname "$0")/lib/tools.sh"

# ── Root Check ────────────────────────────────────────────────
if [[ "$EUID" -eq 0 ]]; then
  ui_fail "Please do not run as root."
fi
chmod +x "$DOTFILES_DIR/scripts/"*.sh "$DOTFILES_DIR/scripts/"**/*.sh 2>/dev/null || true
chmod +x "$DOTFILES_DIR/bin/"* 2>/dev/null || true

# ── Platform Detection ────────────────────────────────────────
PLATFORM=$(detect_platform)
DISTRO=$(detect_distro_family)
PM=$(pkg_manager_name)

# Immutable Fedora: bail early — the host is read-only.
if is_silverblue; then
  echo
  ui_warn "Immutable Fedora (Silverblue/Kinoite/Bluefin) detected."
  echo "    The host filesystem is read-only — this installer won't work here."
  echo "    Run it inside a mutable container with toolbox or distrobox:"
  echo
  echo "      toolbox create --distro fedora"
  echo "      toolbox enter"
  echo "      bash ~/.dotfiles/scripts/install.sh"
  echo
  exit 1
fi

# ── Welcome ──────────────────────────────────────────────────
DISTRO_PRETTY=$(detect_distro_pretty)
[[ "$PLATFORM" == "wsl" ]] && DISTRO_PRETTY="$DISTRO_PRETTY (WSL)"
banner "Dotfiles Installer" "$DISTRO_PRETTY · $(uname -m)"

if [[ "$PLATFORM" == "macos" ]]; then
  pkg_welcome="Homebrew"
else
  pkg_welcome="${PM} + Homebrew"
fi

BREW_COUNT=$(brewfile_formulas "$DOTFILES_DIR/Brewfile" | wc -l | tr -d ' ')
MISE_COUNT=$(mise_runtimes "$DOTFILES_DIR/.mise.toml" | wc -l | tr -d ' ')
MISE_LIST=$(mise_runtimes "$DOTFILES_DIR/.mise.toml" | paste -sd, - | sed 's/,/, /g')

echo "  This will install and configure:"
echo "    • System packages ($pkg_welcome)"
echo "    • CLI tools ($BREW_COUNT from Brewfile)"
echo "    • Language runtimes ($MISE_COUNT: $MISE_LIST)"
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

# ── Sudo keepalive ────────────────────────────────────────────
# Prime sudo once up-front and refresh the timestamp in the
# background, so long-running steps don't re-prompt mid-install.
_needs_sudo=0
if [[ "$PLATFORM" != "macos" ]] || ! command -v brew &>/dev/null; then
  _needs_sudo=1
fi
if [[ "$_needs_sudo" -eq 1 ]] && command -v sudo &>/dev/null; then
  ui_info "Priming sudo (you'll be asked once)..."
  if sudo -v; then
    ( while sleep 50; do sudo -n true 2>/dev/null || exit; kill -0 "$$" 2>/dev/null || exit; done ) &
    __SUDO_KEEPALIVE_PID=$!
    trap '[[ -n "${__SUDO_KEEPALIVE_PID:-}" ]] && kill "$__SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT
  else
    ui_fail "sudo authentication failed"
  fi
  echo
fi

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
  if [[ "$DISTRO" == "unknown" ]]; then
    echo
    echo "    Detected: $(describe_os_release)"
    echo "    Supported families: debian (Debian/Ubuntu), fedora (Fedora/RHEL/CentOS)"
    echo "    To add support, extend detect_distro_family in scripts/lib/platform.sh"
    echo
    ui_fail "Unsupported distro — /etc/os-release did not match any supported family."
  fi
  step "${PM}: refresh package lists" pkg_refresh_lists
  step "${PM}: install base tools"    install_base_tools
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
  if [[ "$line" == *Installing* ]]; then
    echo -e "  ${_C_GREEN}✓${_C_RESET} $line"
  elif [[ "$line" == *"already installed"* || "$line" == *Using* ]]; then
    echo -e "  ${_C_GRAY}· ${line}${_C_RESET}"
  fi
done
set +o pipefail
ui_success "Brew bundle complete"

# mise — run directly since it needs shell env
# macOS ARM prebuilt Python binaries have a broken directory layout in mise;
# compile from source on macOS until upstream fixes it.
if [[ "$OSTYPE" == "darwin"* ]]; then
  export MISE_PYTHON_COMPILE=1
fi
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
section_summary
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
