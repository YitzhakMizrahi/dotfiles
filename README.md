# 🧠 Dotfiles

Personal dotfiles for WSL/Linux development environment, optimized for productivity, clarity, and easy bootstrapping.

## 📦 Contents

- `.zshrc` with lazy-loading, Homebrew, pyenv, nvm, and aliases
- `scripts/` directory with utilities like system updates, cleanup, and disk usage
- Git, Docker, and command aliases
- Optional SSH agent setup
- Ready for dotfile syncing across machines

## ⚡️ Getting Started

Clone and symlink:

```bash
git clone git@github.com:YitzhakMizrahi/dotfiles.git ~/.dotfiles
ln -sf ~/.dotfiles/.zshrc ~/.zshrc
ln -sf ~/.dotfiles/.tmux.conf ~/.tmux.conf
ln -sf ~/.dotfiles/.gitconfig ~/.gitconfig
ln -sf ~/.dotfiles/.config/yazi ~/.config/yazi
ln -sf ~/.dotfiles/.config/lazygit ~/.config/lazygit
ln -sf ~/.dotfiles/.config/gh ~/.config/gh


