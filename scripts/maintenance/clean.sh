#!/usr/bin/env bash

# ╭────────────────────────────────────────────────────────────╮
# │              Dev Environment Cleanup Utility               │
# ╰────────────────────────────────────────────────────────────╯
# Cleans package caches, build artifacts, and system junk.
#
# Usage:
#   cleanup              Auto-delete safe caches, show savings
#   cleanup --dry-run    Preview everything, delete nothing
#   cleanup --deep       Regular cleanup + interactive review of heavy items

set -euo pipefail

source "$(dirname "$0")/../lib/ui.sh"

# ── Flags ────────────────────────────────────────────────────
DRY_RUN=0
DEEP=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --deep)    DEEP=1 ;;
  esac
done

# ── Helpers ──────────────────────────────────────────────────

# Size in bytes (cross-platform)
size_bytes() {
  if [[ -e "$1" ]]; then
    if du -sb "$1" &>/dev/null; then
      du -sb "$1" 2>/dev/null | cut -f1
    else
      echo $(( $(du -s "$1" 2>/dev/null | cut -f1) * 512 ))
    fi
  else
    echo 0
  fi
}

# Human-readable size (pure bash)
human_size() {
  local bytes="$1"
  if [[ "$bytes" -ge 1073741824 ]]; then
    local whole=$((bytes / 1073741824))
    local frac=$(( (bytes % 1073741824) * 10 / 1073741824 ))
    echo "${whole}.${frac}G"
  elif [[ "$bytes" -ge 1048576 ]]; then
    echo "$(( bytes / 1048576 ))M"
  elif [[ "$bytes" -ge 1024 ]]; then
    echo "$(( bytes / 1024 ))K"
  else
    echo "${bytes}B"
  fi
}

# Available disk space in bytes (cross-platform)
disk_free_bytes() {
  if df --output=avail -B1 "$HOME" &>/dev/null; then
    df --output=avail -B1 "$HOME" 2>/dev/null | tail -1 | tr -d ' '
  else
    echo $(( $(df "$HOME" 2>/dev/null | tail -1 | awk '{print $4}') * 512 ))
  fi
}

# ── Summary Tracking ────────────────────────────────────────
declare -a SUMMARY_NAMES=()
declare -a SUMMARY_FREED=()
declare -a SUMMARY_EST=()

# Record a section's freed space (real run) or estimate (dry-run)
track_section() {
  local name="$1" start_bytes="$2" estimate="${3:-0}"
  SUMMARY_NAMES+=("$name")
  if [[ "$DRY_RUN" -eq 0 ]]; then
    local freed=$(( $(disk_free_bytes) - start_bytes ))
    [[ "$freed" -lt 0 ]] && freed=0
    SUMMARY_FREED+=("$freed")
  else
    SUMMARY_FREED+=("0")
  fi
  SUMMARY_EST+=("$estimate")
}

# ── Cleanup Functions ───────────────────────────────────────

# Run a cache cleanup command
do_clean() {
  local label="$1"
  shift

  if [[ "$DRY_RUN" -eq 1 ]]; then
    ui_info "$label"
    return
  fi

  if [[ "$1" == "sudo" ]]; then
    "$@" >/dev/null || true
  else
    "$@" &>/dev/null || true
  fi
  ui_success "$label"
}

# Find and remove build artifact directories under ~/dev
# Tracks estimated size for summary
ARTIFACT_ESTIMATE=0

