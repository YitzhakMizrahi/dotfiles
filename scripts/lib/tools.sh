#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │              Tool Mapping (Brewfile → commands)            │
# ╰────────────────────────────────────────────────────────────╯
# Brewfile is the single source of truth for managed tools.
# This file maps formula names to commands and labels where they differ.

[[ -n "${__TOOLS_SH_LOADED:-}" ]] && return 0
__TOOLS_SH_LOADED=1

# Formula → command name (only where they differ)
declare -A _TOOL_CMD=(
  ["ripgrep"]="rg"
  ["git-delta"]="delta"
)

# Formula → display label (only where they differ)
declare -A _TOOL_LABEL=(
  ["git-delta"]="delta"
)

# Tools handled in dedicated sections (skipped in generic tool checks)
_TOOL_SKIP=("mise")

tool_cmd()   { echo "${_TOOL_CMD[$1]:-$1}"; }
tool_label() { echo "${_TOOL_LABEL[$1]:-$1}"; }

tool_is_skipped() {
  local formula="$1"
  for skip in "${_TOOL_SKIP[@]}"; do
    [[ "$formula" == "$skip" ]] && return 0
  done
  return 1
}

# mise runtime → binary command (only where they differ)
declare -A _RUNTIME_CMD=(
  ["rust"]="rustc"
)

runtime_cmd() { echo "${_RUNTIME_CMD[$1]:-$1}"; }

# Parse Brewfile and return formula names (one per line)
brewfile_formulas() {
  grep -oP '^brew "\K[^"]+' "${1:-$DOTFILES_DIR/Brewfile}"
}

# Parse .mise.toml [tools] section and return runtime names (one per line)
mise_runtimes() {
  local config="${1:-$MISE_GLOBAL_CONFIG_FILE}"
  [[ -f "$config" ]] || return 0
  sed -n '/^\[tools\]/,/^\[/p' "$config" | grep -oP '^\K[a-z_-]+(?=\s*=)'
}
