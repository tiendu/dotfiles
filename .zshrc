# Set the location of the Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Add a dir to PATH
add2path() {
  local dir="$1"
  dir=$(realpath "$dir")
  # Check if directory exists
  if [ -d "$dir" ]; then
    # Check if directory is already in PATH
    if [[ ":$PATH:" != *":$dir:"* ]]; then
      export PATH="$dir:$PATH"
      # Save to file if not already in the list
      if [ ! -f "$HOME/.zsh_added_paths" ] || ! grep -Fxq "$dir" "$HOME/.zsh_added_paths"; then
        echo "$dir" >> "$HOME/.zsh_added_paths"
      fi
      echo "Directory '$dir' added to PATH."
    else
      echo "Directory '$dir' is already in PATH."
    fi
    chmod +x "$dir"/* 2>/dev/null
    for file in "$dir"/*; do
      if [ -f "$file" ] && [ ! -x "$file" ]; then
        echo "Failed to make $file executable."
      fi
    done
  else
    echo "Directory '$dir' does not exist."
  fi
}

# Load previously added directories into PATH at startup
if [ -f "$HOME/.zsh_added_paths" ]; then
  while IFS= read -r line; do
    if [ -d "$line" ] && [[ ":$PATH:" != *":$line:"* ]]; then
      export PATH="$line:$PATH"
    fi
  done < "$HOME/.zsh_added_paths"
fi

# Clean up PATH and .zsh_added_paths
_clean_up_paths() {
  # Remove duplicates from $PATH
  local unique_paths=()
  local -A seen_paths
  IFS=":" read -r -A path_array <<< "$PATH"

  for path in "${path_array[@]}"; do
    if [[ -n "$path" && -z "${seen_paths[$path]}" && -d "$path" ]]; then
      unique_paths+=("$path")
      seen_paths["$path"]=1
    fi
  done

  PATH=$(printf "%s:" "${unique_paths[@]}")
  PATH=${PATH%:}  # Remove trailing colon

  # Clean up .zsh_added_paths
  [ -f "$HOME/.zsh_added_paths" ] && sort -u "$HOME/.zsh_added_paths" -o "$HOME/.zsh_added_paths"
}
_clean_up_paths

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

# Setup Zoxide (fuzzy directory finder)
if command -v zoxide > /dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# Setup fzf (fuzzy finder) if installed
if command -v fzf > /dev/null 2>&1; then
  source <(fzf --zsh)
fi

# Bind fzf to history search
export FZF_CTRL_R_OPTS="
  --preview 'echo {2..} | bat --color=always -pl sh'
  --preview-window up:hidden:wrap
  --bind 'ctrl-/:change-preview-window(30%|60%|90%|)'
  --bind 'ctrl-v:execute(echo {2..} | view - > /dev/tty)'
  --bind 'ctrl-t:track+clear-query'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"

# Use Vim nav keys in fzf
export FZF_DEFAULT_OPTS="--bind 'ctrl-j:down,ctrl-k:up,alt-j:preview-down,alt-k:preview-up'"

# Vim to create new file
_nvim() {
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

# Custom tab completion
_first_tab() {
  if [[ $#BUFFER == 0 ]]; then
    BUFFER="cd "
    CURSOR=3
    zle list-choices
  else
    zle expand-or-complete
  fi
}
zle -N _first_tab
bindkey -M viins '^I' _first_tab

# Aliases for convenience
alias rm="rm -i"  # Prompt before removing files
alias cp="cp -i"  # Prompt before overwriting files
alias mv="mv -i"  # Prompt before overwriting files
alias l="ls"
alias g="git"
alias e="_nvim"
alias sd="cd ~ && cd (find * -type d | fzf)"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# Alias for cross-platform pbcopy/pbpaste
if [[ "$OSTYPE" == "darwin"* ]]; then
  alias pbcopy="pbcopy"
  alias pbpaste="pbpaste"
elif command -v xclip > /dev/null 2>&1; then
  alias pbcopy="xclip -selection clipboard"
  alias pbpaste="xclip -selection clipboard -o"
elif command -v xsel > /dev/null 2>&1; then
  alias pbcopy="xsel --clipboard --input"
  alias pbpaste="xsel --clipboard --output"
else
  echo "No clipboard utility found. Install xclip or xsel for pbcopy/pbpaste functionality."
fi

# Replace grep with ripgrep if available
if command -v rg > /dev/null 2>&1; then
  alias grep="rg"
fi

# Replace ls with exa/eza if available
if command -v exa > /dev/null 2>&1; then
  alias ls="exa --icons"
  alias ll="exa -l --icons"
  alias la="exa -la --icons"
  alias tree="exa --tree --level=2"
elif command -v eza > /dev/null 2>&1; then
  alias ls="eza --icons"
  alias ll="eza -l --icons"
  alias la="eza -la --icons"
  alias tree="eza --tree --level=2"
else
  alias ls="ls --color=auto"
  alias tree="ls -R"
fi

# History settings
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt APPEND_HISTORY            # Append history to the history file
setopt SHARE_HISTORY             # Share history between sessions
setopt HIST_IGNORE_ALL_DUPS      # Ignore duplicate commands
setopt HIST_IGNORE_SPACE         # Ignore commands that start with a space
setopt HIST_VERIFY               # Verify history expansions before executing
setopt EXTENDED_HISTORY          # Save timestamp in history file

# Completion and correction settings
autoload -Uz compinit && compinit
setopt CORRECT                   # Correct spelling errors
setopt MENUCOMPLETE              # Use menu completion
setopt AUTO_MENU                 # Automatically show the completion menu
setopt LIST_PACKED               # Pack the completion list

# Call compdef after compinit
compdef _files _nvim

# Improve directory navigation
setopt AUTOCD
setopt AUTO_PUSHD                # Automatically push directories onto the stack
setopt PUSHD_IGNORE_DUPS         # Don't add duplicate directories to the stack
setopt PUSHD_MINUS               # Push onto the stack with `-` syntax

# Enable Zsh options for better shell behavior
setopt INTERACTIVE_COMMENTS      # Allow comments in interactive shell
setopt LONG_LIST_JOBS            # Use long format for job lists
setopt NO_BEEP                   # Disable the bell/beep sound
setopt GLOBDOTS                  # Include dotfiles in globbing

# Vim mode
## Enable Vim mode
bindkey -v

## Configure key bindings for Vim mode
bindkey '^P' up-line-or-history                   # Ctrl+P to move up in history
bindkey '^N' down-line-or-history                 # Ctrl+N to move down in history

## Map jj, jk, kj to Esc in insert mode
bindkey -M viins 'jj' vi-cmd-mode
bindkey -M viins 'jk' vi-cmd-mode
bindkey -M viins 'kj' vi-cmd-mode
bindkey -M viins 'kk' vi-cmd-mode

## Add Vim status to the right prompt (RPROMPT)
function zle-keymap-select {
  VIM_PROMPT="${WHITE}[${RESET}${BOLD_YELLOW}NORMAL${RESET_BOLD}${WHITE}]${RESET}"
  INSERT_PROMPT="${WHITE}[${RESET}${BOLD_CYAN}INSERT${WHITE}]${RESET}"
  if [[ $KEYMAP == vicmd ]]; then
    VIM_MODE=$VIM_PROMPT
  else
    VIM_MODE=$INSERT_PROMPT
  fi
  PROMPT_TIME="${WHITE}[${RESET}${BOLD_MAGENTA}%D{%H:%M:%S}${RESET}${WHITE}]${RESET}"
  RPROMPT="${VIM_MODE} ${PROMPT_TIME}"
}
zle -N zle-keymap-select
zle-line-init() { zle zle-keymap-select }
zle -N zle-line-init

# Get Git branch and status
_git_info() {
  local git_branch git_status rebase_commit_msg
  # Check if we are in the middle of a rebase
  if [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ]; then
    # If rebasing, get the commit message of the next commit
    rebase_commit_msg=$(cat .git/rebase-merge/message 2>/dev/null || cat .git/rebase-apply/message 2>/dev/null)
    git_branch="${rebase_commit_msg}"
  else
    # Get the current branch name
    git_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  fi
  if [[ -n "$git_branch" ]]; then
    # Check if there are any changes in the working directory
    if [[ -n $(git status --porcelain) ]]; then
      git_status="${BOLD_RED}✘${RESET_BOLD}"  # Changes exist
    else
      git_status="${BOLD_GREEN}✔${RESET_BOLD}"  # No changes
    fi
    echo "${BOLD_TEAL}$git_branch${RESET_BOLD} $git_status"
  fi
}

# Update prompt
_update_prompt() {
  PROMPT="${BOLD_BLUE}┌─${RESET_BOLD}${WHITE}[${RESET}${BOLD_PINK}%~${RESET_BOLD}${WHITE}]${RESET}"
  PROMPT+=" ${BROWN}-${RESET} ${WHITE}[${RESET}${BOLD_ORANGE}%!${RESET_BOLD}${WHITE}]${RESET}"
  PROMPT+=" ${BROWN}-${RESET}"
  PROMPT+=" ${WHITE}[${RESET}$(_git_info)${WHITE}]${RESET}"
  PROMPT+="
${BOLD_BLUE}└─${RESET_BOLD}${WHITE}[${RESET}${BOLD_GRAY}\$${RESET}${WHITE}]${RESET} "
  PS2=" ${BOLD_BLUE}>${RESET_BOLD} "
}
_update_prompt

# Hooks to update the prompt
precmd() {
  _update_prompt
  _clean_up_paths  # Call it once at shell startup
}

# Ensure that the prompt is updated when the keymap changes (e.g., Vim mode)
autoload -Uz add-zsh-hook
add-zsh-hook precmd _clean_up_paths
add-zsh-hook precmd _update_prompt
