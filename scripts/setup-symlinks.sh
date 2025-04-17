#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                 🔗 Dotfile Symlink Setup                   │
# ╰────────────────────────────────────────────────────────────╯
# Checks and creates symlinks for tracked dotfiles

set -e

# ── Logging ───────────────────────────────────────────────────
info()    { echo -e "\033[1;34mℹ️  $1\033[0m"; }
success() { echo -e "\033[1;32m✅ $1\033[0m"; }
warn()    { echo -e "\033[1;33m⚠️  $1\033[0m"; }
fail()    { echo -e "\033[1;31m❌ $1\033[0m"; }
created() { echo -e "\033[1;35m📁 Created directory: $1\033[0m"; }
touched() { echo -e "\033[1;36m📄 Created file: $1\033[0m"; }
divider() { echo -e "\033[2m──────────────────────────────────────────────\033[0m"; }

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
  ["~/.config/lsd/config.yaml"]="~/.dotfiles/.config/lsd/config.yaml"
  ["~/.config/yazi"]="~/.dotfiles/.config/yazi"
  ["~/.config/gh/config.yml"]="~/.dotfiles/.config/gh/config.yml"
  ["~/.config/lazygit/config.yml"]="~/.dotfiles/.config/lazygit/config.yml"
)

# ── Main ──────────────────────────────────────────────────────
echo -e "\n\033[1;36m🔗 Initializing Dotfile Symlink Setup...\033[0m"

for target in "${!SYMLINKS[@]}"; do
  link_dotfile "$target" "${SYMLINKS[$target]}"
done

info "Symlinks checked, fixed, and ready."
