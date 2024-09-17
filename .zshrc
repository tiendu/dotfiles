# Set the location of the Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Path settings
export PATH="$HOME/mambaforge/bin:$HOME/.local/bin:$PATH"

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
    VIM_PROMPT="%{$fg_bold[yellow]%} [NORMAL]%{$reset_color%}"  # Normal mode
    INSERT_PROMPT="%{$fg_bold[cyan]%} [INSERT]%{$reset_color%}"  # Insert mode

    if [[ $KEYMAP == vicmd ]]; then
        VIM_MODE=$VIM_PROMPT  # Display NORMAL mode in rprompt
    else
        VIM_MODE=$INSERT_PROMPT  # Display INSERT mode in rprompt
    fi

    # Add the current time in the right prompt
    PROMPT_TIME="[%D{%H:%M:%S}]"
    
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

# Git prompt info
git_prompt_info() {
  # Get the current Git branch
  local git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

  # If not inside a git repository, return an empty string
  if [[ -z "$git_branch" ]]; then
    return
  fi

  # ANSI escape codes for bold red and bold green
  local bold_red="%{\e[1;31m%}"  # Bold red
  local bold_green="%{\e[1;32m%}"  # Bold green
  local reset_color="%{\e[0m%}"  # Reset color to default

  # Check for changes in the working directory
  if [[ -n $(git status --porcelain) ]]; then
    local git_status="${bold_red}✘${reset_color}"  # Changes exist
  else
    local git_status="${bold_green}✔${reset_color}"  # No changes
  fi

  # Return the branch name with status symbol
  echo "$git_branch $git_status"
}

# Zsh prompt
PROMPT=$'%{\e[0;34m%}%B┌─%b%{\e[0;34m%}%B[%b%{\e[1;37m%}%~%{\e[0;34m%}%B]%b%{\e[0m%} - %{\e[0;34m%}%B[%b%{\e[0;33m%}%!%{\e[0;34m%}%B]%b%{\e[0m%} - %{\e[0;34m%}%B[%b%{\e[1;36m%}$(git_prompt_info)%{\e[0;34m%}%B]%b%{\e[0m%}
%{\e[0;34m%}%B└─%B[%{\e[1;35m%}$%{\e[0;34m%}%B]%{\e[0m%}%b '
PS2=$' \e[0;34m%}%B>%{\e[0m%}%b '
