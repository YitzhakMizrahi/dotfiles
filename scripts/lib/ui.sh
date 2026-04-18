#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │              UI Library (Gum + Fallback)                   │
# ╰────────────────────────────────────────────────────────────╯
# Elegant terminal output with Gruvbox-themed ANSI colors.
# Gum is used ONLY for interactive components (spin, confirm, input, choose)
# to avoid terminal query escape sequence leaks from gum style.
#
# Source this file instead of logging.sh:
#   source "$(dirname "$0")/lib/ui.sh"

# Guard against double-sourcing
[[ -n "${__UI_SH_LOADED:-}" ]] && return 0
__UI_SH_LOADED=1

# ── Gruvbox ANSI Colors ──────────────────────────────────────
# 256-color approximations of the Gruvbox palette
_C_RESET="\033[0m"
_C_BOLD="\033[1m"
_C_RED="\033[38;5;167m"
_C_GREEN="\033[38;5;142m"
_C_YELLOW="\033[38;5;214m"
_C_BLUE="\033[38;5;109m"
_C_GRAY="\033[38;5;245m"

# ── Gruvbox Hex Palette (for gum interactive components) ─────
readonly GB_FG="#ebdbb2"
readonly GB_RED="#fb4934"
readonly GB_GREEN="#8ec07c"
readonly GB_YELLOW="#fabd2f"
readonly GB_BLUE="#83a598"
readonly GB_PURPLE="#d3869b"
readonly GB_ORANGE="#fe8019"
readonly GB_GRAY="#928374"

# ── CI Mode ────────────────────────────────────────────────
# Set DOTFILES_CI=1 to skip interactive prompts (Docker, LXC tests)
DOTFILES_CI="${DOTFILES_CI:-0}"

# ── Gum Detection ──────────────────────────────────────────
# Disable gum in CI (no TTY) or when not installed
if [[ "$DOTFILES_CI" -eq 1 ]] || ! command -v gum &>/dev/null; then
  HAS_GUM=0
else
  HAS_GUM=1
fi

# ── Gum Theme (env vars for interactive components) ──────────
if [[ "$HAS_GUM" -eq 1 ]]; then
  export GUM_CONFIRM_PROMPT_FOREGROUND="$GB_FG"
  export GUM_CONFIRM_SELECTED_BACKGROUND="$GB_BLUE"
  export GUM_CONFIRM_SELECTED_FOREGROUND="#282828"
  export GUM_CONFIRM_UNSELECTED_FOREGROUND="$GB_GRAY"
  export GUM_INPUT_PROMPT_FOREGROUND="$GB_BLUE"
  export GUM_INPUT_CURSOR_FOREGROUND="$GB_ORANGE"
  export GUM_INPUT_PLACEHOLDER_FOREGROUND="$GB_GRAY"
  export GUM_CHOOSE_CURSOR_FOREGROUND="$GB_ORANGE"
  export GUM_CHOOSE_SELECTED_FOREGROUND="$GB_GREEN"
  export GUM_SPIN_SPINNER_FOREGROUND="$GB_BLUE"
fi

# ── Install Log ──────────────────────────────────────────────
# All step output goes here. Set DOTFILES_LOG before sourcing to override.
DOTFILES_LOG="${DOTFILES_LOG:-${HOME}/.dotfiles/install.log}"

ui_log_init() {
  mkdir -p "$(dirname "$DOTFILES_LOG")"
  : > "$DOTFILES_LOG"
}

_log_header() {
  echo "" >> "$DOTFILES_LOG"
  echo "══════════════════════════════════════════════════════" >> "$DOTFILES_LOG"
  echo "  $1" >> "$DOTFILES_LOG"
  echo "  $(date '+%Y-%m-%d %H:%M:%S')" >> "$DOTFILES_LOG"
  echo "══════════════════════════════════════════════════════" >> "$DOTFILES_LOG"
}

_show_failure() {
  echo "" >&2
  echo -e "  ${_C_GRAY}Last 10 lines:${_C_RESET}" >&2
  tail -10 "$DOTFILES_LOG" | sed 's/^/    /' >&2
  echo "" >&2
  echo -e "  ${_C_GRAY}Full log: $DOTFILES_LOG${_C_RESET}" >&2
}

