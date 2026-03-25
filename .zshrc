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

# Plugins ─────────────────────────────────────────────────────────────
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
zinit light Aloxaf/fzf-tab
zinit light starship/starship
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
path_prepend "$HOME/bin"
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/.cargo/bin"

# Optional tool paths
path_prepend "$HOME/tools/godot"
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
if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
  eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
elif [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
_zshrc_timing_log "homebrew"

# 🟨 ── Go (goenv) ────────────────────────────────────────────────────
export GOENV_ROOT="$HOME/.goenv"
path_prepend "$GOENV_ROOT/bin"
if command -v goenv >/dev/null 2>&1; then
  eval "$(goenv init -)"
fi
_zshrc_timing_log "goenv"

# 🐍 ── Python (pyenv) ────────────────────────────────────────────────
export PYENV_ROOT="$HOME/.pyenv"
path_prepend "$PYENV_ROOT/bin"
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init - zsh)"
  if pyenv commands | grep -qx 'virtualenv-init'; then
    eval "$(pyenv virtualenv-init -)"
  fi
fi
_zshrc_timing_log "pyenv"

# 🟢 ── Lazy-load NVM ─────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  nvm()  { unset -f nvm node npm npx; source "$NVM_DIR/nvm.sh"; nvm "$@"; }
  node() { unset -f nvm node npm npx; source "$NVM_DIR/nvm.sh"; node "$@"; }
  npm()  { unset -f nvm node npm npx; source "$NVM_DIR/nvm.sh"; npm "$@"; }
  npx()  { unset -f nvm node npm npx; source "$NVM_DIR/nvm.sh"; npx "$@"; }
fi
_zshrc_timing_log "nvm (lazy)"

# 🔐 ── SSH Agent ─────────────────────────────────────────────────────
if ! pgrep -u "$USER" ssh-agent >/dev/null; then
  eval "$(ssh-agent -s)" >/dev/null
fi
alias addkey='ssh-add ~/.ssh/id_ed25519'
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
alias dstop='docker stop $(docker ps -q)'
alias dclean='docker container prune -f && docker system prune -a -f --volumes'
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
alias us='bash ~/.dotfiles/scripts/update-system.sh'
alias clup='bash ~/.dotfiles/scripts/clean-system.sh'
alias book='firefox ~/books/book/book/index.html 2>/dev/null'
_zshrc_timing_log "script aliases"

# ⚙️ ── Functions ─────────────────────────────────────────────────────
mkcd() { mkdir -p "$1" && cd "$1"; }
_zshrc_timing_log "functions"

# 💬 ── Prompt (starship) ─────────────────────────────────────────────
if command -v starship >/dev/null 2>&1; then
  export STARSHIP_CONFIG="$HOME/.config/starship.toml"
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
fi
_zshrc_timing_log "compinit"

# 🧭 ── zoxide ────────────────────────────────────────────────────────
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init --cmd cd zsh)"
fi
alias zi='__zoxide_zi'
_zshrc_timing_log "zoxide"

# 🕒 ── Final Timing Output ───────────────────────────────────────────
if [[ $SOURCE_TIMING == "true" ]]; then
  ZSHRC_END_TIME=$(date +%s%N)
  ZSHRC_DURATION_MS=$(( (ZSHRC_END_TIME - __zshrc_timer_start) / 1000000 ))
  echo "🕒 .zshrc fully loaded in ${ZSHRC_DURATION_MS} ms"
fi

if [[ -s "$NVM_DIR/bash_completion" ]]; then
  . "$NVM_DIR/bash_completion"
fi