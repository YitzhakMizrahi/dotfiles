#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │              Shared Logging Helpers                        │
# ╰────────────────────────────────────────────────────────────╯
# Source this file at the top of any setup script:
#   source "$(dirname "$0")/lib/logging.sh"

# Guard against double-sourcing
[[ -n "${__LOGGING_SH_LOADED:-}" ]] && return 0
__LOGGING_SH_LOADED=1

# ── Core ──────────────────────────────────────────────────────
info()    { echo -e "\033[1;34mℹ️  $1\033[0m"; }
success() { echo -e "\033[1;32m✅ $1\033[0m"; }
warn()    { echo -e "\033[1;33m⚠️  $1\033[0m"; }
fail()    { echo -e "\033[1;31m❌ $1\033[0m"; exit 1; }

# ── Extended (for scripts that need them) ─────────────────────
created() { echo -e "\033[1;35m📁 Created directory: $1\033[0m"; }
touched() { echo -e "\033[1;36m📄 Created file: $1\033[0m"; }
divider() { echo -e "\033[2m──────────────────────────────────────────────\033[0m"; }