# ── Banner ──────────────────────────────────────────────────
# Usage: banner "Dotfiles Installer" "linux · wsl · x86_64"
banner() {
  local title="$1"
  local subtitle="${2:-}"

  if [[ "$HAS_GUM" -eq 1 ]]; then
    local body="$title"
    [[ -n "$subtitle" ]] && body=$(printf "%s\n%s" "$title" "$subtitle")
    echo
    gum style \
      --border rounded \
      --border-foreground "$GB_BLUE" \
      --foreground "$GB_FG" \
      --padding "1 4" \
      --align center \
      "$body"
    echo
  else
    local width=46
    local border="${_C_BLUE}"
    local pad_line
    printf -v pad_line '%*s' "$width" ''

    # Center title
    local tpad=$(( (width - ${#title}) / 2 ))
    local tright=$(( width - tpad - ${#title} ))
    local centered_title
    printf -v centered_title '%*s%s%*s' "$tpad" '' "$title" "$tright" ''

    echo
    echo -e "${border}╭${pad_line// /─}╮${_C_RESET}"
    echo -e "${border}│${pad_line}│${_C_RESET}"
    echo -e "${border}│${_C_RESET}${_C_BOLD}${centered_title}${_C_RESET}${border}│${_C_RESET}"
    if [[ -n "$subtitle" ]]; then
      local spad=$(( (width - ${#subtitle}) / 2 ))
      local sright=$(( width - spad - ${#subtitle} ))
      local centered_sub
      printf -v centered_sub '%*s%s%*s' "$spad" '' "$subtitle" "$sright" ''
      echo -e "${border}│${_C_RESET}${_C_GRAY}${centered_sub}${_C_RESET}${border}│${_C_RESET}"
    fi
    echo -e "${border}│${pad_line}│${_C_RESET}"
    echo -e "${border}╰${pad_line// /─}╯${_C_RESET}"
    echo
  fi
}

# ── Section Header (top-level) ─────────────────────────────
# Usage: section "Configuration"
section() {
  echo
  echo -e "${_C_BOLD}${_C_BLUE}━━ $1 ━━${_C_RESET}"
}

# ── Subsection Header (within a section) ───────────────────
# Usage: subsection "Installed Tools"
subsection() {
  echo
  echo -e "  ${_C_GRAY}── $1 ──${_C_RESET}"
}

# ── Step (spinner + log) ─────────────────────────────────────
# Runs a command with a spinner, logging output to install.log.
# On failure, shows last 10 lines + log path.
# Do NOT use for interactive commands.
# Usage: step "Installing packages" brew bundle --file=Brewfile
step() {
  local label="$1"
  shift

  _log_header "$label"

  if [[ "$HAS_GUM" -eq 1 ]]; then
    if gum spin --spinner dot --title "$label" -- \
        bash -c '"$@" >> "$0" 2>&1' "$DOTFILES_LOG" "$@"; then
      echo -e "  ${_C_GREEN}✓${_C_RESET} $label"
    else
      echo -e "  ${_C_RED}✗${_C_RESET} $label"
      _show_failure "$label"
      return 1
    fi
  else
    ui_info "$label..."
    if "$@" >> "$DOTFILES_LOG" 2>&1; then
      ui_success "$label"
    else
      echo -e "  ${_C_RED}✗${_C_RESET} $label — failed"
      _show_failure "$label"
      return 1
    fi
  fi
}

# ── Confirm ─────────────────────────────────────────────────
# Usage: if ui_confirm "Restart shell?"; then ...
# In CI mode, returns 1 (no) by default. Pass "yes" as $2 to default yes.
ui_confirm() {
  local prompt="$1"
  local default="${2:-no}"
  if [[ "$DOTFILES_CI" -eq 1 ]]; then
    ui_info "$prompt → $default (CI mode)"
    [[ "$default" == "yes" ]]
    return
  fi
  if [[ "$HAS_GUM" -eq 1 ]]; then
    gum confirm "$prompt"
  else
    read -p "$prompt [y/N]: " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
  fi
}

# ── Input ───────────────────────────────────────────────────
# Usage: name=$(ui_input "Name:" "John Doe")
# In CI mode, returns the placeholder as default value.
ui_input() {
  local prompt="$1"
  local placeholder="${2:-}"
  if [[ "$DOTFILES_CI" -eq 1 ]]; then
    echo "$placeholder"
    return
  fi
  if [[ "$HAS_GUM" -eq 1 ]]; then
    gum input --prompt "$prompt " --placeholder "$placeholder"
  else
    read -p "$prompt " -r response
    echo "$response"
  fi
}

# ── Status Messages ─────────────────────────────────────────
ui_info()    { echo -e "  ${_C_BLUE}▸${_C_RESET} $1"; }
ui_success() { echo -e "  ${_C_GREEN}✓${_C_RESET} $1"; }
ui_warn()    { echo -e "  ${_C_YELLOW}▲${_C_RESET} $1"; }

ui_fail() {
  echo -e "  ${_C_RED}✗${_C_RESET} $1"
  exit 1
}

# ── Timing Helpers ────────────────────────────────────────────
_timer_start() {
  _TIMER_START=$(date +%s)
}

_timer_elapsed() {
  local start="${_TIMER_START:-$(date +%s)}"
  local now
  now=$(date +%s)
  local elapsed=$((now - start))
  local mins=$((elapsed / 60))
  local secs=$((elapsed % 60))
  if [[ $mins -gt 0 ]]; then
    echo "${mins}m ${secs}s"
  else
    echo "${secs}s"
  fi
}

# Like section, but prints elapsed time for the previous section and
# records each section's timing so section_summary can recap at the end.
_SECTION_START=""
_SECTION_LABEL=""
_SECTION_TIMINGS=()
timed_section() {
  local title="$1"
  timed_section_end
  section "$title"
  _SECTION_START=$(date +%s)
  _SECTION_LABEL="$title"
}

# Format a duration in seconds as "Xm Ys" or "Ys"
_format_duration() {
  local secs="$1"
  local mins=$((secs / 60))
  local rem=$((secs % 60))
  if [[ $mins -gt 0 ]]; then
    echo "${mins}m ${rem}s"
  else
    echo "${rem}s"
  fi
}

# Print elapsed time for the current section (call after the last timed_section)
timed_section_end() {
  if [[ -n "$_SECTION_START" ]]; then
    local now elapsed time_str
    now=$(date +%s)
    elapsed=$(( now - _SECTION_START ))
    time_str=$(_format_duration "$elapsed")
    _SECTION_TIMINGS+=("$_SECTION_LABEL|$elapsed")
    echo -e "  ${_C_GRAY}$_SECTION_LABEL completed in $time_str${_C_RESET}"
    _SECTION_START=""
    _SECTION_LABEL=""
  fi
}

# Print a recap of all timed_section durations recorded so far.
section_summary() {
  [[ ${#_SECTION_TIMINGS[@]} -eq 0 ]] && return 0
  echo
  echo "  Sections:"
  local entry label secs
  for entry in "${_SECTION_TIMINGS[@]}"; do
    label="${entry%%|*}"
    secs="${entry##*|}"
    printf "    ${_C_GREEN}✓${_C_RESET} %-18s %s\n" "$label" "$(_format_duration "$secs")"
  done
}
