#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                Post-Install Validation                     │
# ╰────────────────────────────────────────────────────────────╯
# Verifies tool versions and reminds about final manual steps

set -e

source "$(dirname "$0")/lib/ui.sh"

# ── Tool Version Checks ──────────────────────────────────────
# Strip ANSI escape sequences and terminal responses from version output
strip_ansi() {
  sed 's/\x1b\[[0-9;]*[a-zA-Z]//g; s/\x1b[P>][^\\]*\\\\//g; s/\x1b[^[]*//g' | tr -d '\r'
}

# Get version string for a tool (handles per-tool quirks)
# TERM=dumb prevents tools from sending terminal queries (DA, DSR)
get_version() {
  local cmd="$1"
  (
    export TERM=dumb
    case "$cmd" in
      tmux)     tmux -V 2>/dev/null ;;
      lazygit)  lazygit --version 2>/dev/null | grep -oP 'version=\K[^,]+' | head -1 ;;
      btop)     btop --version 2>/dev/null | grep -oP 'btop version: \K.*' ;;
      *)        "$cmd" --version 2>/dev/null | head -n 1 ;;
    esac
  ) | strip_ansi
}

print_version() {
  local label="$1"
  local cmd="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    local version
    version="$(get_version "$cmd")"
    printf "  ${_C_GREEN}✓${_C_RESET} %-12s  %s\n" "$label" "$version"
  else
    printf "  ${_C_RED}✗${_C_RESET} %-12s  Not found\n" "$label"
  fi
}

# Suppress terminal echo during version checks to prevent DCS response
# display (tools like yazi query the terminal directly via /dev/tty)
_SAVED_TERM="${TERM:-}"
export TERM=dumb
stty -echo 2>/dev/null || true

subsection "Installed Tools"
echo

print_version "Git" "git"
print_version "Zsh" "zsh"
print_version "tmux" "tmux"
print_version "Starship" "starship"
print_version "gum" "gum"
print_version "bat" "bat"
print_version "lsd" "lsd"
print_version "fd" "fd"
print_version "ripgrep" "rg"
print_version "fzf" "fzf"
print_version "zoxide" "zoxide"
print_version "delta" "delta"
print_version "lazygit" "lazygit"
print_version "yazi" "yazi"
print_version "gh" "gh"
print_version "btop" "btop"
print_version "fastfetch" "fastfetch"

# Restore echo and drain any pending terminal responses
stty echo 2>/dev/null || true
read -r -t 0.1 -s -n 10000 2>/dev/null </dev/tty || true
export TERM="${_SAVED_TERM}"

# ── Language Runtimes ────────────────────────────────────────
subsection "Language Runtimes"
echo
if command -v mise >/dev/null 2>&1; then
  mise list 2>/dev/null || ui_warn "No runtimes installed yet"
else
  ui_warn "mise not found — language runtimes not managed"
fi

# ── Symlink Validation ────────────────────────────────────────
subsection "Symlinks"
echo

check_symlink() {
  local target="$1"
  if [[ -L "$target" ]]; then
    echo -e "  ${_C_GREEN}✓${_C_RESET} $target"
  elif [[ -e "$target" ]]; then
    echo -e "  ${_C_YELLOW}▲${_C_RESET} $target (not a symlink)"
  else
    echo -e "  ${_C_RED}✗${_C_RESET} $target (missing)"
  fi
}

check_symlink "$HOME/.zshrc"
check_symlink "$HOME/.tmux.conf"
check_symlink "$HOME/.gitconfig"
check_symlink "$HOME/.config/lsd/config.yaml"
check_symlink "$HOME/.config/gh/config.yml"
check_symlink "$HOME/.config/lazygit/config.yml"
check_symlink "$HOME/.config/wezterm/wezterm.lua"

# ── Environment Checks ──────────────────────────────────────
subsection "Environment"
echo
if command -v docker >/dev/null 2>&1; then
  print_version "Docker" "docker"
else
  ui_warn "Docker not found"
  if grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then
    echo "    Install Docker Desktop for Windows and enable WSL integration"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "    Install Docker Desktop: https://docs.docker.com/desktop/install/mac-install/"
  else
    echo "    Install Docker Engine: https://docs.docker.com/engine/install/"
  fi
fi

# ── Final Checklist ───────────────────────────────────────────
subsection "Next Steps"
echo
echo "    gh auth login                          Authenticate GitHub CLI"
echo "    exec zsh                               Reload shell"
echo "    cat ~/.gitconfig.local                 Review Git identity"

echo
ui_success "Post-install validation complete"
