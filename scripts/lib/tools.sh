#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │              Tool Mapping (Brewfile → commands)            │
# ╰────────────────────────────────────────────────────────────╯
# Brewfile is the single source of truth for managed tools.
# This file maps formula names to commands and labels where they differ.

[[ -n "${__TOOLS_SH_LOADED:-}" ]] && return 0
__TOOLS_SH_LOADED=1

# Formula → command name (only where they differ)
tool_cmd() {
  case "$1" in
    ripgrep)   echo "rg" ;;
    git-delta) echo "delta" ;;
    *)         echo "$1" ;;
  esac
}

# Formula → display label (only where they differ)
tool_label() {
  case "$1" in
    git-delta) echo "delta" ;;
    *)         echo "$1" ;;
  esac
}

# Tools handled in dedicated sections (skipped in generic tool checks)
tool_is_skipped() {
  case "$1" in
    mise) return 0 ;;
    *)    return 1 ;;
  esac
}

# mise runtime → binary command (only where they differ)
runtime_cmd() {
  case "$1" in
    rust) echo "rustc" ;;
    *)    echo "$1" ;;
  esac
}

# Parse Brewfile and return formula names (one per line)
brewfile_formulas() {
  sed -n 's/^brew "\([^"]*\)".*/\1/p' "${1:-$DOTFILES_DIR/Brewfile}"
}

# Parse .mise.toml [tools] section and return runtime names (one per line)
mise_runtimes() {
  local config="${1:-$MISE_GLOBAL_CONFIG_FILE}"
  [[ -f "$config" ]] || return 0
  sed -n '/^\[tools\]/,/^\[/p' "$config" | awk -F '=' '/^[a-z_-]/ { gsub(/[[:space:]]/, "", $1); print $1 }'
}
