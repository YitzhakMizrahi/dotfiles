#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                Post-Install Validation                     │
# ╰────────────────────────────────────────────────────────────╯
# Verifies tool versions and reminds about final manual steps

set -e

source "$(dirname "$0")/lib/ui.sh"
source "$(dirname "$0")/lib/paths.sh"
source "$(dirname "$0")/lib/tools.sh"

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

while IFS= read -r formula; do
  tool_is_skipped "$formula" && continue
  print_version "$(tool_label "$formula")" "$(tool_cmd "$formula")"
done < <(brewfile_formulas)

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

# Read symlink targets dynamically from symlinks.sh
SYMLINKS_SCRIPT="$DOTFILES_DIR/scripts/setup/symlinks.sh"
if [[ -f "$SYMLINKS_SCRIPT" ]]; then
  while IFS= read -r target; do
    check_symlink "${target/#\~/$HOME}"
  done < <(grep -oP '^\s*\["\K[^"]+' "$SYMLINKS_SCRIPT")
else
  ui_warn "symlinks.sh not found — cannot validate"
fi

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

if command -v gh >/dev/null 2>&1 && gh auth status &>/dev/null; then
  ui_success "GitHub CLI authenticated"
else
  ui_warn "GitHub CLI not authenticated"
fi

# Brewfile consistency check
if command -v brew >/dev/null 2>&1; then
  BREWFILE="$DOTFILES_DIR/Brewfile"
  if [[ -f "$BREWFILE" ]]; then
    if brew bundle check --file="$BREWFILE" &>/dev/null; then
      ui_success "All Brewfile packages installed"
    else
      ui_warn "Missing Brewfile packages:"
      brew bundle check --verbose --file="$BREWFILE" 2>/dev/null \
        | grep -oP '→ Formula \K\S+' | while read -r pkg; do
          echo "    $pkg"
        done
      ui_info "Run 'dotfiles update' to install missing packages"
    fi
  fi
fi

# ── Next Steps (only show what's pending) ─────────────────────
NEXT_STEPS=()
if command -v gh >/dev/null 2>&1 && ! gh auth status &>/dev/null; then
  NEXT_STEPS+=("    gh auth login                          Authenticate GitHub CLI")
fi
if [[ "$SHELL" != *zsh ]]; then
  NEXT_STEPS+=("    chsh -s \$(which zsh)                   Set Zsh as default shell")
fi
if [[ ! -f "$GITCONFIG_LOCAL" ]] || ! grep -q "name =" "$GITCONFIG_LOCAL" 2>/dev/null; then
  NEXT_STEPS+=("    dotfiles install                        Set up Git identity")
fi

if [[ ${#NEXT_STEPS[@]} -gt 0 ]]; then
  subsection "Next Steps"
  echo
  for step in "${NEXT_STEPS[@]}"; do
    echo "$step"
  done
fi

echo
ui_success "Post-install validation complete"