clean_dev_dirs() {
  local label="$1"
  local pattern="$2"
  local sibling="${3:-}"

  local dirs=()
  while IFS= read -r -d '' dir; do
    if [[ -n "$sibling" ]]; then
      [[ -f "$(dirname "$dir")/$sibling" ]] || continue
    fi
    dirs+=("$dir")
  done < <(find "$HOME/dev" -name "$pattern" -type d \
    -not -path '*/node_modules/*' \
    -not -path '*/.venv/*' \
    -print0 2>/dev/null)

  [[ ${#dirs[@]} -eq 0 ]] && return

  local total=0
  for dir in "${dirs[@]}"; do
    total=$((total + $(size_bytes "$dir")))
  done
  ARTIFACT_ESTIMATE=$((ARTIFACT_ESTIMATE + total))

  local count=${#dirs[@]}
  local plural="dirs"; [[ "$count" -eq 1 ]] && plural="dir"
  local msg="$label — $count $plural ($(human_size $total))"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    ui_info "$msg"
  else
    for dir in "${dirs[@]}"; do
      rm -rf "$dir"
    done
    ui_success "$msg"
  fi
}

# Interactive per-item review (used in --deep mode)
deep_review_dirs() {
  local label="$1"
  shift
  local dirs=("$@")

  if [[ ${#dirs[@]} -eq 0 ]]; then
    ui_info "None found"
    return
  fi

  for dir in "${dirs[@]}"; do
    local dir_bytes dir_size project dir_label
    dir_bytes=$(size_bytes "$dir")
    dir_size=$(human_size "$dir_bytes")
    project=$(dirname "$dir" | sed "s|$HOME/||")
    dir_label="$project/$(basename "$dir")"

    if ui_confirm "  Remove $dir_label ($dir_size)?"; then
      if [[ "$DRY_RUN" -eq 1 ]]; then
        echo -e "  ${_C_GRAY}[dry-run]${_C_RESET} Would remove ($dir_size)"
      else
        rm -rf "$dir"
        ui_success "Removed ($dir_size freed)"
      fi
    else
      ui_info "Kept"
    fi
  done
}

# ── Main ─────────────────────────────────────────────────────
MODE="cleanup"
[[ "$DRY_RUN" -eq 1 ]] && MODE="dry run"
[[ "$DEEP" -eq 1 ]] && MODE="deep"
[[ "$DRY_RUN" -eq 1 && "$DEEP" -eq 1 ]] && MODE="deep · dry run"

banner "Dev Cleanup" "$MODE · $(date +%Y-%m-%d)"

DISK_BEFORE=$(disk_free_bytes)

# ── Package Caches ───────────────────────────────────────────
section "Package Caches"
echo
sec_start=$(disk_free_bytes)

command -v uv    &>/dev/null && do_clean "uv cache"            uv cache clean
command -v pip   &>/dev/null && do_clean "pip cache"            pip cache purge
command -v npm   &>/dev/null && do_clean "npm cache"            npm cache clean --force
command -v pnpm  &>/dev/null && do_clean "pnpm store"           pnpm store prune
command -v go    &>/dev/null && do_clean "go build cache"       go clean -cache
command -v cargo &>/dev/null && do_clean "cargo registry cache" bash -c 'rm -rf ~/.cargo/registry/cache/* ~/.cargo/registry/src/*'
command -v brew  &>/dev/null && do_clean "brew cache"           brew cleanup --prune=0
command -v mise  &>/dev/null && do_clean "mise cache"           mise cache clear

track_section "Package Caches" "$sec_start"

# ── Build Artifacts ──────────────────────────────────────────
if [[ -d "$HOME/dev" ]]; then
  section "Build Artifacts"
  echo
  sec_start=$(disk_free_bytes)
  ARTIFACT_ESTIMATE=0

  clean_dev_dirs ".next"          ".next"
  clean_dev_dirs ".turbo"         ".turbo"
  clean_dev_dirs "Rust target"    "target"       "Cargo.toml"
  clean_dev_dirs "__pycache__"    "__pycache__"
  clean_dev_dirs ".pytest_cache"  ".pytest_cache"
  clean_dev_dirs ".ruff_cache"    ".ruff_cache"
  clean_dev_dirs ".mypy_cache"    ".mypy_cache"

  track_section "Build Artifacts" "$sec_start" "$ARTIFACT_ESTIMATE"
fi

# ── System ───────────────────────────────────────────────────
section "System"
echo
sec_start=$(disk_free_bytes)

if [[ -d "$HOME/.cache/pre-commit" ]]; then
  do_clean "pre-commit cache" bash -c 'rm -rf ~/.cache/pre-commit/*'
fi

if command -v apt-get &>/dev/null; then
  do_clean "apt cache" sudo apt-get clean -y
elif command -v dnf &>/dev/null; then
  do_clean "dnf cache" sudo dnf clean all
fi

if command -v journalctl &>/dev/null && pidof systemd &>/dev/null; then
  do_clean "journal logs (→100M)" sudo journalctl --vacuum-size=100M
fi

track_section "System" "$sec_start"

# ── Docker ───────────────────────────────────────────────────
if command -v docker &>/dev/null && docker info &>/dev/null; then
  section "Docker"
  echo
  sec_start=$(disk_free_bytes)

  do_clean "build cache" docker builder prune -f

  track_section "Docker" "$sec_start"
fi

# ── Deep Review ──────────────────────────────────────────────
if [[ "$DEEP" -eq 1 ]]; then
  section "Deep Review"

  if [[ -d "$HOME/dev" ]]; then
    subsection "Stale node_modules (>30 days)"
    stale_nm=()
    while IFS= read -r -d '' dir; do
      stale_nm+=("$dir")
    done < <(find "$HOME/dev" -maxdepth 5 -name "node_modules" -type d -mtime +30 \
      -not -path '*/node_modules/*/node_modules*' -print0 2>/dev/null)
    deep_review_dirs "node_modules" "${stale_nm[@]}"

    subsection "Stale .venv (>30 days)"
    stale_venv=()
    while IFS= read -r -d '' dir; do
      stale_venv+=("$dir")
    done < <(find "$HOME/dev" -maxdepth 5 -name ".venv" -type d -mtime +30 -print0 2>/dev/null)
    deep_review_dirs ".venv" "${stale_venv[@]}"
  fi

  if command -v ollama &>/dev/null; then
    subsection "Ollama Models"

    model_lines=()
    while IFS= read -r line; do
      model_lines+=("$line")
    done < <(ollama list 2>/dev/null | tail -n +2)

    if [[ ${#model_lines[@]} -eq 0 ]]; then
      ui_info "No models installed"
    else
      choices=()
      for line in "${model_lines[@]}"; do
        name=$(echo "$line" | awk '{print $1}')
        size=$(echo "$line" | awk '{print $3 $4}')
        choices+=("$name ($size)")
      done

      if [[ "$HAS_GUM" -eq 1 ]]; then
        echo -e "  ${_C_GRAY}Space to select, Enter to confirm (none selected = skip)${_C_RESET}"
        echo
        selected=$(gum choose --no-limit \
            --cursor-prefix "◯ " \
            --selected-prefix "◉ " \
            --unselected-prefix "◯ " \
            --header "Select models to remove:" \
            "${choices[@]}" || true)

        if [[ -z "$selected" ]]; then
          ui_info "No models selected — skipped"
        else
          while IFS= read -r item; do
            model_name=$(echo "$item" | sed 's/ (.*//')
            if [[ "$DRY_RUN" -eq 1 ]]; then
              echo -e "  ${_C_GRAY}[dry-run]${_C_RESET} Would remove $model_name"
            else
              ollama rm "$model_name" &>/dev/null && \
                ui_success "Removed $model_name" || \
                ui_warn "Failed to remove $model_name"
            fi
          done <<< "$selected"
        fi
      else
        for line in "${model_lines[@]}"; do
          name=$(echo "$line" | awk '{print $1}')
          size=$(echo "$line" | awk '{print $3 $4}')
          if ui_confirm "  Remove $name ($size)?"; then
            if [[ "$DRY_RUN" -eq 1 ]]; then
              echo -e "  ${_C_GRAY}[dry-run]${_C_RESET} Would remove $name"
            else
              ollama rm "$name" &>/dev/null && \
                ui_success "Removed $name" || \
                ui_warn "Failed to remove $name"
            fi
          else
            ui_info "Kept $name"
          fi
        done
      fi
    fi
  fi

  subsection "Largest ~/.cache entries"
  echo
  if [[ -d "$HOME/.cache" ]]; then
    du -sh "$HOME/.cache"/*/ 2>/dev/null | sort -rh | head -5 | while read -r size dir; do
      echo -e "  ${_C_YELLOW}$size${_C_RESET}  $(basename "$dir")"
    done
  fi
fi

# ── Summary ──────────────────────────────────────────────────
DISK_AFTER=$(disk_free_bytes)
TOTAL_FREED=$((DISK_AFTER - DISK_BEFORE))
[[ "$TOTAL_FREED" -lt 0 ]] && TOTAL_FREED=0

echo
echo -e "  ${_C_GRAY}────────────────────────────────────────${_C_RESET}"

if [[ "$DRY_RUN" -eq 1 ]]; then
  # Show estimated sizes where available
  for i in "${!SUMMARY_NAMES[@]}"; do
    est="${SUMMARY_EST[$i]}"
    if [[ "$est" -gt 0 ]]; then
      printf "  ${_C_GRAY}%-28s ~%s${_C_RESET}\n" "${SUMMARY_NAMES[$i]}" "$(human_size "$est")"
    fi
  done
  echo
  echo -e "  ${_C_BLUE}Available disk space:${_C_RESET} $(human_size $DISK_BEFORE)"
  echo -e "  ${_C_GRAY}Run without --dry-run to clean${_C_RESET}"
else
  # Show per-section breakdown
  has_breakdown=0
  for i in "${!SUMMARY_NAMES[@]}"; do
    freed="${SUMMARY_FREED[$i]}"
    if [[ "$freed" -gt 1024 ]]; then
      printf "  %-28s %s\n" "${SUMMARY_NAMES[$i]}" "$(human_size "$freed")"
      has_breakdown=1
    fi
  done
  if [[ "$has_breakdown" -eq 1 ]]; then
    echo -e "  ${_C_GRAY}────────────────────────────────────────${_C_RESET}"
  fi
  echo -e "  $(human_size $DISK_BEFORE) → $(human_size $DISK_AFTER)  ${_C_GREEN}+$(human_size $TOTAL_FREED) freed${_C_RESET}"
fi

echo
ui_success "Cleanup complete"
