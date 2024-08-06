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
alias tree="eza --tree --level=2"
alias rm="rm -i"  # Prompt before removing files
alias cp="cp -i"  # Prompt before overwriting files
alias mv="mv -i"  # Prompt before overwriting files
alias c="clear"
alias h="history"
alias j="autojump"
alias ..1="cd .."
alias ..2="cd ../.."
alias ..3="cd ../../.."

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
setopt auto_cd  # Auto cd when typing directory name

# Add useful functions
mkcd () { mkdir -p "$1" && cd "$1"; }  # Make directory and change to it

# Path settings
export PATH="$HOME/mambaforge/bin:$HOME/.local/bin:$PATH"

# Check if commands exist before sourcing
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -s /usr/share/autojump/autojump.zsh ] && source /usr/share/autojump/autojump.zsh

# Auto-update Oh My Zsh every 2 weeks
if [ -x "$(command -v omz-update)" ]; then
  omz-update --auto
fi
