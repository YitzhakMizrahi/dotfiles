#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                  Dotfile Symlink Setup                     │
# ╰────────────────────────────────────────────────────────────╯
# Checks and creates symlinks for tracked dotfiles

set -e

source "$(dirname "$0")/../lib/ui.sh"

resolve_path() {
  echo "${1/#\~/$HOME}"
}

link_dotfile() {
  local target
  local source
  target=$(resolve_path "$1")
  source=$(resolve_path "$2")

  # Source must exist in the repo — if it doesn't, that's a real problem
  if [[ ! -e "$source" ]]; then
    ui_warn "Source missing: $source — skipping"
    return 0
  fi

  # Target is already a correct symlink
  if [[ -L "$target" ]]; then
    local actual_link
    actual_link="$(readlink "$target")"
    if [[ "$actual_link" == "$source" ]]; then
      ui_success "OK: $target"
      return 0
    fi
    ui_warn "Incorrect link — fixing: $target"
    rm -f "$target"
  elif [[ -e "$target" ]]; then
    ui_warn "Target exists and is not a symlink: $target — skipping"
    return 0
  fi

  # Create parent directory and symlink
  mkdir -p "$(dirname "$target")"
  ln -sf "$source" "$target"
  ui_success "Linked: $target → $source"
}

# ── Symlink Targets ───────────────────────────────────────────
# Format: "target|source" — one pair per line
SYMLINKS=(
  "~/.zshrc|~/.dotfiles/.zshrc"
  "~/.tmux.conf|~/.dotfiles/.tmux.conf"
  "~/.gitconfig|~/.dotfiles/.gitconfig"
  "~/.config/lsd/config.yaml|~/.dotfiles/.config/lsd/config.yaml"
  "~/.config/gh/config.yml|~/.dotfiles/.config/gh/config.yml"
  "~/.config/lazygit/config.yml|~/.dotfiles/.config/lazygit/config.yml"
  "~/.config/wezterm/wezterm.lua|~/.dotfiles/.config/wezterm/wezterm.lua"
)

# ── Main ──────────────────────────────────────────────────────
for entry in "${SYMLINKS[@]}"; do
  link_dotfile "${entry%%|*}" "${entry##*|}"
done

echo
ui_success "Symlinks checked and ready"
