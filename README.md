# Pedro's Dotfiles

Personal dotfiles configuration for macOS development environment.

## What's Included

- **Shell**: Zsh with Oh My Zsh, custom aliases, and productivity plugins
- **Node.js**: fnm (Fast Node Manager) with multiple Node versions
- **Package Managers**: Homebrew, pnpm, bun
- **Git**: Configuration with GPG signing via 1Password
- **Claude Code**: Settings, agents, hooks, and MCP configuration
- **Codex**: Configuration with MCP servers
- **Zed**: Editor settings and keybindings
- **SSH**: Host configurations for home lab
- **Development Tools**: Various CLI tools and utilities

## Prerequisites

- macOS
- Command Line Tools (`xcode-select --install`)

## Setup

```bash
# Clone this repository
git clone https://github.com/yourusername/dotfiles.git ~/dev/dotfiles
cd ~/dev/dotfiles

# Run interactive sync
./sync
```

## Sync Script

The `sync` script manages bidirectional dotfile synchronization between this repo and your system.

```bash
./sync            # Interactive mode — per-file prompts
./sync --status   # Show status table (no changes)
./sync --push     # Batch push: repo -> system
./sync --pull     # Batch pull: system -> repo
./sync --help     # Show usage and tracked files
```

**Sensitive files** (`.zshrc`, `.gitconfig`, `.codex/config.toml`, `.ssh/config`) are scanned for tokens before syncing to the repo.

## Manual Steps After First Setup

1. **Install Homebrew** (if not already installed):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Install packages**:
   ```bash
   brew bundle --file=./Brewfile
   ```

3. **Install Oh My Zsh + plugins**:
   ```bash
   sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
   git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
   git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
   git clone https://github.com/spaceship-prompt/spaceship-prompt.git ~/.oh-my-zsh/custom/themes/spaceship-prompt --depth=1
   ln -s ~/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme ~/.oh-my-zsh/custom/themes/spaceship.zsh-theme
   ```

4. **Push dotfiles to system**:
   ```bash
   ./sync --push
   ```

5. **Add your personal tokens to `~/.zshrc`**

6. **Configure 1Password SSH agent** for Git commit signing

7. **Restart your terminal** or run `source ~/.zshrc`

## Included Tools

### Homebrew Packages

**Formulae**: `agent-browser`, `arduino-cli`, `certbot`, `cloudflared`, `codex`, `deno`, `ffmpeg`, `fnm`, `gemini-cli`, `gh`, `git-lfs`, `git-xet`, `go`, `just`, `neovim`, `platformio`, `ripgrep`, `sshs`, `stripe`, `uv`, `watchexec`, `yt-dlp`, `zoxide`

**Casks**: `1password-cli`, `arduino-ide`, `balenaetcher`, `claude-code`, `ghostty`, `gitkraken-cli`, `monitorcontrol`, `proxyman`, `raspberry-pi-imager`, `tor-browser`, `zed`

### Zsh Plugins

- git
- zsh-syntax-highlighting
- zsh-autosuggestions
- virtualenv

## Custom Aliases

- `up` — Update all system packages (macOS, Homebrew, pnpm)
- `yolo` — Amend last commit and force push
- `lfg` — Review current branch with Claude
- `peek` — Get code review from Claude

## File Structure

```
dotfiles/
├── .zshrc                          # Zsh configuration
├── .gitconfig                      # Git configuration
├── .gitignore                      # Global gitignore
├── .claude/
│   ├── settings.json               # Claude settings
│   ├── mcp.json                    # Claude MCP servers
│   ├── agents/                     # Claude agent definitions (6 files)
│   ├── commands/aw.md              # Claude command
│   └── hooks/pre-tool-use.js       # Claude hook
├── .codex/
│   └── config.toml                 # Codex configuration
├── .config/
│   ├── spaceship.zsh               # Spaceship prompt config
│   ├── git/ignore                  # Global git ignore (XDG)
│   └── zed/
│       ├── settings.json           # Zed editor settings
│       └── keymap.json             # Zed keybindings
├── .ssh/
│   └── config                      # SSH host configurations
├── AGENTS.md                       # Claude instructions (-> ~/AGENTS.md)
├── Brewfile                        # Homebrew packages
├── sync                            # Dotfile sync script
└── README.md                       # This file
```

## Updating

```bash
cd ~/dev/dotfiles
git pull
./sync
```

## License

Personal configuration files — use at your own discretion.
