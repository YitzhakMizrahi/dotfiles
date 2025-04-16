# ── Optional Timing Flag ─────────────────────────────────────
if [[ $SOURCE_TIMING == "true" ]]; then
  __zshrc_timer_start=$(date +%s%N)
  function _zshrc_timing_log() {
    local label=$1
    local now=$(date +%s%N)
    local elapsed=$(( (now - __zshrc_timer_start) / 1000000 ))
    echo "⏱️ ${label} loaded at ${elapsed} ms"
    __zshrc_timer_start=$now
  }
else
  function _zshrc_timing_log() { :; }
fi

# ── oh-my-zsh Meta ───────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
_zshrc_timing_log "oh-my-zsh meta setup"

# ── Environment ──────────────────────────────────────────────
export PATH="$HOME/bin:$PATH"
export EDITOR="vim"
export TERM="xterm-256color"
_zshrc_timing_log "env setup"

# ── Homebrew ─────────────────────────────────────────────────
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
_zshrc_timing_log "homebrew"

# ── pyenv ─────────────────────────────────────────────────────
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"
eval "$(pyenv virtualenv-init -)"
_zshrc_timing_log "pyenv"

# ── Lazy-load NVM ────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"

nvm() {
  unset -f nvm
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm "$@"
}
node() {
  unset -f node
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  node "$@"
}
npm() {
  unset -f npm
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  npm "$@"
}
_zshrc_timing_log "nvm (lazy)"

# ── oh-my-zsh Init ───────────────────────────────────────────
source $ZSH/oh-my-zsh.sh
_zshrc_timing_log "oh-my-zsh"

# ── SSH Agent ────────────────────────────────────────────────
[ -f ~/.ssh/id_ed25519 ] && ssh-add ~/.ssh/id_ed25519 2>/dev/null
_zshrc_timing_log "ssh-agent"

# ── Aliases: LSD ─────────────────────────────────────────────
alias ls='lsd --group-dirs=first --icon=always'
alias ll='lsd -l --group-dirs=first --icon=always'
alias la='lsd -a --group-dirs=first --icon=always'
alias lla='lsd -la --group-dirs=first --icon=always'
_zshrc_timing_log "lsd aliases"

# ── Aliases: Docker ──────────────────────────────────────────
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dlogs='docker logs --tail 100 -f'
alias dexec='docker exec -it'
alias dstop='docker stop $(docker ps -a -q)'
alias dclean='docker rm $(docker ps -a -q) && docker system prune -a -f --volumes'
_zshrc_timing_log "docker aliases"

# ── Aliases: Git ─────────────────────────────────────────────
alias gcl='git clone'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gpl='git pull'
alias gs='git status'
alias gb='git branch'
alias gco='git checkout'
alias gm='git merge'
_zshrc_timing_log "git aliases"

# ── Aliases: Personal Scripts ───────────────────────────────
alias sl='bash ~/scripts/scripts_list.sh'
alias us='bash ~/scripts/update_system.sh'
alias clup='bash ~/scripts/cleanup.sh'
alias diu='bash ~/scripts/disk_usage.sh'
_zshrc_timing_log "script aliases"

# ── Debug Aliases ──────────────────────────────────────────
alias zshrc='SOURCE_TIMING=true source ~/.zshrc'

# ── Utility Functions ───────────────────────────────────────
mkcd() { mkdir -p "$@" && cd "$_"; }
_zshrc_timing_log "functions"

# ── Prompt (optional override) ──────────────────────────────
# PROMPT='%F{blue}%n@%m%f:%F{cyan}%~%f %# '
_zshrc_timing_log "prompt"

# ── Keybindings ─────────────────────────────────────────────
bindkey '^H' backward-kill-word          # Ctrl+Backspace
bindkey '^[[3;5~' kill-word              # Ctrl+Delete
_zshrc_timing_log "keybindings"

# ── Completion ──────────────────────────────────────────────
autoload -U compinit && compinit
_zshrc_timing_log "compinit"

# ── Final Timing Output ─────────────────────────────────────
if [[ $SOURCE_TIMING == "true" ]]; then
  ZSHRC_END_TIME=$(date +%s%N)
  ZSHRC_DURATION_MS=$(( (ZSHRC_END_TIME - __zshrc_timer_start) / 1000000 ))
  echo "🕒 .zshrc fully loaded in ${ZSHRC_DURATION_MS} ms"
fi
