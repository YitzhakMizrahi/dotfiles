#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │                   System Update Utility                    │
# ╰────────────────────────────────────────────────────────────╯
# Updates system packages via the distro's native package manager.
# Supports Debian/Ubuntu (apt) and Fedora (dnf).

set -e

source "$(dirname "$0")/../lib/ui.sh"
source "$(dirname "$0")/../lib/platform.sh"

# ── Platform Check ────────────────────────────────────────────
DISTRO=$(detect_distro_family)
case "$DISTRO" in
  debian|fedora) ;;
  *) ui_fail "Unsupported distro family: $DISTRO (supported: debian, fedora)" ;;
esac

# ── Confirmation ──────────────────────────────────────────────
banner "System Update" "$(hostname) · $DISTRO · $(date +%Y-%m-%d)"

ui_warn "This will update your system packages."
echo
if ! ui_confirm "Proceed with system update?"; then
  ui_info "Update cancelled."
  exit 0
fi

# ── Update ────────────────────────────────────────────────────
echo
case "$DISTRO" in
  debian)
    step "apt: refresh package lists" sudo apt-get update -y
    step "apt: upgrade packages"      sudo apt-get upgrade -y
    step "apt: dist-upgrade"          sudo apt-get dist-upgrade -y
    step "apt: autoremove"            sudo apt-get autoremove -y
    ;;
  fedora)
    step "dnf: upgrade packages" sudo dnf upgrade -y --refresh
    step "dnf: autoremove"       sudo dnf autoremove -y
    ;;
esac

echo
ui_success "System updated"
