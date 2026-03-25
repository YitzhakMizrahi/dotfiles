#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │              Central Path Constants                        │
# ╰────────────────────────────────────────────────────────────╯
# Single source of truth for paths used across scripts and shell config.
# Compatible with both bash and zsh.

[[ -n "${__PATHS_SH_LOADED:-}" ]] && return 0
__PATHS_SH_LOADED=1

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
GITCONFIG_LOCAL="$HOME/.gitconfig.local"
export MISE_GLOBAL_CONFIG_FILE="${MISE_GLOBAL_CONFIG_FILE:-$DOTFILES_DIR/.mise.toml}"
export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$DOTFILES_DIR/.config/starship.toml}"
