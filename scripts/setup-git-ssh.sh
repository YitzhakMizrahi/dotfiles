#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │            🔐 Git Identity and SSH Key Setup               │
# ╰────────────────────────────────────────────────────────────╯
# Configures Git user info and SSH key basics

set -e

source "$(dirname "$0")/lib/logging.sh"

# ── Ensure ~/.gitconfig.local exists ─────────────────────────
GITCONFIG_LOCAL="$HOME/.gitconfig.local"
if [[ ! -f "$GITCONFIG_LOCAL" ]]; then
  info "Creating $GITCONFIG_LOCAL for user config..."
  touch "$GITCONFIG_LOCAL"
  success "Created $GITCONFIG_LOCAL."
else
  info "$GITCONFIG_LOCAL already exists."
  echo "Current Git identity configuration:"
  grep -E "name =|email =" "$GITCONFIG_LOCAL" || echo "(none found)"
  echo -n $'\nUpdate Git identity? [y/N]: '
  read -r update_git
  if [[ "$update_git" =~ ^[Yy]$ ]]; then
    sed -i '/\[user\]/,/^\s*\[.*\]/d' "$GITCONFIG_LOCAL"
  fi
fi

# ── Prompt for Git identity ──────────────────────────────────
if ! grep -q "name =" "$GITCONFIG_LOCAL"; then
  echo -n "Enter your Git user name: "; read -r git_name
  echo "[user]" >> "$GITCONFIG_LOCAL"
  echo "  name = $git_name" >> "$GITCONFIG_LOCAL"
fi

if ! grep -q "email =" "$GITCONFIG_LOCAL"; then
  echo -n "Enter your Git email: "; read -r git_email
  if ! grep -q "\[user\]" "$GITCONFIG_LOCAL"; then
    echo "[user]" >> "$GITCONFIG_LOCAL"
  fi
  echo "  email = $git_email" >> "$GITCONFIG_LOCAL"
fi
success "Git identity saved to $GITCONFIG_LOCAL."

# ── SSH Key Check ────────────────────────────────────────────
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

mapfile -t SSH_KEYS < <(find "$HOME/.ssh" -maxdepth 1 -type f -name "id_ed25519*" ! -name "*.pub" 2>/dev/null)

if [[ ${#SSH_KEYS[@]} -eq 0 ]]; then
  warn "No SSH private keys found in ~/.ssh."
  echo -n "Would you like to generate a new SSH key? [Y/n]: "; read -r create_key
  if [[ ! "$create_key" =~ ^[Nn]$ ]]; then
    echo -n "Enter a label for your new key (e.g. personal-laptop): "; read -r label
    label_cleaned=$(echo "$label" | tr -cd '[:alnum:]_-')
    KEY_PATH="$HOME/.ssh/id_ed25519_$label_cleaned"
    ssh-keygen -t ed25519 -C "$label" -f "$KEY_PATH"
    eval "$(ssh-agent -s)"
    ssh-add "$KEY_PATH"
    success "New SSH key generated and added: $(basename "$KEY_PATH")"
  else
    warn "SSH key creation skipped."
  fi
else
  info "SSH private key(s) found in ~/.ssh:"
  for key in "${SSH_KEYS[@]}"; do
    echo "  - $(basename "$key")"
  done
  echo
fi

# ── Completion Message ───────────────────────────────────────
success "🛡️ Git identity and SSH setup complete!"

warn "To upload SSH key(s) to GitHub:"
echo "  1. Run: gh auth login"
echo "  2. Then: gh ssh-key add ~/.ssh/your_key.pub --title \"your-device-name\""
