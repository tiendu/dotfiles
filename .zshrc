# Set the location of the Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Load Oh My Zsh plugins and theme
plugins=(git z zsh-autosuggestions zsh-syntax-highlighting)
ZSH_THEME="junkfood"
source $ZSH/oh-my-zsh.sh

# Aliases for convenience
alias ls="exa"
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

# History settings
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt sharehistory

# Completion and correction settings
zstyle ":completion:*" matcher-list "m:{a-zA-Z}={A-Za-z}"
setopt correct

# Enable Vi mode
bindkey -v

# Custom key bindings
bindkey '^A' beginning-of-line  # Ctrl + A to move to the beginning of the line
bindkey '^E' end-of-line        # Ctrl + E to move to the end of the line
bindkey '^K' kill-line          # Ctrl + K to kill the line
bindkey '^U' unix-line-discard  # Ctrl + U to cut from the beginning of the line

# Create a function to handle jj, jk, and kj mapping to Esc
function zle-jj-to-escape {
  LBUFFER=${LBUFFER%?} # Remove the last character from the buffer
  zle vi-cmd-mode      # Switch to command mode
}
zle -N zle-jj-to-escape
bindkey -M viins 'jj' zle-jj-to-escape
bindkey -M viins 'jk' zle-jj-to-escape
bindkey -M viins 'kj' zle-jj-to-escape

# Auto-update Oh My Zsh every 2 weeks
if [ -x "$(command -v omz-update)" ]; then
  omz-update --auto
fi

# Display a directory tree using exa
alias tree="exa --tree --level=2"
# Open Neovim in the current directory
alias v="nvim ."

# Set up fzf (fuzzy finder) if installed
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Enable better auto-completion with zsh-completions
if [ -d "$HOME/.zsh/completions" ]; then
  fpath+=("$HOME/.zsh/completions")
fi

# Path settings
export PATH="$HOME/mambaforge/bin:$HOME/.local/bin:$PATH"
