# Dotfiles

Personal dotfiles — modular, declarative, and tested. Designed for Ubuntu/WSL2 and macOS.

---

## Quick Start

```bash
git clone https://github.com/YitzhakMizrahi/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
bash scripts/install.sh
```

> Don't run as root. The installer will guide you through setup interactively.

---

## How It Works

The installer is a thin orchestrator that runs these steps in order:

1. **APT base tools** — git, zsh, tmux, curl, wget, build-essential (Linux/WSL)
2. **Homebrew** — installed if missing, then `brew bundle` from `Brewfile`
3. **Language runtimes** — Python, Node, Go, Rust via `mise` and `.mise.toml`
4. **Symlinks** — tracked configs linked to `$HOME`
5. **Fonts** — Nerd Font detection and optional install
6. **Shell** — Zinit plugin manager, optional chsh to Zsh
7. **Git & SSH** — identity config (`~/.gitconfig.local`), SSH key setup
8. **Validation** — tool versions, symlink checks, runtime verification

---

## Tool Management

| Layer | Managed by | Config file |
|-------|-----------|-------------|
| CLI tools | Homebrew | `Brewfile` |
| Language runtimes | mise | `.mise.toml` |
| Shell plugins | Zinit | `.zshrc` |
| Prompt | Starship | `.config/starship.toml` |
| Configs | Symlinks | `scripts/setup-symlinks.sh` |

---

## Scripts

| Script | Purpose |
|--------|---------|
| `install.sh` | Main orchestrator |
| `setup-symlinks.sh` | Symlinks tracked config files |
| `setup-fonts.sh` | Nerd Font detection and install |
| `setup-shell.sh` | Zinit install, chsh offer |
| `setup-git-ssh.sh` | Git identity and SSH key setup |
| `post-cleanup.sh` | Temp file and package cleanup |
| `post-validate.sh` | Version checks and final checklist |
| `clean-system.sh` | Interactive cache/trash cleanup |
| `update-system.sh` | APT system update |
| `test-validate.sh` | CI validation (Docker/LXC) |

---

## Testing

```bash
# Docker (full isolated test)
docker build --network host -f Dockerfile.test -t dotfiles-test .

# LXC (local sandbox)
bin/lxc-dev test
```

---

## Key Decisions

- **Brewfile over imperative scripts** — declarative, idempotent, reviewable
- **mise over pyenv/nvm/goenv** — single tool for all language runtimes
- **Symlinks only where necessary** — PATH and env vars preferred where possible
- **Gum UI library** — elegant terminal output with Gruvbox theme, ANSI fallback
- **CI mode** — `DOTFILES_CI=1` skips interactive prompts for automated testing

---

## Inspiration

- [Mathias Bynens](https://github.com/mathiasbynens/dotfiles)
- [Zinit Plugin Ecosystem](https://github.com/zdharma-continuum/zinit)
- [Starship Prompt](https://starship.rs/)
- [Charmbracelet Gum](https://github.com/charmbracelet/gum)
