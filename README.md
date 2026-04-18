# Dotfiles

Personal dotfiles — modular, declarative, and tested. Designed for Ubuntu/WSL2, Fedora, and macOS.

---

## Quick Start

```bash
git clone https://github.com/YitzhakMizrahi/dotfiles.git ~/.dotfiles
bash ~/.dotfiles/scripts/install.sh
```

> After install, the `dotfiles` CLI is available: `dotfiles update`, `dotfiles doctor`, etc.

> Don't run as root. The installer will guide you through setup interactively.

---

## How It Works

The installer is a thin orchestrator that runs these steps in order:

1. **Base tools** — git, zsh, tmux, curl, wget, unzip, build tools, gocryptfs (apt on Debian/Ubuntu, dnf on Fedora)
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
#   python = "3.13"
mise install
```

### Symlinks (config files)

Edit the `SYMLINKS` list in `scripts/setup/symlinks.sh`:

```bash
# Add an entry (format: "target|source"):
#   "~/.config/foo/config.yml|~/.dotfiles/.config/foo/config.yml"
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
| Terminal | WezTerm | `.config/wezterm/wezterm.lua` |
| Configs | Symlinks | `scripts/setup/symlinks.sh` |

---

## Scripts

| Script | Purpose |
|--------|---------|
| `bin/dotfiles` | CLI — install, update, doctor, test, edit |
| `scripts/install.sh` | Main orchestrator |
| `scripts/doctor.sh` | Version checks and final checklist |
| `scripts/setup/symlinks.sh` | Symlinks tracked config files |
| `scripts/setup/fonts.sh` | Nerd Font detection and install |
| `scripts/setup/shell.sh` | Default shell (chsh) |
| `scripts/setup/git-ssh.sh` | Git identity and SSH key setup |
| `scripts/maintenance/update.sh` | System update (apt or dnf) |
| `scripts/maintenance/clean.sh` | Interactive cache/trash cleanup |
| `scripts/test/validate.sh` | CI validation (Docker + macOS) |

### Shared libraries

| Library | Purpose |
|---------|---------|
| `scripts/lib/ui.sh` | UI components (banner, spinner, confirm, colors) |
| `scripts/lib/paths.sh` | Central path constants (DOTFILES_DIR, ZINIT_HOME, etc.) |
| `scripts/lib/brew.sh` | Homebrew path detection (`brew_ensure_path`) |
| `scripts/lib/tools.sh` | Brewfile/mise parser and formula-to-command mapping |

---

## CLI

```bash
dotfiles update       # Pull latest, upgrade tools and runtimes, re-link
dotfiles doctor       # Validate tools, symlinks, runtimes, environment
dotfiles test         # Full CI test via Docker (automated)
dotfiles test -i      # Interactive Docker test (see Gum UI, prompts)
dotfiles edit         # Open dotfiles directory in $EDITOR
```

## Testing

CI runs on both Linux (Docker) and macOS (native):

```bash
dotfiles test         # Build and validate locally via Docker
```

Set `DOTFILES_CI=1` to run the installer non-interactively (skips prompts,
uses defaults). This is what CI and `dotfiles test` use internally.

On WSL, font installation is automatically skipped (use your Windows
terminal's font settings instead). Override with `DOTFILES_FORCE_FONTS=1`
for testing.

---

## Fedora Notes

- `dnf` installs `@development-tools` plus `git`, `zsh`, `tmux`, `curl`,
  `wget`, `unzip`, `procps-ng`, `file`, and `gocryptfs` before Homebrew
  bootstraps. `@development-tools` works on both `dnf4` and `dnf5`.
- **Immutable variants** (Silverblue, Kinoite, Bluefin, Bazzite) ship a
  read-only host filesystem, so `install.sh` detects `/run/ostree-booted`
  and exits early with instructions to run inside a mutable container:

  ```bash
  toolbox create --distro fedora
  toolbox enter
  bash ~/.dotfiles/scripts/install.sh
  ```

- Tested on traditional Fedora Workstation via CI (`Dockerfile.fedora.test`).

---

## Key Decisions

- **Brewfile over imperative scripts** — declarative, idempotent, reviewable
- **mise over pyenv/nvm/goenv** — single tool for all language runtimes
- **Single source of truth** — Brewfile, .mise.toml, and symlinks.sh drive all validation dynamically
- **Symlinks only where necessary** — PATH and env vars preferred where possible
- **Gum UI library** — elegant terminal output with Gruvbox theme, ANSI fallback
- **Cross-platform** — all scripts portable to macOS (Bash 3.2 + BSD tools), CI runs on both Linux and macOS
- **Unified terminal config** — single `wezterm.lua` with platform detection, auto-synced to Windows on WSL
- **CI mode** — `DOTFILES_CI=1` skips interactive prompts for automated testing

---

## Inspiration

- [Mathias Bynens](https://github.com/mathiasbynens/dotfiles)
- [Zinit Plugin Ecosystem](https://github.com/zdharma-continuum/zinit)
- [Starship Prompt](https://starship.rs/)
- [Charmbracelet Gum](https://github.com/charmbracelet/gum)
