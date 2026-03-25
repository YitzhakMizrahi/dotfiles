#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                🧠 Dotfiles Installer                           │
# ╰────────────────────────────────────────────────────────────╯
# Delegates setup to modular scripts for better structure 🛠️

set -e

source "$(dirname "$0")/lib/logging.sh"

# ── Root Check ────────────────────────────────────────────────
if [[ "$EUID" -eq 0 ]]; then
  fail "Please do not run as root."
fi

# ── Ensure Executables ────────────────────────────────────────
DOTFILES_DIR="$HOME/.dotfiles"
chmod +x "$DOTFILES_DIR/scripts/"*.sh || true
chmod +x "$DOTFILES_DIR/bin/"* || true

# ── Modular Scripts ───────────────────────────────────────────
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

# ── Install Flow ─────────────────────────────────────────────
run_step "setup-symlinks.sh"   "🔗 Setting up dotfile symlinks"
run_step "install-tools.sh"    "📦 Installing dev tools"
run_step "setup-fonts.sh"      "🔤 Checking/installing fonts"
run_step "setup-shell.sh"      "💻 Configuring shell (Zsh, Starship, etc)"
run_step "setup-languages.sh"  "🐍 Installing Python/Node environments"
run_step "setup-git-ssh.sh"    "🔐 Git identity and SSH setup"
run_step "post-cleanup.sh"     "🧹 Optional cleanup"
run_step "post-validate.sh"    "✅ Running post-install validation"

# ── Offer Shell Restart ───────────────────────────────────────
echo
read -p $'🔄 Install complete! Restart shell to apply changes? [Y/n]: ' restart
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
