# ⏱️ ── Optional Timing Flag ───────────────────────────────────────────
if [[ $SOURCE_TIMING == "true" ]]; then
  zmodload zsh/datetime
  __zshrc_timer_origin=$EPOCHREALTIME
  __zshrc_timer_start=$EPOCHREALTIME
  function _zshrc_timing_log() {
    local label=$1
    local now=$EPOCHREALTIME
    local elapsed=$(( (now - __zshrc_timer_start) * 1000 ))
    printf "⏱️  %-25s %6.1f ms\n" "$label" "$elapsed"
    __zshrc_timer_start=$now
  }
else
  function _zshrc_timing_log() { :; }
fi

# 📌 ── Shared Paths ────────────────────────────────────────────────────
source "$HOME/.dotfiles/scripts/lib/paths.sh"
source "$HOME/.dotfiles/scripts/lib/brew.sh"

# 🌐 ── Zinit Plugin Manager ──────────────────────────────────────────
if [[ -f "$ZINIT_HOME/zinit.zsh" ]]; then
  source "$ZINIT_HOME/zinit.zsh"
else
  echo "Zinit not found, please run the install script again." >&2
fi

# Plugins (loaded synchronously — small and needed on first keystroke)
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
zinit light Aloxaf/fzf-tab
_zshrc_timing_log "zinit"

# 🌍 ── Environment ───────────────────────────────────────────────────
export TERM="xterm-256color"

path_prepend() {
  [[ -d "$1" ]] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}

path_append() {
  [[ -d "$1" ]] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$PATH:$1" ;;
  esac
}

# Personal/user binaries
path_prepend "$HOME/.dotfiles/bin"
path_prepend "$HOME/.local/bin"
path_append "/snap/bin"

export PATH
_zshrc_timing_log "env setup"

# 📝 ── History Settings ──────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=5000

setopt HIST_IGNORE_SPACE
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt APPEND_HISTORY

unsetopt SHARE_HISTORY
_zshrc_timing_log "history"

# 🍺 ── Homebrew ──────────────────────────────────────────────────────
brew_ensure_path
_zshrc_timing_log "homebrew"

# 🔧 ── mise (language runtimes) ───────────────────────────────────────
# Add shims directly — avoids spawning mise on every shell start.
# Use 'eval "$(mise activate zsh)"' if you need per-project auto-switching.
path_prepend "${MISE_DATA_DIR:-$HOME/.local/share}/mise/shims"
_zshrc_timing_log "mise"

# 🔐 ── SSH Agent ─────────────────────────────────────────────────────
if ! pgrep -u "${USER:-$(whoami)}" ssh-agent >/dev/null 2>&1; then
  eval "$(ssh-agent -s)" >/dev/null
fi
alias addkey='ssh-add "$(find ~/.ssh -maxdepth 1 -name "id_ed25519*" ! -name "*.pub" | head -1)"'
_zshrc_timing_log "ssh-agent"

# 📁 ── Aliases: File Navigation ──────────────────────────────────────
alias ls='lsd --group-dirs=first --icon=always'
alias ll='ls -lh'
alias la='ls -A'
alias lla='ls -lAh'
_zshrc_timing_log "file nav aliases"

# 🐳 ── Aliases: Docker ───────────────────────────────────────────────
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dlogs='docker logs --tail 100 -f'
alias dexec='docker exec -it'
alias ddf='docker system df'                        # disk usage breakdown
alias dprune='docker system prune -f'               # safe: stopped containers, dangling images, unused networks

# 🐳 ── Aliases: Docker Compose ──────────────────────────────────────
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f --tail=50'
alias dcr='docker compose restart'
alias dcps='docker compose ps'
alias dcb='docker compose build'
_zshrc_timing_log "docker aliases"

# 🌱 ── Aliases: Git ──────────────────────────────────────────────────
alias gcl='git clone'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gpl='git pull --rebase'
alias gpr='git pull --rebase --autostash'
alias gs='git status'
alias gb='git branch'
alias gco='git checkout'
alias gm='git merge'
_zshrc_timing_log "git aliases"

