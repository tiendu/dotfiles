# Add a dir to PATH
a2p() {
  local dir
  dir=$(realpath "$1" 2>/dev/null)
  # Exit if realpath fails (directory doesn't exist)
  if [ -z "$dir" ]; then
    echo "Directory '$1' does not exist."
    return
  fi
  # Add directory to PATH if not already included
  if [[ ":$PATH:" != *":$dir:"* ]]; then
    export PATH="$dir:$PATH"
    echo "$dir" >> "$HOME/.zsh_added_paths" 2>/dev/null
    echo "Directory '$dir' added to PATH."
  else
    echo "Directory '$dir' is already in PATH."
  fi
  # Make all files executable if not already
  find "$dir" -type f ! -perm -u+x -exec chmod +x {} \;
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
BOLD_RED="%B%F{#ff0000}"
BOLD_GREEN="%B%F{#00ff00}"
BOLD_YELLOW="%B%F{#ffff00}"
BOLD_MINT="%B%F{#00ffaa}"
BOLD_GRAY="%B%F{#808080}"
BOLD_CYAN="%B%F{#00ffff}"
MINT="%F{#00ffaa}"
WHITE="%F{#ffffff}"
BROWN="%F{#a52a2a}"

# Modify less
export LESS="e M q R F X z -3"

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

# Aliases for convenience
alias rm="rm -i"  # Prompt before removing files
alias cp="cp -i"  # Prompt before overwriting files
alias mv="mv -i"  # Prompt before overwriting files
alias l="ls"
alias g="git"
alias e="_nvim"
if command -v fd > /dev/null 2>&1 && command -v fzf > /dev/null 2>&1; then
  alias sd='dir=$(fd -t d . | fzf) && [ -n "$dir" ] && cd "$dir"'
else
  alias sd='
    dirs=()
    while IFS= read -r dir; do
      dirs+=("$dir")
    done < <(find . -type d ! -path "*/.*")
    if [ ${#dirs[@]} -eq 0 ]; then
      echo "No directories found."
      return
    fi
    echo "Select a directory:"
    select dir in "${dirs[@]}"; do
      if [ -n "$dir" ]; then
        cd "$dir"
        break
      else
        echo "Invalid selection."
      fi
    done
  '
fi
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

# History settings
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt APPEND_HISTORY            # Append history to the history file
setopt SHARE_HISTORY             # Share history between sessions
setopt INC_APPEND_HISTORY        # Append commands as soon as they are entered
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming
setopt HIST_IGNORE_DUPS          # Don't record an entry if it's a duplicate
setopt HIST_IGNORE_ALL_DUPS      # Ignore duplicate commands
setopt HIST_IGNORE_SPACE         # Ignore commands that start with a space
setopt HIST_REDUCE_BLANKS        # Remove extra blanks
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

## For insert mode (viins), ensure backspace deletes the previous character
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char

## For command mode (vicmd), bind backspace to delete the previous character
bindkey -M vicmd '^?' backward-delete-char
bindkey -M vicmd '^H' backward-delete-char

## Add Vim status to the right prompt (RPROMPT)
function zle-keymap-select {
  local NOR_PROMPT="${WHITE}(${RESET}${BOLD_YELLOW}N${RESET_BOLD}${WHITE})${RESET}"
  local INS_PROMPT="${WHITE}(${RESET}${BOLD_CYAN}I${WHITE})${RESET}"
  if [[ $KEYMAP == vicmd ]]; then
    VIM_MODE=$NOR_PROMPT
  else
    VIM_MODE=$INS_PROMPT
  fi
  RPROMPT="${VIM_MODE}"
  zle reset-prompt
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
  if [[ -n "${git_branch}" ]]; then
    # Check if there are any changes in the working directory
    if [[ -n $(git status --porcelain) ]]; then
      git_status="${BOLD_RED}${git_branch}${RESET_BOLD}"  # Changes exist
    else
      git_status="${BOLD_GREEN}${git_branch}${RESET_BOLD}"  # No changes
    fi
    echo "${git_status}"
  fi
}

# Directory stats using explicit full-path ls
_dir_info() {
  local size count
  size=$(/bin/ls -lah 2>/dev/null | grep -m 1 total | sed 's/total //')
  count=$(/bin/ls -A1 2>/dev/null | wc -l | tr -d '[:space:]')
  echo "${BOLD_MINT}${count}${RESET_BOLD}${BOLD_GRAY} | ${RESET_BOLD}${BOLD_MINT}${size}${RESET_BOLD}"
}

# Prompt
_update_prompt() {
  local git_info dir_info
  git_info=$(_git_info)
  dir_info=$(_dir_info)

  PROMPT="${WHITE}(${RESET}${BOLD_PINK}%~${RESET}"
  if [[ -n "$git_info" ]]; then
    PROMPT+=" ${BROWN}::${RESET} ${git_info}"
  fi

  PROMPT+=" ${BROWN}::${RESET} ${dir_info}"
  PROMPT+="${WHITE})-(${RESET}${BOLD_GRAY}\$${RESET}${WHITE})${RESET} "
  PS2="${BOLD_BLUE}>${RESET} "
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

export PATH="$HOME/.pixi/bin:$PATH"
