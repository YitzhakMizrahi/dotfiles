#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                 🔗 Dotfile Symlink Checker                 │
# ╰────────────────────────────────────────────────────────────╯
# Smartly resolves all symlinks in one pass — with retries 🌀

# ── Symlink Targets ──────────────────────────────────────────
declare -A SYMLINKS=(
  ["~/.zshrc"]="~/.dotfiles/.zshrc"
  ["~/.tmux.conf"]="~/.dotfiles/.tmux.conf"
  ["~/.gitconfig"]="~/.dotfiles/.gitconfig"
  ["~/.config/lsd/config.yaml"]="~/.dotfiles/.config/lsd/config.yaml"
  ["~/.config/yazi"]="~/.dotfiles/.config/yazi"
  ["~/.config/gh/config.yml"]="~/.dotfiles/.config/gh/config.yml"
  ["~/.config/lazygit/config.yml"]="~/.dotfiles/.config/lazygit/config.yml"
)

# ── Log Helpers ──────────────────────────────────────────────
info()    { echo -e "\033[1;34m📘 $1\033[0m"; }
success() { echo -e "\033[1;32m👌 $1\033[0m"; }
created() { echo -e "\033[1;36m📁 Created directory: $1\033[0m"; }
touched() { echo -e "\033[1;36m🖍️ Created file: $1\033[0m"; }
linked()  { echo -e "\033[1;36m🔗 Linked: $1 → $2\033[0m"; }
warn()    { echo -e "\033[1;33m⚠️  $1\033[0m"; }
fail()    { echo -e "\033[1;31m❌ $1\033[0m"; }
divider() { echo -e "\033[2m$(printf '%*s' 50 '' | tr ' ' ─)\033[0m"; }

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
    # Step 1: Fix missing source
    if [[ ! -e "$source" && ! -L "$source" ]]; then
      warn "Source missing: $source"
      mkdir -p "$source_dir" && created "$source_dir"
      touch "$source"
      if [[ $? -eq 0 ]]; then
        touched "$source"
      else
        fail "Failed to create source file: $source"
      fi
      continue
    fi

    # Step 2: Fix broken or incorrect target
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

    # Step 3: Create symlink if missing
    if [[ ! -L "$target" ]]; then
      mkdir -p "$target_dir" && created "$target_dir"
      ln -nsf "$source" "$target" && linked "$target" "$source" || fail "Failed to link $target"
      continue
    fi

    # Step 4: Final confirmation
    success "OK: $target → $source"
    break
  done

  divider
}

# ── Main ────────────────────────────────────────────────────
echo -e "\n\033[1;36m🔗 Initializing Dotfile Symlink Setup...\033[0m"
for target in "${!SYMLINKS[@]}"; do
  link_dotfile "$target" "${SYMLINKS[$target]}"
done
info "All done. Symlinks checked, fixed, and ready."
