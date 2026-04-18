#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │              Platform & Distro Detection                   │
# ╰────────────────────────────────────────────────────────────╯
# Cross-distro support for Debian/Ubuntu, Fedora/RHEL, macOS, WSL.
# Exposes detection helpers and a thin dispatch for the few
# operations where the distro's package manager actually differs.
# Compatible with both bash and zsh.
#
# Detection results are memoized — /etc/os-release and /proc/version
# are stable for the life of the shell, so repeated calls return a
# cached value instead of re-invoking awk/grep.

[[ -n "${__PLATFORM_SH_LOADED:-}" ]] && return 0
__PLATFORM_SH_LOADED=1

# Platform: macos | wsl | linux | unknown
detect_platform() {
  if [[ -n "${__PLATFORM_CACHE+x}" ]]; then
    echo "$__PLATFORM_CACHE"
    return 0
  fi
  local result
  if [[ "$OSTYPE" == "darwin"* ]]; then
    result="macos"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if grep -qi microsoft /proc/version 2>/dev/null; then
      result="wsl"
    else
      result="linux"
    fi
  else
    result="unknown"
  fi
  __PLATFORM_CACHE="$result"
  echo "$result"
}

# Distro family: debian | fedora | arch | macos | unknown
# Reads /etc/os-release ID and ID_LIKE without polluting caller's scope.
detect_distro_family() {
  if [[ -n "${__DISTRO_FAMILY_CACHE+x}" ]]; then
    echo "$__DISTRO_FAMILY_CACHE"
    return 0
  fi
  local result
  if [[ "$OSTYPE" == "darwin"* ]]; then
    result="macos"
  elif [[ -r /etc/os-release ]]; then
    local id id_like
    id=$(awk -F= '/^ID=/       { gsub(/"/, "", $2); print $2; exit }' /etc/os-release)
    id_like=$(awk -F= '/^ID_LIKE=/ { gsub(/"/, "", $2); print $2; exit }' /etc/os-release)
    case " ${id_like} ${id} " in
      *" debian "*|*" ubuntu "*)              result="debian" ;;
      *" fedora "*|*" rhel "*|*" centos "*)   result="fedora" ;;
      *" arch "*)                             result="arch" ;;
      *)                                      result="unknown" ;;
    esac
  else
    result="unknown"
  fi
  __DISTRO_FAMILY_CACHE="$result"
  echo "$result"
}

# Immutable/atomic Fedora host (Silverblue, Kinoite, Bluefin, Bazzite, …)
is_silverblue() {
  [[ -f /run/ostree-booted ]]
}

# Diagnostic string for error messages — shows exactly what detection saw.
describe_os_release() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macOS ($OSTYPE)"
    return 0
  fi
  if [[ ! -r /etc/os-release ]]; then
    echo "/etc/os-release not readable"
    return 0
  fi
  local id id_like
  id=$(awk -F= '/^ID=/       { gsub(/"/, "", $2); print $2; exit }' /etc/os-release)
  id_like=$(awk -F= '/^ID_LIKE=/ { gsub(/"/, "", $2); print $2; exit }' /etc/os-release)
  echo "ID=${id:-<empty>} ID_LIKE=${id_like:-<empty>}"
}

# Human-readable distro + version for banners (e.g. "Fedora 41", "Ubuntu 22.04", "macOS 14.5")
detect_distro_pretty() {
  if [[ -n "${__DISTRO_PRETTY_CACHE+x}" ]]; then
    echo "$__DISTRO_PRETTY_CACHE"
    return 0
  fi
  local result
  if [[ "$OSTYPE" == "darwin"* ]]; then
    local version
    version=$(sw_vers -productVersion 2>/dev/null)
    if [[ -n "$version" ]]; then
      result="macOS $version"
    else
      result="macOS"
    fi
  elif [[ -r /etc/os-release ]]; then
    local name version_id
    name=$(awk -F= '/^NAME=/        { gsub(/"/, "", $2); print $2; exit }' /etc/os-release)
    version_id=$(awk -F= '/^VERSION_ID=/ { gsub(/"/, "", $2); print $2; exit }' /etc/os-release)
    # "Fedora Linux 41" → "Fedora 41"; "Debian GNU/Linux 12" stays verbose but authentic
    name="${name% Linux}"
    if [[ -n "$name" && -n "$version_id" ]]; then
      result="$name $version_id"
    elif [[ -n "$name" ]]; then
      result="$name"
    else
      result="unknown"
    fi
  else
    result="unknown"
  fi
  __DISTRO_PRETTY_CACHE="$result"
  echo "$result"
}

# Display name for the system package manager (used in UI labels)
pkg_manager_name() {
  case "$(detect_distro_family)" in
    debian) echo "apt" ;;
    fedora) echo "dnf" ;;
    arch)   echo "pacman" ;;
    macos)  echo "brew" ;;
    *)      echo "native" ;;
  esac
}

# Refresh the system package manager's cache/index
pkg_refresh_lists() {
  case "$(detect_distro_family)" in
    debian) sudo apt-get update -y ;;
    fedora) sudo dnf makecache ;;
    *) return 1 ;;
  esac
}

# Install base tools needed before Homebrew can run,
# plus a few items that genuinely benefit from native packaging
# (gocryptfs/FUSE, zsh for /etc/shells).
install_base_tools() {
  case "$(detect_distro_family)" in
    debian)
      sudo apt-get install -y \
        git zsh tmux curl wget unzip build-essential gocryptfs
      ;;
    fedora)
      sudo dnf install -y \
        @development-tools \
        git zsh tmux curl wget unzip procps-ng file gocryptfs
      ;;
    *) return 1 ;;
  esac
}
