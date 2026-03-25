#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │              Homebrew Path Detection                       │
# ╰────────────────────────────────────────────────────────────╯
# Single function to find and activate Homebrew on any platform.
# Compatible with both bash and zsh.

[[ -n "${__BREW_SH_LOADED:-}" ]] && return 0
__BREW_SH_LOADED=1

brew_ensure_path() {
  command -v brew &>/dev/null && return 0
  local brew_prefixes=("/home/linuxbrew/.linuxbrew" "$HOME/.linuxbrew" "/opt/homebrew" "/usr/local")
  for prefix in "${brew_prefixes[@]}"; do
    if [[ -x "$prefix/bin/brew" ]]; then
      eval "$("$prefix/bin/brew" shellenv)"
      return 0
    fi
  done
  return 1
}