# 🛠️ ── Aliases: Utility ─────────────────────────────────────────────
alias reload='source ~/.zshrc'
alias reload-t='SOURCE_TIMING=true source ~/.zshrc'
alias py='python3'
alias ipy='ipython'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias vo='vault-open'
alias vc='vault-close'
_zshrc_timing_log "utility aliases"

# 🛠️ ── Aliases: Personal Scripts ────────────────────────────────────
alias us='bash ~/.dotfiles/scripts/maintenance/update.sh'
alias clup='bash ~/.dotfiles/scripts/maintenance/clean.sh'
alias book='rustup doc --book 2>/dev/null'
_zshrc_timing_log "script aliases"

# ⚙️ ── Functions ─────────────────────────────────────────────────────
mkcd() { mkdir -p "$1" && cd "$1"; }

# Tmux workspace launchers — attach if exists, create with layout if not
# Usage: dashboard [path]   agents [path]
dashboard() {
  local dir="${1:-.}"
  dir=$(cd "$dir" 2>/dev/null && pwd) || { echo "Invalid path: $1"; return 1; }
  if tmux has-session -t dashboard 2>/dev/null; then
    tmux attach -t dashboard
    return
  fi
  tmux new-session -d -s dashboard -c "$dir"
  tmux send-keys -t dashboard 'lazygit' Enter
  tmux split-window -h -t dashboard -c "$dir"
  tmux send-keys -t dashboard 'lazydocker' Enter
  tmux split-window -v -f -t dashboard -p 20 -c "$dir"
  tmux send-keys -t dashboard 'docker compose logs -f --tail=50' Enter
  tmux select-pane -t dashboard:0.0
  tmux attach -t dashboard
}

agents() {
  local dir="${1:-.}"
  dir=$(cd "$dir" 2>/dev/null && pwd) || { echo "Invalid path: $1"; return 1; }
  if tmux has-session -t agents 2>/dev/null; then
    tmux attach -t agents
    return
  fi
  tmux new-session -d -s agents -c "$dir"
  tmux send-keys -t agents 'claude' Enter
  tmux split-window -h -t agents -c "$dir"
  tmux send-keys -t agents 'codex' Enter
  tmux select-pane -t agents:0.0
  tmux attach -t agents
}

_zshrc_timing_log "functions"

# 💬 ── Prompt (starship) ─────────────────────────────────────────────
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
else
  PROMPT='%F{blue}%n@%m%f:%F{cyan}%~%f %# '
fi
_zshrc_timing_log "prompt"

# ⌨️  ── Keybindings ──────────────────────────────────────────────────
autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic

bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word
bindkey "^[[3;5~" kill-word
bindkey "^H" backward-kill-word
bindkey "^[[1;5A" history-search-backward
bindkey "^[[1;5B" history-search-forward
_zshrc_timing_log "keybindings"

# 🔄 ── Completion ────────────────────────────────────────────────────
autoload -Uz compinit
local zcd="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"
mkdir -p "${zcd:h}"
if [[ -s "$zcd" && $(date +'%j') == $(stat -c '%j' "$zcd" 2>/dev/null || stat -f '%Sm' -t '%j' "$zcd" 2>/dev/null) ]]; then
  compinit -C -d "$zcd"
else
  compinit -d "$zcd"
  { zcompile "$zcd" } &!
fi
_zshrc_timing_log "compinit"

# 🧭 ── zoxide ────────────────────────────────────────────────────────
[[ ! -o interactive ]] && export _ZO_DOCTOR=0   # suppress false positives in non-interactive shells
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init --cmd cd zsh)"
fi
alias zi='__zoxide_zi'
_zshrc_timing_log "zoxide"

# 🕒 ── Final Timing Output ───────────────────────────────────────────
if [[ $SOURCE_TIMING == "true" ]]; then
  local __zshrc_total=$(( (EPOCHREALTIME - __zshrc_timer_origin) * 1000 ))
  printf "🕒 .zshrc fully loaded in %.0f ms\n" "$__zshrc_total"
fi

