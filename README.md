# Dotfiles

Personal dotfiles — modular, declarative, and tested. Designed for Ubuntu/WSL2 and macOS.

---

## Quick Start

```bash
git clone https://github.com/YitzhakMizrahi/dotfiles.git ~/.dotfiles
dotfiles install
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

## Adding & Removing

This repo follows a **single source of truth** principle. Each type of
configuration lives in exactly one file. Installation, updates, doctor
checks, and CI tests all read from these files dynamically — no
secondary lists to update.

### CLI tools

Edit `Brewfile`, then run `dotfiles update`:

```bash
# Add
echo 'brew "newtool"' >> Brewfile
dotfiles update

# Remove — delete the line from Brewfile, then:
brew uninstall newtool
```

### Language runtimes

Edit `.mise.toml`, then run `mise install`:

```bash
# In .mise.toml under [tools]:
#   python = "latest"
mise install
```

### Symlinks (config files)

Edit the `SYMLINKS` map in `scripts/setup/symlinks.sh`:

```bash
# Add an entry:
#   ["~/.config/foo/config.yml"]="~/.dotfiles/.config/foo/config.yml"
dotfiles update    # re-links everything
```

### Shared paths & constants

All shared paths live in `scripts/lib/paths.sh` (sourced by every script
and `.zshrc`). Change a path there and it propagates everywhere.

---

## Tool Management

| Layer | Managed by | Config file |
|-------|-----------|-------------|
| CLI tools | Homebrew | `Brewfile` |
| Language runtimes | mise | `.mise.toml` |
| Shell plugins | Zinit | `.zshrc` |
| Prompt | Starship | `.config/starship.toml` |
| Configs | Symlinks | `scripts/setup/symlinks.sh` |

---

## Scripts

| Script | Purpose |
|--------|---------|
| `bin/dotfiles` | CLI — test, update, doctor, edit |
| `scripts/install.sh` | Main orchestrator |
| `scripts/doctor.sh` | Version checks and final checklist |
| `scripts/setup/symlinks.sh` | Symlinks tracked config files |
| `scripts/setup/fonts.sh` | Nerd Font detection and install |
| `scripts/setup/shell.sh` | Default shell (chsh) |
| `scripts/setup/git-ssh.sh` | Git identity and SSH key setup |
| `scripts/maintenance/update.sh` | APT system update |
| `scripts/maintenance/clean.sh` | Interactive cache/trash cleanup |
| `scripts/test/validate.sh` | CI validation (Docker) |

### Shared libraries

| Library | Purpose |
|---------|---------|
| `scripts/lib/ui.sh` | UI components (banner, spinner, confirm, colors) |
| `scripts/lib/paths.sh` | Central path constants (DOTFILES_DIR, ZINIT_HOME, etc.) |
| `scripts/lib/brew.sh` | Homebrew path detection (`brew_ensure_path`) |
| `scripts/lib/tools.sh` | Brewfile/mise parser and formula-to-command mapping |
| `scripts/lib/logging.sh` | Legacy logging helpers |

---

## Testing

```bash
# Full isolated CI test via Docker
dotfiles test

# Interactive test — see Gum UI, prompts, full experience
dotfiles test -i

# Check current machine state
dotfiles doctor

# Pull latest + update tools + re-link
dotfiles update

# Open dotfiles in $EDITOR
dotfiles edit
```

---

## Key Decisions

- **Brewfile over imperative scripts** — declarative, idempotent, reviewable
- **mise over pyenv/nvm/goenv** — single tool for all language runtimes
- **Single source of truth** — Brewfile, .mise.toml, and symlinks.sh drive all validation dynamically
- **Symlinks only where necessary** — PATH and env vars preferred where possible
- **Gum UI library** — elegant terminal output with Gruvbox theme, ANSI fallback
- **CI mode** — `DOTFILES_CI=1` skips interactive prompts for automated testing

---

## Inspiration

- [Mathias Bynens](https://github.com/mathiasbynens/dotfiles)
- [Zinit Plugin Ecosystem](https://github.com/zdharma-continuum/zinit)
- [Starship Prompt](https://starship.rs/)
- [Charmbracelet Gum](https://github.com/charmbracelet/gum)
