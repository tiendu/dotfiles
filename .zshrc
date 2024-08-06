# Set the location of the Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Load Oh My Zsh plugins and theme
plugins=(git z zsh-autosuggestions zsh-syntax-highlighting autojump)
ZSH_THEME="junkfood"
source $ZSH/oh-my-zsh.sh

# Aliases for convenience
alias ls="eza"
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
alias tree="exa --tree --level=2"
alias rm="rm -i"  # Prompt before removing files
alias cp="cp -i"  # Prompt before overwriting files
alias mv="mv -i"  # Prompt before overwriting files

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

# Setup fzf (fuzzy finder) if installed
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Load autojump if installed
[ -s /usr/share/autojump/autojump.zsh ] && source /usr/share/autojump/autojump.zsh

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

# Path settings
export PATH="$HOME/mambaforge/bin:$HOME/.local/bin:$PATH"
