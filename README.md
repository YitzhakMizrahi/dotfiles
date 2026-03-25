# ⚙️ Dotfiles

Welcome to my personal modular and polished **dotfiles setup** — designed for speed, clarity, and full control.

---

## 🧠 Features

- 🧩 Modular `install.sh` flow — step-by-step clarity
- 🔗 Clean symlink handling via `setup-symlinks.sh`
- 💻 Zsh shell enhancements (Zinit, Starship, plugins)
- 🄤 Nerd Font detection and optional installer
- 🐍 Python + Node version managers (pyenv, nvm)
- 🔐 Git identity & SSH key setup with GitHub integration hints
- 🧪 Final post-install validations
- 🧹 Optional cleanup of temporary and leftover files

---

## 🚀 Quick Start

```bash
# Clone your dotfiles
git clone https://github.com/YitzhakMizrahi/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Run the installer
bash scripts/install.sh
```

> 💡 Don’t run as root. This will guide you through safe setup and prompt you as needed.

---

## 📁 Modular Script Overview

| Script                  | Description                                      |
|-------------------------|--------------------------------------------------|
| `install.sh`            | The main launcher (calls other scripts)          |
| `setup-symlinks.sh`     | Symlinks all tracked config files                |
| `install-tools.sh`      | Installs tools (Homebrew, apt, etc)              |
| `setup-fonts.sh`        | Detects and optionally installs Nerd Fonts       |
| `setup-shell.sh`        | Zsh config with Zinit & Starship                 |
| `setup-languages.sh`    | Installs Python (pyenv) and Node (nvm)           |
| `setup-git-ssh.sh`      | Git identity, SSH key generation (no gh auth)    |
| `post-validate.sh`      | Confirms versions & shows a final checklist      |
| `post-cleanup.sh`       | Cleans temp folders and Homebrew/apt leftovers   |

---

## 🚰 Tooling Philosophy

This project assumes:

- You're using `zsh` with plugins and Starship prompt
- You want to control Git identity per-machine (`~/.gitconfig.local`)
- Fonts, visuals, and scripts should be **functional yet beautiful**
- Setup should be interactive but **fully traceable**

---

## 🤝 Contributing / Customizing

Fork it, personalize the prompt, tweak the aliases, or split into profiles — this dotfiles project is meant to grow with your system.

---

## ✨ Inspiration

- [Mathias Bynens](https://github.com/mathiasbynens/dotfiles)
- [Zinit Plugin Ecosystem](https://github.com/zdharma-continuum/zinit)
- [Starship Prompt](https://starship.rs/)

