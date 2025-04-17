#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                🧠 Dotfiles Bootstrap Launcher                │
# ╰────────────────────────────────────────────────────────────╯
# Delegates setup to modular scripts for better structure 🛠️

set -e

# ── Logging ───────────────────────────────────────────────────
info()    { echo -e "\033[1;34mℹ️  $1\033[0m"; }
success() { echo -e "\033[1;32m✅ $1\033[0m"; }
warn()    { echo -e "\033[1;33m⚠️  $1\033[0m"; }
fail()    { echo -e "\033[1;31m❌ $1\033[0m"; exit 1; }

# ── Root Check ────────────────────────────────────────────────
if [[ "$EUID" -eq 0 ]]; then
  fail "Please do not run as root."
fi

# ── Ensure Executables ────────────────────────────────────────
DOTFILES_DIR="$HOME/.dotfiles"
chmod +x "$DOTFILES_DIR/scripts/"*.sh || true

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

# ── Bootstrap Flow ────────────────────────────────────────────
run_step "setup-symlinks.sh"   "🔗 Setting up dotfile symlinks"
run_step "install-tools.sh"    "📦 Installing dev tools"
run_step "setup-fonts.sh"      "🔤 Checking/installing fonts"
run_step "setup-shell.sh"      "💻 Configuring shell (Zsh, Starship, etc)"
run_step "setup-languages.sh"  "🐍 Installing Python/Node environments"
run_step "setup-git-ssh.sh"    "🔐 Git identity and SSH setup"
run_step "post-cleanup.sh"     "🧹 Optional cleanup"
run_step "post-checks.sh"      "✅ Running post-install validation"

# ── Offer Shell Restart ───────────────────────────────────────
echo
read -p $'🔄 Bootstrap complete! Restart shell to apply changes? [Y/n]: ' restart
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
