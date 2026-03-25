#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                  Install Validation Tests                  │
# ╰────────────────────────────────────────────────────────────╯
# Run after install.sh to verify everything is set up correctly.
# Used by both Docker CI and local LXC testing.
# Exit code: 0 if all pass, 1 if any fail.

set -e

# Ensure Homebrew is on PATH (needed for Docker/LXC test environments)
if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
  eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
elif [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

PASS=0
FAIL=0

check() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    printf "  PASS  %s\n" "$label"
    PASS=$((PASS + 1))
  else
    printf "  FAIL  %s\n" "$label"
    FAIL=$((FAIL + 1))
  fi
}

check_symlink() {
  local target="$1"
  local label="symlink: $target"
  if [[ -L "$target" ]]; then
    printf "  PASS  %s\n" "$label"
    PASS=$((PASS + 1))
  else
    printf "  FAIL  %s\n" "$label"
    FAIL=$((FAIL + 1))
  fi
}

echo
echo "=== Dotfiles Install Validation ==="
echo

# ── Symlinks ──────────────────────────────────────────────────
echo "-- Symlinks --"
check_symlink "$HOME/.zshrc"
check_symlink "$HOME/.tmux.conf"
check_symlink "$HOME/.gitconfig"
check_symlink "$HOME/.config/lsd/config.yaml"
check_symlink "$HOME/.config/gh/config.yml"
check_symlink "$HOME/.config/lazygit/config.yml"
check_symlink "$HOME/.config/wezterm/wezterm.lua"
echo

# ── Core Tools ────────────────────────────────────────────────
echo "-- Core Tools --"
check "git"       command -v git
check "zsh"       command -v zsh
check "tmux"      command -v tmux
check "curl"      command -v curl
check "wget"      command -v wget
echo

# ── Modern CLI ────────────────────────────────────────────────
echo "-- Modern CLI Tools --"
check "bat"       command -v bat
check "lsd"       command -v lsd
check "fd"        command -v fd
check "ripgrep"   command -v rg
check "fzf"       command -v fzf
check "zoxide"    command -v zoxide
check "delta"     command -v delta
check "lazygit"   command -v lazygit
check "yazi"      command -v yazi
check "gh"        command -v gh
check "btop"      command -v btop
check "starship"  command -v starship
check "fastfetch" command -v fastfetch
check "duf"       command -v duf
check "dust"      command -v dust
check "jq"        command -v jq
check "tldr"      command -v tldr
echo

# ── Runtime Manager ───────────────────────────────────────────
echo "-- Runtime Manager --"
check "mise"      command -v mise
echo

# ── Language Runtimes ─────────────────────────────────────────
echo "-- Language Runtimes (mise) --"
if command -v mise >/dev/null 2>&1; then
  export MISE_GLOBAL_CONFIG_FILE="$HOME/.dotfiles/.mise.toml"
  eval "$(mise activate bash 2>/dev/null)" || true
  check "python"  mise which python
  check "node"    mise which node
  check "go"      mise which go
  check "rust"    mise which rustc
else
  printf "  SKIP  mise not installed — skipping runtime checks\n"
fi
echo

# ── Shell Config ──────────────────────────────────────────────
echo "-- Shell Config --"
check "zinit installed" test -d "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
check "starship config exists" test -f "$HOME/.dotfiles/.config/starship.toml"
check "gitconfig.local exists" test -f "$HOME/.gitconfig.local"
echo

# ── Summary ───────────────────────────────────────────────────
TOTAL=$((PASS + FAIL))
echo "=== Results: $PASS/$TOTAL passed ==="

if [[ $FAIL -gt 0 ]]; then
  echo "$FAIL test(s) failed."
  exit 1
else
  echo "All tests passed."
  exit 0
fi
