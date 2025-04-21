# ⏱️ ── Optional Timing Flag ──────────────────────────────────────────────
if [[ $SOURCE_TIMING == "true" ]]; then
  __zshrc_timer_start=$(date +%s%N)
  function _zshrc_timing_log() {
    local label=$1
    local now=$(date +%s%N)
    local elapsed=$(( (now - __zshrc_timer_start) / 1000000 ))
    echo "⏱️  ${label} loaded at ${elapsed} ms"
    __zshrc_timer_start=$now
  }
else
  function _zshrc_timing_log() { :; }
fi

# 🌐 ── Zinit Plugin Manager ──────────────────────────────────────────────
if [[ ! -f "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git/zinit.zsh" ]]; then
  echo "Zinit not found, please run the install script again."
else
  source "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git/zinit.zsh"
fi

# Load plugins
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
zinit light Aloxaf/fzf-tab
# zinit ice wait"0" atinit"echo ⚡ starship loading..."
zinit light starship/starship
_zshrc_timing_log "zinit"

# 🌍 ── Environment ────────────────────────────────────────────────────────
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.dotfiles/scripts:$PATH"
export TERM="xterm-256color"

# 🐧 Add Snap support for tools like lxc
export PATH="$PATH:/snap/bin"

_zshrc_timing_log "env setup"

# 📝 ── History Settings ───────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

setopt HIST_IGNORE_ALL_DUPS     # Remove older duplicate commands
setopt HIST_REDUCE_BLANKS       # Trim redundant spaces
setopt HIST_VERIFY              # Confirm before executing history expansions
setopt APPEND_HISTORY           # Don’t overwrite history file
setopt SHARE_HISTORY            # Sync history across terminal sessions
_zshrc_timing_log "history"

# 🍺 ── Homebrew ───────────────────────────────────────────────────────────
if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
  eval "$($HOME/.linuxbrew/bin/brew shellenv)"
elif [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
_zshrc_timing_log "homebrew"

# 🟨 ── Go (goenv) ──────────────────────────────────────────────────────────
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)"
_zshrc_timing_log "goenv"

# 🐍 ── pyenv ──────────────────────────────────────────────────────────────
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init - zsh)"
  eval "$(pyenv virtualenv-init -)"
fi
_zshrc_timing_log "pyenv"

# 🟢 ── Lazy-load NVM ──────────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
nvm() { unset -f nvm; source "$NVM_DIR/nvm.sh"; nvm "$@"; }
node() { unset -f node; source "$NVM_DIR/nvm.sh"; node "$@"; }
npm() { unset -f npm; source "$NVM_DIR/nvm.sh"; npm "$@"; }
_zshrc_timing_log "nvm (lazy)"

# 🔐 ── SSH Agent ──────────────────────────────────────────────────────────
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
  eval "$(ssh-agent -s)" > /dev/null
fi
alias addkey='ssh-add ~/.ssh/id_ed25519'
_zshrc_timing_log "ssh-agent"

# 📁 ── Aliases: File Navigation ───────────────────────────────────────────
alias ls='lsd --group-dirs=first --icon=always'
alias ll='ls -lh'
alias la='ls -A'
alias lla='ls -lAh'
_zshrc_timing_log "file nav aliases"

# 🐳 ── Aliases: Docker ────────────────────────────────────────────────────
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dlogs='docker logs --tail 100 -f'
alias dexec='docker exec -it'
alias dstop='docker stop $(docker ps -q)'
alias dclean='docker container prune -f && docker system prune -a -f --volumes'
_zshrc_timing_log "docker aliases"

# 🌱 ── Aliases: Git ───────────────────────────────────────────────────────
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

# 🛠️ ── Aliases: Utility ─────────────────────────────────────────
alias reload='source ~/.zshrc'
alias please='sudo $(fc -ln -1)'
alias py='python3'
alias ipy='ipython'
alias rm='rm -i'
_zshrc_timing_log "utility aliases"

# 🛠️ ── Aliases: Personal Scripts ─────────────────────────────────────────
alias sl='bash ~/.dotfiles/scripts/scripts_list.sh'
alias us='bash ~/.dotfiles/scripts/update_system.sh'
alias clup='bash ~/.dotfiles/scripts/cleanup.sh'
alias diu='bash ~/.dotfiles/scripts/disk_usage.sh'
_zshrc_timing_log "script aliases"

# 🧪 ── Debugging / Reloading ──────────────────────────────────────────────
alias zshrc='SOURCE_TIMING=true source ~/.zshrc'

# 🔧 ── Utility Functions ──────────────────────────────────────────────────
mkcd() { mkdir -p "$1" && cd "$1"; }
_zshrc_timing_log "functions"

# 💬 ── Prompt (starship) ─────────────────────────────────────────────────
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
  export STARSHIP_CONFIG="$HOME/.config/starship.toml"
else
  # fallback prompt
  PROMPT='%F{blue}%n@%m%f:%F{cyan}%~%f %# '
fi
_zshrc_timing_log "prompt"

# ⌨️ ── Keybindings ────────────────────────────────────────────────────────
bindkey '^H' backward-kill-word          # Ctrl+Backspace
bindkey '^[[3;5~' kill-word              # Ctrl+Delete
bindkey '^[[1;5A' history-search-backward
bindkey '^[[1;5B' history-search-forward
_zshrc_timing_log "keybindings"

# 🔄 ── Completion ─────────────────────────────────────────────────────────
autoload -U compinit && compinit
_zshrc_timing_log "compinit"

# 🧭 ── zoxide (smart cd) ──────────────────────────────────────────────────
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init --cmd cd zsh)"
fi
alias zi='__zoxide_zi'
_zshrc_timing_log "zoxide"

# Auto attach to tmux session if not already inside one
# if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
#   tmux attach -t default || tmux new -s default
# fi

# 🕒 ── Final Timing Output ────────────────────────────────────────────────
if [[ $SOURCE_TIMING == "true" ]]; then
  ZSHRC_END_TIME=$(date +%s%N)
  ZSHRC_DURATION_MS=$(( (ZSHRC_END_TIME - __zshrc_timer_start) / 1000000 ))
  echo "🕒 .zshrc fully loaded in ${ZSHRC_DURATION_MS} ms"
fi
