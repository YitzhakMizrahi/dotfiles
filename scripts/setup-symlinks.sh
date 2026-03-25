#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                 🔗 Dotfile Symlink Setup                   │
# ╰────────────────────────────────────────────────────────────╯
# Checks and creates symlinks for tracked dotfiles

set -e

source "$(dirname "$0")/lib/logging.sh"

resolve_path() {
  echo "$(eval echo $1)"
}

link_dotfile() {
  local target=$(resolve_path "$1")
  local source=$(resolve_path "$2")
  local target_dir=$(dirname "$target")
  local source_dir=$(dirname "$source")

  echo -e "\n🕓 Checking $target..."

  while true; do
    if [[ ! -e "$source" && ! -L "$source" ]]; then
      warn "Source missing: $source"
      mkdir -p "$source_dir" && created "$source_dir"
      touch "$source" && touched "$source"
      continue
    fi

    if [[ -L "$target" ]]; then
      actual_link="$(readlink "$target")"
      if [[ "$actual_link" != "$source" ]]; then
        warn "Incorrect link. Removing: $target"
        rm -f "$target"
        continue
      fi
    elif [[ -e "$target" ]]; then
      warn "Target exists and is not a symlink. Skipping."
      break
    fi

    if [[ ! -L "$target" ]]; then
      mkdir -p "$target_dir" && created "$target_dir"
      ln -nsf "$source" "$target" && echo -e "\033[1;36m🔗 Linked: $target → $source\033[0m" || fail "Failed to link $target"
      continue
    fi

    success "OK: $target → $source"
    break
  done

  divider
}

# ── Symlink Targets ───────────────────────────────────────────
declare -A SYMLINKS=(
  ["~/.zshrc"]="~/.dotfiles/.zshrc"
  ["~/.tmux.conf"]="~/.dotfiles/.tmux.conf"
  ["~/.gitconfig"]="~/.dotfiles/.gitconfig"
  ["~/.config/starship.toml"]="~/.dotfiles/.config/starship.toml"
  ["~/.config/yazi"]="~/.dotfiles/.config/yazi"
  ["~/.config/lsd/config.yaml"]="~/.dotfiles/.config/lsd/config.yaml"
  ["~/.config/gh/config.yml"]="~/.dotfiles/.config/gh/config.yml"
  ["~/.config/lazygit/config.yml"]="~/.dotfiles/.config/lazygit/config.yml"
  ["~/bin/vault-open"]="~/.dotfiles/bin/vault-open"
  ["~/bin/vault-close"]="~/.dotfiles/bin/vault-close"
  ["~/bin/lxc-dev"]="~/.dotfiles/bin/lxc-dev"
)

# ── Main ──────────────────────────────────────────────────────
echo -e "\n\033[1;36m🔗 Initializing Dotfile Symlink Setup...\033[0m"

for target in "${!SYMLINKS[@]}"; do
  link_dotfile "$target" "${SYMLINKS[$target]}"
done

info "Symlinks checked, fixed, and ready."
