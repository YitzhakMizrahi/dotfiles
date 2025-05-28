# ⏱️ ── Optional Timing Flag ───────────────────────────────────────────
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

# 🌐 ── Zinit Plugin Manager ──────────────────────────────────────────
if [[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git/zinit.zsh" ]]; then
  source "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git/zinit.zsh"
else
  echo "Zinit not found, please run the install script again." >&2
fi

# Plugins ───────────────────────────────────────────────────────────────
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
zinit light Aloxaf/fzf-tab
zinit light starship/starship
_zshrc_timing_log "zinit"

# 🌍 ── Environment ─────────────────────────────────────────────────────
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.dotfiles/scripts:$PATH"
# NEW: local user binaries first so lsd / starship via cargo/pipx work
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
export TERM="xterm-256color"
# Snap support
export PATH="$PATH:/snap/bin"
_zshrc_timing_log "env setup"

# 📝 ── History Settings ───────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_VERIFY \
       APPEND_HISTORY SHARE_HISTORY
_zshrc_timing_log "history"

# 🍺 ── Homebrew ───────────────────────────────────────────────────────
if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
  eval "$( $HOME/.linuxbrew/bin/brew shellenv)"
elif [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
_zshrc_timing_log "homebrew"

# 🟨 ── Go (goenv) ───────────────────────────────────────────────────────
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)"
_zshrc_timing_log "goenv"

# 🐍 ── pyenv ───────────────────────────────────────────────────────────────
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init - zsh)"
  eval "$(pyenv virtualenv-init -)"
fi
_zshrc_timing_log "pyenv"

# 🟢 ── Lazy‑load NVM ───────────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
nvm()  { unset -f nvm ; source "$NVM_DIR/nvm.sh" ; nvm  "$@"; }
node() { unset -f node; source "$NVM_DIR/nvm.sh" ; node "$@"; }
npm()  { unset -f npm ; source "$NVM_DIR/nvm.sh" ; npm  "$@"; }
_zshrc_timing_log "nvm (lazy)"

# 🔐 ── SSH Agent ───────────────────────────────────────────────────────────────
if ! pgrep -u "$USER" ssh-agent >/dev/null; then
  eval "$(ssh-agent -s)" >/dev/null
fi
alias addkey='ssh-add ~/.ssh/id_ed25519'
_zshrc_timing_log "ssh-agent"

# 📁 ── Aliases: File Navigation ───────────────────────────────────────────────────────
alias ls='lsd --group-dirs=first --icon=always'
alias ll='ls -lh'
alias la='ls -A'
alias lla='ls -lAh'
_zshrc_timing_log "file nav aliases"

# 🐳 ── Aliases: Docker ───────────────────────────────────────────────────────
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

# 🛠️ ── Aliases: Utility ───────────────────────────────────────────────────────
alias reload='source ~/.zshrc'
alias reload-t='SOURCE_TIMING=true source ~/.zshrc'
alias please='sudo $(fc -ln -1)'
alias py='python3'
alias ipy='ipython'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
_zshrc_timing_log "utility aliases"

# 🛠️ ── Aliases: Personal Scripts ───────────────────────────────────────
alias sl='bash ~/.dotfiles/scripts/scripts_list.sh'
alias us='bash ~/.dotfiles/scripts/update_system.sh'
alias clup='bash ~/.dotfiles/scripts/cleanup.sh'
alias diu='bash ~/.dotfiles/scripts/disk_usage.sh'
alias book='firefox ~/books/book/book/index.html 2>/dev/null'
_zshrc_timing_log "script aliases"

# ⚙️ ── Functions ───────────────────────────────────────────────────────
mkcd() { mkdir -p "$1" && cd "$1"; }

pkgx() {
  case "$1" in
    build)   go build -o build/bin/bootstrap-cli main.go ;;
    exec)    lxc exec bootstrap-test -- su - devuser ;;
    push)    lxc file push build/bin/bootstrap-cli bootstrap-test/home/devuser/bootstrap-cli --mode=755 ;;
    run)     shift ; lxc exec bootstrap-test -- su - devuser -c "cd /home/devuser && ./bootstrap-cli $*" ;;
    restore) lxc restore bootstrap-test clean-setup ;;
    *) echo "Usage: pkgx {build|push|run [args...]|restore}" ; return 1 ;;
  esac
}
_zshrc_timing_log "functions"

# 💬 ── Prompt (starship) ───────────────────────────────────────────────────────
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
  export STARSHIP_CONFIG="$HOME/.config/starship.toml"
else
  PROMPT='%F{blue}%n@%m%f:%F{cyan}%~%f %# '
fi
_zshrc_timing_log "prompt"

# ⌨️  ── Keybindings ───────────────────────────────────────────────────────
# Fix for paste errors (^[[200~) — enables bracketed paste
autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic
# Ctrl + Arrow: word movement
bindkey "^[[1;5C" forward-word        # Ctrl + →
bindkey "^[[1;5D" backward-word       # Ctrl + ←
# Ctrl + Del / Backspace: word deletion
bindkey "^[[3;5~" kill-word           # Ctrl + Delete
bindkey "^H" backward-kill-word       # Ctrl + Backspace
# Ctrl + Up/Down for history search
bindkey "^[[1;5A" history-search-backward
bindkey "^[[1;5B" history-search-forward
_zshrc_timing_log "keybindings"


# 🔄 ── Completion ───────────────────────────────────────────────────────
autoload -Uz compinit
# First run: create cache (-C); subsequent runs: normal
if [[ ! -f ${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION} ]]; then
  compinit -C
else
  compinit
fi
_zshrc_timing_log "compinit"

# 🧭 ── zoxide ───────────────────────────────────────────────────────
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init --cmd cd zsh)"
fi
alias zi='__zoxide_zi'
_zshrc_timing_log "zoxide"

# 🕒 ── Final Timing Output ───────────────────────────────────────────────
if [[ $SOURCE_TIMING == "true" ]]; then
  ZSHRC_END_TIME=$(date +%s%N)
  ZSHRC_DURATION_MS=$(( (ZSHRC_END_TIME - __zshrc_timer_start) / 1000000 ))
  echo "🕒 .zshrc fully loaded in ${ZSHRC_DURATION_MS} ms"
fi
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
