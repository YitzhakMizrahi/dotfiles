#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                   🛠️ Dotfiles Install Script                   │
# ╰────────────────────────────────────────────────────────────╯
# Run this script after cloning your dotfiles to set up symlinks,
# permissions, paths, and optional tools.

# ── Logging Helpers ──────────────────────────────────────────
info()    { echo -e "\033[1;34mℹ️  $1\033[0m"; }
success() { echo -e "\033[1;32m✅ $1\033[0m"; }
warn()    { echo -e "\033[1;33m⚠️  $1\033[0m"; }
fail()    { echo -e "\033[1;31m❌ $1\033[0m"; }

# ── Step 1: Ensure Scripts Are Executable ────────────────────
info "Making dotfiles scripts executable..."
find "$HOME/.dotfiles/scripts" -type f -name "*.sh" -exec chmod +x {} \;
success "Scripts marked as executable."

# ── Step 2: Ensure PATH includes scripts ─────────────────────
if ! grep -q 'PATH=.*.dotfiles/scripts' "$HOME/.zshrc"; then
  echo 'export PATH="$HOME/.dotfiles/scripts:$PATH"' >> "$HOME/.zshrc"
  success "Appended scripts path to .zshrc"
else
  info "Scripts path already in .zshrc"
fi

# ── Step 3: Run Symlink Check Script ─────────────────────────
if [[ -f "$HOME/.dotfiles/scripts/check-and-link-dotfiles.sh" ]]; then
  "$HOME/.dotfiles/scripts/check-and-link-dotfiles.sh"
else
  warn "check-and-link-dotfiles.sh not found!"
fi

# ── Step 4: Optional Tool Notices ─────────────────────────────
info "Checking optional tools..."
for tool in gh yazi lazygit; do
  if command -v "$tool" &>/dev/null; then
    success "$tool is installed."
  else
    warn "$tool is not installed. You can install it later if needed."
  fi
done

info "Install script finished. You may want to restart your shell."
