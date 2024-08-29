# vi ~/.zshrc
# Set the location of the Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Path settings
export PATH="$HOME/mambaforge/bin:$HOME/.local/bin:$PATH"

# Load Oh My Zsh plugins and theme
plugins=(git z zsh-autosuggestions zsh-syntax-highlighting)
ZSH_THEME="junkfood"
source $ZSH/oh-my-zsh.sh

# Setup Zoxide (fuzzy directory finder)
if command -v zoxide > /dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# Setup fzf (fuzzy finder) if installed
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Auto-update Oh My Zsh every 2 weeks
if [ -x "$(command -v omz-update)" ]; then
  omz-update --auto
fi

# Open file in nvim, create it if it doesn't exist
nvim_open_or_create() {
  if [ ! -e "$1" ]; then
    touch "$1"  # Create the file if it doesn't exist
  fi
  nvim "$1"  # Open the file in nvim
}

# Aliases for convenience
alias ll="ls -l"
alias la="ls -A"
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline --graph --all"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias rm="rm -i"  # Prompt before removing files
alias cp="cp -i"  # Prompt before overwriting files
alias mv="mv -i"  # Prompt before overwriting files
alias e="nvim_open_or_create"

# Replace grep with ripgrep if available
if command -v rg > /dev/null 2>&1; then
  alias grep="rg"
fi

# Replace ls with eza if available
if command -v eza > /dev/null 2>&1; then
  alias ls="eza"
  alias tree="eza --tree --level=2"
else
  alias ls="ls"
  alias tree="ls -R"
fi

# History settings
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt sharehistory
setopt hist_ignore_all_dups  # Ignore duplicate commands
setopt hist_ignore_space  # Ignore commands that start with a space
setopt hist_verify  # Verify history expansions before executing
setopt extended_history  # Save timestamp in history file

# Completion and correction settings
setopt correct
setopt menucomplete  # Show a menu for completions
setopt auto_menu  # Automatically show the completion menu
setopt list_packed  # Pack the completion list

# Enable colored output in `less` and other pagers
export LESS='-R'
export LESSOPEN='|~/.lessfilter %s'

# Improve directory navigation with pushd/popd
setopt auto_pushd  # Automatically push directories onto the stack
setopt pushd_ignore_dups  # Don't add duplicate directories to the stack
setopt pushd_minus  # Push onto the stack with `-` syntax

# Enable Zsh options for better shell behavior
setopt interactive_comments  # Allow comments in interactive shell
setopt long_list_jobs  # Use long format for job lists
setopt no_beep  # Disable the bell/beep sound
setopt globdots  # Include dotfiles in globbing

# Enable vim mode
bindkey -v

# Configure key bindings for vim mode
bindkey '^R' history-incremental-search-backward  # Ctrl+R to search history
bindkey '^P' up-line-or-history                   # Ctrl+P to move up in history
bindkey '^N' down-line-or-history                 # Ctrl+N to move down in history

# Map jj, jk, kj to Esc in insert mode
bindkey -M viins 'jj' vi-cmd-mode
bindkey -M viins 'jk' vi-cmd-mode
bindkey -M viins 'kj' vi-cmd-mode
