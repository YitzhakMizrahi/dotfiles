#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                  🧪 Post-Bootstrap Checklist                │
# ╰────────────────────────────────────────────────────────────╯
# Verifies tool versions and reminds about final manual steps

set -e

# ── Logging helpers ──
info()    { echo -e "\033[1;34mℹ️  $1\033[0m"; }
success() { echo -e "\033[1;32m✅ $1\033[0m"; }
warn()    { echo -e "\033[1;33m⚠️  $1\033[0m"; }
fail()    { echo -e "\033[1;31m❌ $1\033[0m"; exit 1; }

# ── Tool Version Checks ──
print_version() {
  local emoji="$1"
  local label="$2"
  local cmd="$3"
  if command -v "$cmd" >/dev/null 2>&1; then
    version="$($cmd --version 2>/dev/null | head -n 1)"
    printf "  %s  %-10s  %s\n" "$emoji" "$label" "$version"
  else
    printf "  ⚠️   %-10s  Not found\n" "$label"
  fi
}

echo
info "Checking tool versions …"
echo

# Source nvm if needed
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  # shellcheck disable=SC1090
  source "$NVM_DIR/nvm.sh"
fi

# Python (pyenv)
if [ -d "$HOME/.pyenv" ]; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path 2>/dev/null)"
  eval "$(pyenv init - 2>/dev/null)"

  if command -v pyenv >/dev/null 2>&1; then
    python_ver=$(pyenv version-name)
    printf "  🐍  %-10s  %s\n" "Python" "$python_ver"
  else
    printf "  ⚠️   %-10s  pyenv not initialized\n" "Python"
  fi
else
  printf "  ⚠️   %-10s  Not found\n" "Python"
fi

# Node.js
if command -v node >/dev/null 2>&1; then
  printf "  🟢  %-10s  %s\n" "Node.js" "$(node --version)"
else
  printf "  ⚠️   %-10s  Not found\n" "Node.js"
fi

# Other tools
print_version "📦" "pnpm" "pnpm"
print_version "🔧" "Git"  "git"
print_version "💻" "Zsh"  "zsh"

echo
echo -e "📋 \033[1;34mFinal checklist:\033[0m"
echo
echo -e "  📝  Things you may still want to do manually:"
echo -e "  ⚡  Run '\033[1;33mgh auth login\033[0m' to enable GitHub CLI SSH key upload"
echo -e "  ⌘   Open a new shell session or run '\033[1;33mexec zsh\033[0m' to reload prompt"
echo -e "  🧪  Customize your \033[1;36m~/.config/starship.toml\033[0m if needed"
echo -e "  🛠️  Review \033[1;36m~/.gitconfig.local\033[0m for correctness"

echo
success "🌟 Post-bootstrap check complete. You are all set!"
