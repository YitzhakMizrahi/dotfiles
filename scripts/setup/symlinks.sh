#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                  Dotfile Symlink Setup                     │
# ╰────────────────────────────────────────────────────────────╯
# Checks and creates symlinks for tracked dotfiles

set -e

source "$(dirname "$0")/../lib/ui.sh"
source "$(dirname "$0")/../lib/paths.sh"

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
  "~/.config/gh/config.yml|~/.dotfiles/.config/gh/config.yml"
  "~/.config/lazygit/config.yml|~/.dotfiles/.config/lazygit/config.yml"
  "~/.config/wezterm/wezterm.lua|~/.dotfiles/.config/wezterm/wezterm.lua"
)

# ── Main ──────────────────────────────────────────────────────
for entry in "${SYMLINKS[@]}"; do
  link_dotfile "${entry%%|*}" "${entry##*|}"
done

# ── WSL: Copy wezterm config to Windows side ──────────────────
# Wezterm runs on Windows and needs its config before WSL boots,
# so we copy (not symlink) to the Windows filesystem.
if grep -qi microsoft /proc/version 2>/dev/null; then
  win_user=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')
  if [[ -n "$win_user" ]]; then
    win_wezterm_dir="/mnt/c/Users/$win_user/.config/wezterm"
    wezterm_src="$DOTFILES_DIR/.config/wezterm/wezterm.lua"
    if [[ -f "$wezterm_src" ]]; then
      mkdir -p "$win_wezterm_dir"
      cp "$wezterm_src" "$win_wezterm_dir/wezterm.lua"
      ui_success "Synced wezterm.lua → $win_wezterm_dir"
    fi
  else
    ui_warn "Could not detect Windows username — skipping wezterm sync"
  fi
fi

echo
ui_success "Symlinks checked and ready"
