# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# export PATH=$HOME/bin:/usr/local/bin:$PATH
export DOTNET_ROOT=$HOME/.dotnet
export PATH="$HOME/scripts:$HOME/.config/composer/vendor/bin:/home/etrog/miniconda3/bin:$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH"

# Set ZSH theme
ZSH_THEME="robbyrussell"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting docker npm python sudo web-search)

source $ZSH/oh-my-zsh.sh

# User configuration

## Aliases

# python
alias python=python3

#logo-ls
alias ls='logo-ls'
alias la='logo-ls -A'
alias lla='logo-ls -la'

#git
alias gs='git status'
alias gcm='git commit -m'
alias gco='git checkout'
alias gcob='git checkout -b'

## Scripts:
alias sl='bash ~/scripts/scripts_list.sh'
alias us='bash ~/scripts/update_system.sh'
alias clup='bash ~/scripts/cleanup.sh'
alias diu='bash ~/scripts/disk_usage.sh'


## Functions:

# mkcd makes a directory and navigates into it
mkcd() { mkdir -p "$@" && cd "$_"; }

## >>> conda initialize >>>
__conda_setup="$('/home/etrog/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/etrog/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/etrog/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/etrog/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
## <<< conda initialize <<<

## Keyboard Shortcuts
# Ctrl+Backspace
bindkey '^H' backward-kill-word
# Ctrl+Delete
bindkey '^[[3;5~' kill-word

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
