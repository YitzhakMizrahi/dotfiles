#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                   System Update Utility                    │
# ╰────────────────────────────────────────────────────────────╯
# Updates APT packages. Linux/WSL only.

set -e

source "$(dirname "$0")/lib/logging.sh"

# ── Platform Check ────────────────────────────────────────────
if ! command -v apt-get &>/dev/null; then
  fail "APT not found. This script is for Debian/Ubuntu-based systems."
fi

# ── Confirmation ──────────────────────────────────────────────
echo
warn "This will update your system packages."
read -p "Proceed? [Y/n]: " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]?$ ]]; then
  info "Update cancelled."
  exit 0
fi

# ── Update ────────────────────────────────────────────────────
info "Updating package lists..."
sudo apt-get update

info "Upgrading packages..."
sudo apt-get upgrade -y

info "Running dist-upgrade..."
sudo apt-get dist-upgrade -y

info "Removing unused packages..."
sudo apt-get autoremove -y

echo
success "System updated."
