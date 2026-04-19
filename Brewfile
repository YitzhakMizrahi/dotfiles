# ╭────────────────────────────────────────────────────────────╮
# │                    Brewfile                                │
# ╰────────────────────────────────────────────────────────────╯
# Usage: brew bundle --file=~/.dotfiles/Brewfile
# Idempotent — safe to run repeatedly.

# ── Runtime & Version Manager ─────────────────────────────────
brew "mise"                # Polyglot version manager (Python, Node, Go, Rust)

# ── Core CLI Tools ────────────────────────────────────────────
brew "git"                 # Version control
brew "zsh"                 # Shell
brew "tmux"                # Terminal multiplexer
brew "curl"                # HTTP client
brew "wget"                # HTTP client

# ── Modern CLI Replacements ───────────────────────────────────
brew "bat"                 # cat replacement with syntax highlighting
brew "eza"                 # ls replacement with icons
brew "fd"                  # find replacement
brew "ripgrep"             # grep replacement
brew "fzf"                 # Fuzzy finder
brew "zoxide"              # cd replacement (smart directory jumper)
brew "git-delta"           # Git diff pager
brew "duf"                 # df replacement (disk usage)
brew "dust"                # du replacement (directory space usage)
brew "jq"                  # JSON processor

# ── Dev Tools ─────────────────────────────────────────────────
brew "gum"                 # Elegant shell script UI (Charmbracelet)
brew "gh"                  # GitHub CLI
brew "lazygit"             # Git TUI
brew "lazydocker"          # Docker TUI
brew "yazi"                # Terminal file manager
brew "btop"                # System monitor
brew "starship"            # Cross-shell prompt
brew "tldr"                # Simplified man pages
brew "fastfetch"           # System info (replaces neofetch)
brew "ffmpeg"              # Audio/video swiss-army knife (transcoding, thumbs, capture, transitive dep of yt-dlp, whisper, etc.)

# ── Editor ────────────────────────────────────────────────────
brew "neovim"              # Modal editor

# ── Language Tooling ──────────────────────────────────────────
brew "uv"                  # Python package & project manager (pip/venv/pipx replacement)

# ── Terminal (macOS only — Linux installs via dnf/copr/etc.) ──
cask "ghostty" if OS.mac?  # Modern GPU-accelerated terminal (Mitchell Hashimoto)
