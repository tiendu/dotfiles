# Global color variables with hex color codes
autoload -U colors && colors
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

# Replace grep with ripgrep if available
if command -v rg > /dev/null 2>&1; then
  alias grep="rg"
fi

# Replace ls with eza if available
if command -v eza > /dev/null 2>&1; then
  alias ls="eza"
  alias ll="eza -l"
  alias la="eza -la"
  alias tree="eza --tree --level=3"
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
alias e="nvim"
alias h="fc -l 1 | awk '{\$1=\"\"; print substr(\$0,2)}'"
alias ta="tmux attach || tmux new"

# Dotfiles git alias for easier dotfiles management
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

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
  # Fallback to no-op to avoid script errors in headless environments
  alias pbcopy='cat > /dev/null'
  alias pbpaste='echo ""'
fi

# Custom tab completion
_first_tab() {
  if [[ -z $BUFFER ]]; then
    BUFFER="cd "
    CURSOR=${#BUFFER}
    zle list-choices
  else
    zle expand-or-complete
  fi
}
zle -N _first_tab
bindkey -M viins '^I' _first_tab

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

# Safer defaults
setopt PROMPT_SUBST
unsetopt BEEP

# Vim mode
## Enable Vim mode
bindkey -v

## Configure key bindings for Vim mode
bindkey '^P' up-line-or-history                   # Ctrl+P to move up in history
bindkey '^N' down-line-or-history                 # Ctrl+N to move down in history

## Map jk, kj to Esc in insert mode
bindkey -M viins 'jk' vi-cmd-mode
bindkey -M viins 'kj' vi-cmd-mode

## Add Vim status to the right prompt (RPROMPT)
function zle-keymap-select {
  local NOR_PROMPT="${WHITE}[${RESET}${BOLD_YELLOW}N${RESET_BOLD}${WHITE}]${RESET}"
  local INS_PROMPT="${WHITE}[${RESET}${BOLD_CYAN}I${RESET_BOLD}${WHITE}]${RESET}"

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
      _GIT_INFO_CACHE="${BOLD_RED}${git_branch}${status_suffix}${RESET_BOLD}"
    else
      _GIT_INFO_CACHE="${BOLD_GREEN}${git_branch}${RESET_BOLD}"
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
  blocks=$(command ls -lA . 2>/dev/null | awk '/^total/ { print $2 }')
  blocks=${blocks:-0}

  case "$(uname)" in
    Darwin) block_size=512 ;;   # macOS
    Linux)  block_size=1024 ;;  # Linux
    *)      block_size=512 ;;   # Fallback
  esac

  bytes=$((blocks * block_size))
  _humanize_size <<< "${bytes}"
}

_dir_info() {
  local size count
  size=$(_get_dir_size)
  count=$(/bin/ls -A1 2>/dev/null | wc -l | tr -d '[:space:]')
  echo "${BOLD_CYAN}${count} | ${size}${RESET_BOLD}"
}

_shorten_path() {
  local full_path="${1:-$PWD}"
  local head_count=2
  local tail_count=2
  local prefix=""
  local trimmed_path="$full_path"

  # Replace $HOME with ~ if applicable
  if [[ "$full_path" == "$HOME"* ]]; then
    prefix="~"
    trimmed_path="${full_path/#$HOME/}"
  fi

  # Split path into array
  local parts=()
  IFS='/' read -rA parts <<< "${trimmed_path#/}"  # remove leading slash if any

  local total_parts=${#parts[@]}
  local path_out=""

  if (( total_parts > head_count + tail_count + 1 )); then
    path_out="${prefix}/${(j:/:)parts[1,head_count]}/.../${(j:/:)parts[-$tail_count,-1]}"
  else
    path_out="${prefix}/${(j:/:)parts}"
  fi

  echo "$path_out"
}

# Prompt
_update_prompt() {
  local last_status=$1

  local git_info=$(_git_info)
  local dir_info=$(_dir_info)

  # Line 1 — appended after any injected prompt prefix (e.g., (base))
  PROMPT=" ${BOLD_BLUE}%D{%H:%M:%S}${RESET_BOLD} :: "
  PROMPT+="${BOLD_MAGENTA}$(_shorten_path)${RESET_BOLD}"
  [[ -n "$git_info" ]] && PROMPT+=" :: ${git_info}"
  PROMPT+=" :: ${dir_info}
"

  # Line 2 — status-aware prompt symbol
  if [[ $last_status -eq 0 ]]; then
    PROMPT+="${BOLD_GREEN}>${RESET_BOLD} "
  else
    PROMPT+="${BOLD_RED}<${RESET_BOLD} "
  fi

  PS2="${BOLD_BLUE}>>${RESET_BOLD} "
}

# Hooks to update the prompt
_prompt_precmd() {
  _update_prompt $?
  RPROMPT=$VIM_MODE
}

# Register hooks
autoload -Uz add-zsh-hook
add-zsh-hook precmd _prompt_precmd

# Interactive shell setup
if [[ $- == *i* ]]; then
  _update_prompt 0
  RPROMPT=$VIM_MODE

  autoload -Uz compinit
  zmodload zsh/complist
  zmodload zsh/zle
  compinit -C
fi
