#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │              Git Identity and SSH Key Setup                │
# ╰────────────────────────────────────────────────────────────╯
# Configures Git user info and SSH key basics

set -e

source "$(dirname "$0")/../lib/ui.sh"
source "$(dirname "$0")/../lib/paths.sh"

# ── Check if already fully configured ────────────────────────
GIT_CONFIGURED=false
SSH_CONFIGURED=false

if [[ -f "$GITCONFIG_LOCAL" ]] && grep -q "name =" "$GITCONFIG_LOCAL" && grep -q "email =" "$GITCONFIG_LOCAL"; then
  GIT_CONFIGURED=true
fi

mapfile -t SSH_KEYS < <(find "$HOME/.ssh" -maxdepth 1 -type f -name "id_ed25519*" ! -name "*.pub" 2>/dev/null)
if [[ ${#SSH_KEYS[@]} -gt 0 ]]; then
  SSH_CONFIGURED=true
fi

# If both are configured, show status and offer to reconfigure
if [[ "$GIT_CONFIGURED" == true && "$SSH_CONFIGURED" == true ]]; then
  ui_success "Git identity already configured:"
  grep -E "name =|email =" "$GITCONFIG_LOCAL" 2>/dev/null | sed 's/^/    /'
  echo
  ui_success "SSH key(s) found:"
  for key in "${SSH_KEYS[@]}"; do
    echo "    $(basename "$key")"
  done
  echo
  if ! ui_confirm "Reconfigure Git/SSH?"; then
    ui_info "Kept existing configuration."
    exit 0
  fi
fi

# ── Ensure ~/.gitconfig.local exists ─────────────────────────
if [[ ! -f "$GITCONFIG_LOCAL" ]]; then
  ui_info "Creating $GITCONFIG_LOCAL for user config..."
  touch "$GITCONFIG_LOCAL"
  ui_success "Created $GITCONFIG_LOCAL"
elif [[ "$GIT_CONFIGURED" == true ]]; then
  # User chose to reconfigure — clear the user section
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' '/\[user\]/,/^\s*\[.*\]/d' "$GITCONFIG_LOCAL"
  else
    sed -i '/\[user\]/,/^\s*\[.*\]/d' "$GITCONFIG_LOCAL"
  fi
fi

# ── Prompt for Git identity ──────────────────────────────────
if ! grep -q "name =" "$GITCONFIG_LOCAL"; then
  git_name=$(ui_input "Git user name:" "John Doe")
  echo "[user]" >> "$GITCONFIG_LOCAL"
  echo "  name = $git_name" >> "$GITCONFIG_LOCAL"
fi

if ! grep -q "email =" "$GITCONFIG_LOCAL"; then
  git_email=$(ui_input "Git email:" "you@example.com")
  if ! grep -q "\[user\]" "$GITCONFIG_LOCAL"; then
    echo "[user]" >> "$GITCONFIG_LOCAL"
  fi
  echo "  email = $git_email" >> "$GITCONFIG_LOCAL"
fi
ui_success "Git identity saved to $GITCONFIG_LOCAL"

# ── SSH Key Check ────────────────────────────────────────────
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Re-check in case user is reconfiguring
mapfile -t SSH_KEYS < <(find "$HOME/.ssh" -maxdepth 1 -type f -name "id_ed25519*" ! -name "*.pub" 2>/dev/null)

if [[ ${#SSH_KEYS[@]} -eq 0 ]]; then
  ui_warn "No SSH private keys found in ~/.ssh"
  if ui_confirm "Generate a new SSH key?"; then
    label=$(ui_input "Key label:" "personal-laptop")
    label_cleaned=$(echo "$label" | tr -cd '[:alnum:]_-')
    KEY_PATH="$HOME/.ssh/id_ed25519_$label_cleaned"
    ssh-keygen -t ed25519 -C "$label" -f "$KEY_PATH"
    eval "$(ssh-agent -s)"
    ssh-add "$KEY_PATH"
    ui_success "New SSH key generated and added: $(basename "$KEY_PATH")"
  else
    ui_warn "SSH key creation skipped"
  fi
else
  ui_info "SSH private key(s) found in ~/.ssh:"
  for key in "${SSH_KEYS[@]}"; do
    echo "    $(basename "$key")"
  done
  echo
fi

# ── Completion ───────────────────────────────────────────────
ui_success "Git identity and SSH setup complete"
echo
ui_info "To upload SSH key(s) to GitHub:"
echo "    gh auth login"
echo "    gh ssh-key add ~/.ssh/your_key.pub --title \"your-device-name\""
