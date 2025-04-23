# Add a dir to PATH
a2p() {
  local dir
  dir=$(realpath "$1" 2>/dev/null)
  if [[ -z "$dir" || ! -d "$dir" ]]; then
    echo "Directory '$1' does not exist or is invalid."
    return 1
  fi

  # Add to .zsh_added_paths if not already recorded
  if ! grep -qxF "$dir" "$HOME/.zsh_added_paths" 2>/dev/null; then
    echo "$dir" >> "$HOME/.zsh_added_paths"
  fi

  # Add to PATH if not already present
  if [[ ":$PATH:" != *":$dir:"* ]]; then
    export PATH="$dir:$PATH"
    echo "Directory '$dir' added to PATH."
  else
    echo "Directory '$dir' is already in PATH."
  fi

  # Make all files in the dir executable if not already
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

# Global color variables with hex color codes
RESET="%f"
RESET_BOLD="%f%b"
BOLD_RED="%B%F{red}"
BOLD_GREEN="%B%F{green}"
BOLD_YELLOW="%B%F{yellow}"
BOLD_CYAN="%B%F{cyan}"
BOLD_WHITE="%B%F{white}"
BOLD_MAGENTA="%B%F{magenta}"
BOLD_BLUE="%B%F{blue}"
RED="%F{red}"
GREEN="%F{green}"
YELLOW="%F{yellow}"
CYAN="%F{cyan}"
WHITE="%F{white}"
MAGENTA="%F{magenta}"
BLUE="%F{blue}"

# Modify less
export LESS="e M q R F X z -3"

# Setup Zoxide (fuzzy directory finder)
if command -v zoxide > /dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# Setup fzf (fuzzy finder) if installed
if command -v fzf > /dev/null 2>&1; then
  _fzf_init() {
    source <(fzf --zsh)
  }
  autoload -Uz _fzf_init
  zle -N _fzf_init
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
setopt CORRECT                   # Correct spelling errors
setopt MENUCOMPLETE              # Use menu completion
setopt AUTO_MENU                 # Automatically show the completion menu
setopt LIST_PACKED               # Pack the completion list

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
  local INS_PROMPT="${WHITE}(${RESET}${BOLD_CYAN}I${RESET_BOLD}${WHITE})${RESET}"
  if [[ $KEYMAP == vicmd ]]; then
    VIM_MODE=$NOR_PROMPT
  else
    VIM_MODE=$INS_PROMPT
  fi
  RPROMPT=$VIM_MODE
  zle reset-prompt
}
zle -N zle-keymap-select
zle-line-init() { zle zle-keymap-select }
zle -N zle-line-init

# Get Git branch and status
typeset -g _GIT_INFO_CACHE=""
typeset -g _GIT_INFO_LAST_DIR=""

_git_info() {
  local current_dir=$(git rev-parse --show-toplevel 2>/dev/null)
  [[ -z "$current_dir" ]] && return

  # Use cached value if still in the same repo root
  if [[ "$_GIT_INFO_LAST_DIR" == "$current_dir" && -n "$_GIT_INFO_CACHE" ]]; then
    echo "$_GIT_INFO_CACHE"
    return
  fi

  # (Original logic below — truncated for brevity)
  local git_branch rebase_commit_msg added_count=0 modified_count=0
  local git_dir line status_char

  git_dir=$(git rev-parse --git-dir 2>/dev/null)
  if [[ -d "$git_dir/rebase-merge" || -d "$git_dir/rebase-apply" ]]; then
    rebase_commit_msg=$(<"$git_dir/rebase-merge/message" 2>/dev/null || <"$git_dir/rebase-apply/message" 2>/dev/null)
    git_branch="rebase: ${rebase_commit_msg}"
  else
    git_branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  fi

  while IFS= read -r line; do
    status_char="${line:0:2}"
    case "$status_char" in
      \?\?) ((added_count++)) ;;
      [MARCDU]?) ((modified_count++)) ;;
      ?[MARCDU]) ((modified_count++)) ;;
    esac
  done < <(git status --porcelain)

  local status_suffix=""
  ((added_count > 0)) && status_suffix+=" +${added_count}"
  ((modified_count > 0)) && status_suffix+=" !${modified_count}"

  if [[ -n "$git_branch" ]]; then
    if [[ -n "$status_suffix" ]]; then
      _GIT_INFO_CACHE="${BOLD_RED}${git_branch}${status_suffix} ✘${RESET_BOLD}"
    else
      _GIT_INFO_CACHE="${BOLD_GREEN}${git_branch} ✔${RESET_BOLD}"
    fi
    _GIT_INFO_LAST_DIR="$current_dir"
    echo "$_GIT_INFO_CACHE"
  fi
}

# Directory stats using explicit full-path ls
## Human-readable byte converter (cross-platform awk)
_humanize_size() {
  awk '{
    split("B KB MB GB TB", unit)
    s = $1
    for (i = 1; s >= 1024 && i < 5; i++) s /= 1024
    printf "%.1f%s\n", s, unit[i]
  }'
}

## OS-aware fast directory size using
_get_dir_size() {
  local blocks block_size bytes
  blocks=$(/bin/ls -lA . 2>/dev/null | awk '/^total/ { print $2 }')

  case "$(uname)" in
    Darwin) block_size=512 ;;   # macOS
    Linux)  block_size=1024 ;;  # Linux
    *)      block_size=512 ;;   # Fallback
  esac

  bytes=$((blocks * block_size))
  echo "$bytes" | _humanize_size
}

_dir_info() {
  local size count
  size=$(_get_dir_size)
  count=$(/bin/ls -A1 2>/dev/null | wc -l | tr -d '[:space:]')
  echo "${BOLD_CYAN}${count}${RESET_BOLD}${BOLD_WHITE} | ${RESET_BOLD}${BOLD_CYAN}${size}${RESET_BOLD}"
}

# Prompt
_update_prompt() {
  local git_info dir_info
  git_info=$(_git_info)
  dir_info=$(_dir_info)

  PROMPT="${WHITE}(${RESET}${BOLD_MAGENTA}%~${RESET_BOLD}"
  if [[ -n "$git_info" ]]; then
    PROMPT+=" ${BLUE}::${RESET} ${git_info}"
  fi

  PROMPT+=" ${BLUE}::${RESET} ${dir_info}${WHITE})${RESET}"
  PROMPT+="
${WHITE}(${RESET}${BOLD_WHITE}\$${RESET_BOLD}${WHITE})${RESET} "
  PS2="${BOLD_BLUE}>${RESET_BOLD} "
}

# Hooks to update the prompt
precmd() {
  _update_prompt
  _clean_up_paths  # Call it once at shell startup
}

if [[ $- == *i* ]]; then
  _update_prompt
  _clean_up_paths
  autoload -Uz compinit
  zmodload zsh/complist
  compinit -C -d "$HOME/.zcompdump-$ZSH_VERSION"
  compdef _files _nvim
fi

# Ensure that the prompt is updated when the keymap changes (e.g., Vim mode)
autoload -Uz add-zsh-hook
add-zsh-hook precmd _clean_up_paths
add-zsh-hook precmd _update_prompt

export PATH="$HOME/.pixi/bin:$PATH"
