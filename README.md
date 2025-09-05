# Pedro's Dotfiles

Personal dotfiles configuration for macOS development environment.

## What's Included

- **Shell**: Zsh with Oh My Zsh, custom aliases, and productivity plugins
- **Node.js**: fnm (Fast Node Manager) with multiple Node versions
- **Package Managers**: Homebrew, pnpm
- **Git**: Configuration with GPG signing via 1Password
- **Claude Code**: Settings and configuration
- **Development Tools**: Various CLI tools and utilities

## Prerequisites

- macOS
- Command Line Tools (`xcode-select --install`)

## Installation

```bash
# Clone this repository
git clone https://github.com/yourusername/dotfiles.git ~/dev/dotfiles
cd ~/dev/dotfiles

# Make the install script executable
chmod +x install.sh

# Run the installation
./install.sh
```

## Manual Steps After Installation

1. **Add your personal tokens to `~/.zshrc`:**
   ```bash
   export GITHUB_TOKEN=your_github_token_here
   export NPM_TOKEN=your_npm_token_here
   ```

2. **Configure 1Password SSH agent** for Git commit signing

3. **Restart your terminal** or run:
   ```bash
   source ~/.zshrc
   ```

## Included Tools

### Homebrew Packages
- Development: `go`, `neovim`, `ripgrep`, `fnm`, `gh`
- Media: `ffmpeg` with codecs
- Utilities: `zoxide`, `tree-sitter`, `cloudflared`
- Security: `1password-cli`

### Node.js Versions (via fnm)
- v22.15.0 (default)
- v20.10.0
- v20.19.1
- v24.5.0

### Zsh Plugins
- git
- zsh-syntax-highlighting
- zsh-autosuggestions
- virtualenv

## Custom Aliases

- `gtr` - Go to git repository root
- `up` - Update all system packages (macOS, Homebrew, pnpm)
- `yolo` - Amend last commit and force push
- `lfg` - Review current branch with Claude
- `peek` - Get code review from Claude

## File Structure

```
dotfiles/
├── .zshrc              # Zsh configuration
├── .gitconfig          # Git configuration
├── .gitignore          # Global gitignore
├── .claude.json        # Claude Code configuration
├── .claude/
│   ├── settings.json   # Claude settings
│   └── CLAUDE.md       # Claude instructions
├── Brewfile            # Homebrew packages
├── install.sh          # Installation script
└── README.md           # This file
```

## Updating

To update your dotfiles:

```bash
cd ~/dev/dotfiles
git pull
./install.sh
```

To update all packages:

```bash
up  # Custom alias that updates everything
```

## License

Personal configuration files - use at your own discretion.