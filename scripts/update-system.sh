#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                   System Update Utility                    │
# ╰────────────────────────────────────────────────────────────╯
# Updates APT packages. Linux/WSL only.

set -e

source "$(dirname "$0")/lib/ui.sh"

# ── Platform Check ────────────────────────────────────────────
if ! command -v apt-get &>/dev/null; then
  ui_fail "APT not found. This script is for Debian/Ubuntu-based systems."
fi

# ── Confirmation ──────────────────────────────────────────────
banner "System Update" "$(hostname) · $(date +%Y-%m-%d)"

ui_warn "This will update your system packages."
echo
if ! ui_confirm "Proceed with system update?"; then
  ui_info "Update cancelled."
  exit 0
fi

# ── Update ────────────────────────────────────────────────────
echo
step "Updating package lists" sudo apt-get update -y
step "Upgrading packages" sudo apt-get upgrade -y
step "Running dist-upgrade" sudo apt-get dist-upgrade -y
step "Removing unused packages" sudo apt-get autoremove -y

echo
ui_success "System updated"
