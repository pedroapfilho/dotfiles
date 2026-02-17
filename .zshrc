# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="spaceship"

# Which plugins would you like to load?
plugins=(git zsh-syntax-highlighting zsh-autosuggestions virtualenv)

source $ZSH/oh-my-zsh.sh

# User configuration

# Aliases
alias up="softwareupdate -l && brew update && brew upgrade && brew cleanup && pnpm -g upgrade"
alias yolo="git add . && git commit --amend --no-edit && git push --force-with-lease"
alias python="python3"
alias pip="pip3"
unalias gk 2>/dev/null
alias lfg="claude -p 'Review my current branch and the most recent commit. Provide a detailed summary of all changes, including what was modified, added or removed. Analyze the overall impact and quality of the changes.'"
alias peek="claude -p 'Review my changes and give me your opinion, as a senior software engineer, on the quality and impact of the changes. Also, suggest any improvements or optimizations that could be made to the code.'"

eval "$(zoxide init zsh)"
if [ -z "$DISABLE_ZOXIDE" ]; then
    eval "$(zoxide init --cmd cd zsh)"
fi

# paths
PATH="/usr/local/bin:$PATH:./node_modules/.bin";
PATH="/usr/local/sbin:$PATH"

# envs - ADD YOUR OWN TOKENS HERE
# export GITHUB_TOKEN=your_github_token_here
# export NPM_TOKEN=your_npm_token_here

# fnm
eval "$(fnm env --use-on-cd --shell zsh)"

# pnpm
export PNPM_HOME="/Users/pedroapfilho/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# fnm
FNM_PATH="/Users/pedroapfilho/Library/Application Support/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="/Users/pedroapfilho/Library/Application Support/fnm:$PATH"
  eval "`fnm env`"
fi

. "$HOME/.local/bin/env"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/pedroapfilho/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/pedroapfilho/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/pedroapfilho/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/pedroapfilho/Downloads/google-cloud-sdk/completion.zsh.inc'; fi
export PATH="$PATH":~/.local/bin

autoload -Uz compinit
compinit
. <(cs gen-autocomplete zsh)

# bun completions
[ -s "/Users/pedroapfilho/.bun/_bun" ] && source "/Users/pedroapfilho/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
