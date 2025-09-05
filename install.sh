#!/bin/bash

# Dotfiles Installation Script
# This script sets up a new macOS machine with all necessary tools and configurations

set -e

echo "🚀 Starting dotfiles installation..."

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Homebrew if not installed
if ! command_exists brew; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "📦 Installing Homebrew packages..."
brew bundle --file=./Brewfile

# Install Oh My Zsh if not installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "🎨 Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Install Zsh plugins
echo "🔌 Installing Zsh plugins..."
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

# zsh-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# zsh-autosuggestions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

# Install Spaceship theme
if [ ! -d "$ZSH_CUSTOM/themes/spaceship-prompt" ]; then
    git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
    ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
fi

# Setup fnm (Fast Node Manager)
echo "🚀 Setting up fnm..."
if command_exists fnm; then
    fnm install 22
    fnm default 22
fi

# Install pnpm
if ! command_exists pnpm; then
    echo "📦 Installing pnpm..."
    curl -fsSL https://get.pnpm.io/install.sh | sh -
fi

# Install global npm packages
echo "📦 Installing global npm packages..."
npm install -g corepack

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p ~/.claude
mkdir -p ~/.claude/agents
mkdir -p ~/.claude/hooks
mkdir -p ~/.claude/commands
mkdir -p ~/.config/zed
mkdir -p ~/.local/bin

# Copy configuration files
echo "📋 Copying configuration files..."

# Backup existing files if they exist
[ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.backup
[ -f ~/.gitconfig ] && mv ~/.gitconfig ~/.gitconfig.backup
[ -f ~/.gitignore ] && mv ~/.gitignore ~/.gitignore.backup
[ -f ~/.claude.json ] && mv ~/.claude.json ~/.claude.json.backup
[ -f ~/.claude/settings.json ] && mv ~/.claude/settings.json ~/.claude/settings.json.backup
[ -f ~/.config/zed/settings.json ] && mv ~/.config/zed/settings.json ~/.config/zed/settings.json.backup
[ -f ~/.config/zed/keymap.json ] && mv ~/.config/zed/keymap.json ~/.config/zed/keymap.json.backup

# Copy new configuration files
cp .zshrc ~/.zshrc
cp .gitconfig ~/.gitconfig
cp .gitignore ~/.gitignore
cp .claude.json ~/.claude.json
cp .claude/settings.json ~/.claude/settings.json

# Copy CLAUDE.md if it exists
if [ -f CLAUDE.md ]; then
    cp CLAUDE.md ~/.claude/CLAUDE.md
fi

# Copy agents if they exist
if [ -d .claude/agents ]; then
    cp -r .claude/agents/* ~/.claude/agents/
fi

# Copy hooks if they exist
if [ -d .claude/hooks ]; then
    cp -r .claude/hooks/* ~/.claude/hooks/
fi

# Copy commands if they exist
if [ -d .claude/commands ]; then
    cp -r .claude/commands/* ~/.claude/commands/
fi

# Copy Zed configuration if it exists
if [ -d .config/zed ]; then
    cp .config/zed/settings.json ~/.config/zed/settings.json
    cp .config/zed/keymap.json ~/.config/zed/keymap.json
fi

echo ""
echo "⚠️  IMPORTANT: Add your personal tokens and API keys:"
echo ""
echo "📝 In ~/.zshrc:"
echo "   - GITHUB_TOKEN"
echo "   - NPM_TOKEN"
echo ""
echo "📝 In ~/.claude.json (mcpServers section):"
echo "   - CONTEXT7_API_KEY (context7 server)"
echo "   - OPENAI_API_KEY (zen server)"
echo "   - GEMINI_API_KEY (zen server)"
echo "   - XAI_API_KEY (zen server)"
echo "   - GitHub PAT token (github server Authorization header)"
echo ""
echo "📝 Also update your git config with your personal information if needed"
echo ""
echo "✅ Dotfiles installation complete!"
echo "🔄 Please restart your terminal or run 'source ~/.zshrc' to apply changes"
