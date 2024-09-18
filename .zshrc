
# Set the location of the Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Path settings
export PATH="$HOME/mambaforge/bin:$HOME/.local/bin:$PATH"

# Add a dir to PATH
add2path() {
  local dir="$1"
  # Convert to absolute path
  dir=$(realpath "$dir")
  # Check if directory exists
  if [ -d "$dir" ]; then
    # Check if directory is already in PATH
    if [[ ":$PATH:" != *":$dir:"* ]]; then
      # Add directory to PATH
      export PATH="$dir:$PATH"
      echo "Directory '$dir' added to PATH."
    else
      echo "Directory '$dir' is already in PATH."
    fi
    # Change permissions to make all files in the directory executable
    chmod +x "$dir"/* 2>/dev/null
    # Verify if permissions were changed
    for file in "$dir"/*; do
      if [ -f "$file" ] && [ ! -x "$file" ]; then
        echo "Failed to make $file executable."
      fi
    done
    echo "All files in '$dir' are now executable (if applicable)."
  else
    echo "Directory '$dir' does not exist."
  fi
}

# Global color variables with hex color codes
RESET="%f"
RESET_BOLD="%f%b"
BOLD_PINK="%B%F{#ff69b4}"
BOLD_ORANGE="%B%F{#ff8000}"
BOLD_RED="%B%F{#ff0000}"
BOLD_TEAL="%B%F{#008080}"
BOLD_GREEN="%B%F{#00ff00}"
BOLD_YELLOW="%B%F{#ffff00}"
BOLD_BLUE="%B%F{#0000ff}"
BOLD_MAGENTA="%B%F{#ff00ff}"
BOLD_GRAY="%B%F{#808080}"
BOLD_CYAN="%B%F{#00ffff}"
BOLD_WHITE="%B%F{#ffffff}"
WHITE="%F{#ffffff}"
BLUE="%F{#0000ff}"
BROWN="%F{#a52a2a}"

# Load Oh My Zsh plugins
plugins=(git z zsh-autosuggestions zsh-syntax-highlighting)
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
_nvim_open_or_create() {
  local file="$1"
  if [ ! -e "$file" ]; then
    touch "$file"  # Create the file if it doesn't exist
  fi
  # Open the file in nvim
  nvim "$file"
  # Check if the file is empty after quitting nvim
  if [ ! -s "$file" ]; then
    rm "$file"  # Remove the file if it is empty
    echo "File '$file' was empty and has been deleted."
  fi
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
alias e="_nvim_open_or_create"

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

# vim mode
## Enable vim mode
bindkey -v

## Configure key bindings for vim mode
bindkey '^R' history-incremental-search-backward  # Ctrl+R to search history
bindkey '^P' up-line-or-history                   # Ctrl+P to move up in history
bindkey '^N' down-line-or-history                 # Ctrl+N to move down in history

## Map jj, jk, kj to Esc in insert mode
bindkey -M viins 'jj' vi-cmd-mode
bindkey -M viins 'jk' vi-cmd-mode
bindkey -M viins 'kj' vi-cmd-mode

## Add vim status to the rprompt
function zle-line-init zle-keymap-select {
  VIM_PROMPT="${WHITE}[${RESET}${BOLD_YELLOW}NORMAL${RESET_BOLD}${WHITE}]${RESET}"  # Normal mode
  INSERT_PROMPT="${WHITE}[${RESET}${BOLD_CYAN}INSERT${WHITE}]${RESET}"  # Insert mode
  if [[ $KEYMAP == vicmd ]]; then
      VIM_MODE=$VIM_PROMPT  # Display NORMAL mode in rprompt
  else
      VIM_MODE=$INSERT_PROMPT  # Display INSERT mode in rprompt
  fi
  PROMPT_TIME="${WHITE}[${RESET}${BOLD_MAGENTA}%D{%H:%M:%S}${RESET}${WHITE}]${RESET}"
  RPS1="${VIM_MODE} ${PROMPT_TIME}"  # Set rprompt with vim mode and time
  zle reset-prompt  # Redraw the prompt
}

zle -N zle-line-init
zle -N zle-keymap-select

# Git utilities
## Create a new branch and push it to origin
gnew() {
  if [[ -z "$1" ]]; then
    echo "Error: Please provide a branch name."
    return 1
  fi
  git checkout -b "$1" && git push -u origin "$1"
}

## Quickly stage, commit, and push changes with a message
gquick() {
  if [[ -z "$1" ]]; then
    echo "Error: Please provide a commit message."
    return 1
  fi
  git add . && git commit -m "$1" && git push
}

## Rebase current branch onto the latest version of main
grebase() {
  echo "Rebasing onto main... Continue? (y/n)"
  read answer
  if [[ "$answer" == "y" ]]; then
    git checkout main && git pull origin main && git checkout - && git rebase main
  else
    echo "Rebase aborted."
  fi
}

## Undo last commit but keep changes
gundo() {
  echo "Undo the last commit? (y/n)"
  read answer
  if [[ "$answer" == "y" ]]; then
    git reset --soft HEAD~1
  else
    echo "Undo aborted."
  fi
}

## Squash the last n commits into one
gsquash() {
  if [[ -z "$1" ]]; then
    echo "Error: Please provide the number of commits to squash."
    return 1
  fi
  git reset --soft HEAD~"$1" && git commit --amend
}

## Interactive rebase for the last n commits
grebasei() {
  if [[ -z "$1" ]]; then
    echo "Error: Please provide the number of commits to rebase."
    return 1
  fi
  git rebase -i HEAD~"$1"
}

## Show Git log with a tree graph
glogtree() {
  git log --graph --abbrev-commit --decorate --format=format:"%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %s %C(bold red)%d%C(reset)" --all
}

## Reset current branch to match the remote
gresetremote() {
  # Check for uncommitted changes
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Warning: You have uncommitted changes."
    echo "Resetting will discard these changes. Do you want to continue? (y/n)"
    read answer
    if [[ "$answer" != "y" ]]; then
      echo "Reset aborted."
      return 1
    fi
  fi
  # Fetch the latest from origin
  git fetch origin
  # Get current branch name
  branch="$(git rev-parse --abbrev-ref HEAD)"
  # Confirm resetting to the remote
  echo "Are you sure you want to hard reset '$branch' to match 'origin/$branch'? (y/n)"
  read answer
  if [[ "$answer" == "y" ]]; then
    git reset --hard origin/"$branch"
    echo "Branch '$branch' reset to 'origin/$branch'."
  else
    echo "Reset aborted."
  fi
}

# Get Git branch and status
_git_info() {
  local git_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  if [[ -z "$git_branch" ]]; then
    echo ""
  else
    local git_status=$(git status --porcelain)
    if [[ -n "$git_status" ]]; then
      git_status="${BOLD_RED}✘${RESET_BOLD}"  # Changes exist
    else
      git_status="${BOLD_GREEN}✔${RESET_BOLD}"  # No changes
    fi
    echo "${BOLD_TEAL}$git_branch${RESET_BOLD} $git_status"
  fi
}

# Update prompt
_update_prompt() {
  PROMPT="${BOLD_BLUE}┌─${RESET_BOLD}${WHITE}[${RESET}${BOLD_PINK}%~${RESET_BOLD}${WHITE}]${RESET} ${BROWN}-${RESET} ${WHITE}[${RESET}${BOLD_ORANGE}%!${RESET_BOLD}${WHITE}]${RESET} ${BROWN}-${RESET}"
  PROMPT+=" ${WHITE}[${RESET}$(_git_info)${WHITE}]${RESET}"
  PROMPT+="
${BOLD_BLUE}└─${RESET_BOLD}${WHITE}[${RESET}${BOLD_GRAY}\$${RESET}${WHITE}]${RESET} "
  PS2=" ${BOLD_BLUE}>${RESET_BOLD} "
}

# Hooks to update the prompt
precmd() {
  _update_prompt
}

# Initial prompt setup
_update_prompt
