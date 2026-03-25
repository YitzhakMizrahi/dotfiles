#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │              Shared Logging Helpers                        │
# ╰────────────────────────────────────────────────────────────╯
# Legacy helpers — prefer ui.sh for new scripts.
# Kept for backward compatibility with any external callers.
#   source "$(dirname "$0")/lib/logging.sh"

# Guard against double-sourcing
[[ -n "${__LOGGING_SH_LOADED:-}" ]] && return 0
__LOGGING_SH_LOADED=1

# ── Core ──────────────────────────────────────────────────────
info()    { echo -e "  \033[38;5;109m▸\033[0m $1"; }
success() { echo -e "  \033[38;5;142m✓\033[0m $1"; }
warn()    { echo -e "  \033[38;5;214m▲\033[0m $1"; }
fail()    { echo -e "  \033[38;5;167m✗\033[0m $1"; exit 1; }

# ── Extended (for scripts that need them) ─────────────────────
divider() { echo -e "\033[2m──────────────────────────────────────────────\033[0m"; }
