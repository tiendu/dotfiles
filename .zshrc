# ~/.zshrc
##### Global Color Variables
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

##### General Environment
export LESS="e M q R F X z -3"

##### Tool Initializers
if command -v zoxide > /dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v rg > /dev/null 2>&1; then
  alias grep="rg"
fi

if command -v eza > /dev/null 2>&1; then
  alias ls="eza"
  alias ll="eza -l"
  alias la="eza -la"
  alias tree="eza --tree --level=3"
else
  alias ls="ls --color=auto"
  alias tree="ls -R"
fi

##### Aliases
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"
alias l="ls"
alias g="git"
alias e="nvim"
alias h="fc -l 1 | awk '{\$1=""; print substr(\$0,2)}'"
alias ta="tmux attach || tmux new"
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

##### Clipboard Cross-platform
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
  alias pbcopy='cat > /dev/null'
  alias pbpaste='echo ""'
fi

##### History & Shell Options
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt APPEND_HISTORY SHARE_HISTORY INC_APPEND_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE HIST_REDUCE_BLANKS HIST_VERIFY EXTENDED_HISTORY

setopt CORRECT MENUCOMPLETE AUTO_MENU LIST_PACKED
setopt AUTOCD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_MINUS
setopt INTERACTIVE_COMMENTS LONG_LIST_JOBS NO_BEEP GLOBDOTS
setopt PROMPT_SUBST
unsetopt BEEP

##### Vim Mode & Keybinds
bindkey -v
bindkey '^P' up-line-or-history
bindkey '^N' down-line-or-history
bindkey -M viins 'jk' vi-cmd-mode
bindkey -M viins 'kj' vi-cmd-mode
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char

# Insert "cd " when tab is hit on empty line
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

##### RPROMPT for Vim Mode
function zle-keymap-select {
  local NOR_PROMPT="${WHITE}[${RESET}${BOLD_YELLOW}N${RESET_BOLD}${WHITE}]${RESET}"
  local INS_PROMPT="${WHITE}[${RESET}${BOLD_CYAN}I${RESET_BOLD}${WHITE}]${RESET}"
  VIM_MODE=$([[ $KEYMAP == vicmd ]] && echo $NOR_PROMPT || echo $INS_PROMPT)
  RPROMPT=$VIM_MODE
  zle reset-prompt
}
zle -N zle-keymap-select
zle -N zle-line-init zle-keymap-select

##### Git, Path & Prompt Info
typeset -g _GIT_INFO_CACHE=""
typeset -g _GIT_INFO_LAST_DIR=""

_git_info() {
  local current_dir=$(git rev-parse --show-toplevel 2>/dev/null)
  [[ -z "$current_dir" ]] && return
  if [[ "$_GIT_INFO_LAST_DIR" == "$current_dir" && -n "$_GIT_INFO_CACHE" ]]; then
    echo "$_GIT_INFO_CACHE"
    return
  fi
  local git_branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  local added_count=0 modified_count=0 line
  while IFS= read -r line; do
    [[ "$line" == \?\?* ]] && ((added_count++))
    [[ "$line" == [MARCDU]?* || "$line" == ?[MARCDU]* ]] && ((modified_count++))
  done < <(git status --porcelain)
  local suffix=""
  ((added_count)) && suffix+=" +$added_count"
  ((modified_count)) && suffix+=" !$modified_count"
  _GIT_INFO_CACHE="${git_branch:+${(L)git_branch}${suffix:+ ${suffix}}}"
  _GIT_INFO_LAST_DIR="$current_dir"
  [[ -n "$git_branch" ]] && echo "${suffix:+${BOLD_RED}${git_branch}${suffix}${RESET_BOLD}}" || echo "${BOLD_GREEN}${git_branch}${RESET_BOLD}"
}

_humanize_size() {
  awk '{s=$1; split("B KB MB GB TB",u); for(i=1;s>=1024&&i<5;i++)s/=1024; printf "%.1f%s", s, u[i]}'
}
_get_dir_size() {
  local blocks=$(command ls -lA . 2>/dev/null | awk '/^total/ {print $2}')
  local bs=$([[ $(uname) == Darwin ]] && echo 512 || echo 1024)
  echo $((blocks * bs)) | _humanize_size
}
_dir_info() {
  local size=$(_get_dir_size)
  local count=$(/bin/ls -A1 2>/dev/null | wc -l | tr -d '[:space:]')
  echo "${BOLD_CYAN}${count} | ${size}${RESET_BOLD}"
}
_shorten_path() {
  local full="${1:-$PWD}" prefix=""
  [[ "$full" == "$HOME"* ]] && prefix="~" full="${full/#$HOME/}"
  IFS='/' read -rA parts <<< "${full#/}"
  (( ${#parts[@]} > 4 )) && echo "${prefix}/${(j:/:)parts[1,2]}/.../${(j:/:)parts[-2,-1]}" || echo "${prefix}/${(j:/:)parts}"
}

_update_prompt() {
  local last_status=$1
  local git=$(_git_info)
  local dir=$(_dir_info)
  PROMPT=" ${BOLD_BLUE}%D{%H:%M:%S}${RESET_BOLD} :: ${BOLD_MAGENTA}$(_shorten_path)${RESET_BOLD}"
  [[ -n "$git" ]] && PROMPT+=" :: $git"
  PROMPT+=" :: $dir
"
  PROMPT+=$([[ $last_status -eq 0 ]] && echo "${BOLD_GREEN}>${RESET_BOLD} " || echo "${BOLD_RED}<${RESET_BOLD} ")
  PS2="${BOLD_BLUE}>>${RESET_BOLD} "
}
_prompt_precmd() {
  _update_prompt $?
  RPROMPT=$VIM_MODE
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _prompt_precmd

##### Syntax Highlighting (valid commands only)
_custom_highlight() {
  emulate -L zsh
  setopt extended_glob
  region_highlight=()
  local buffer="$BUFFER"
  local -a words=(${(z)buffer})
  local -a delimiters=(";" "|" "&&" "||" "&" "(" ")")
  local offset=0
  local remaining="$buffer"
  local found_command=0
  for word in "${words[@]}"; do
    [[ -z "${word// }" ]] && continue
    local rel_idx="${remaining%%${word}*}"
    local index=$((offset + ${#rel_idx}))
    local end=$((index + ${#word}))
    offset=$((end))
    remaining="${remaining#"$rel_idx$word"}"
    if (( ${delimiters[(Ie)$word]} )); then
      found_command=0
      continue
    fi
    if (( found_command == 0 )); then
      if whence -w -- "$word" &>/dev/null; then
        region_highlight+=("$index $end fg=green,bold")
      else
        region_highlight+=("$index $end fg=red,bold")
      fi
      found_command=1
    fi
  done
}
_self_insert_wrapper() { zle .self-insert; _custom_highlight; zle reset-prompt }
_backspace_wrapper()  { zle .backward-delete-char; _custom_highlight; zle reset-prompt }
zle -N self-insert _self_insert_wrapper
zle -N backward-delete-char _backspace_wrapper
zle -N zle-keymap-select

##### Init Interactive Shell
if [[ $- == *i* ]]; then
  _update_prompt 0
  RPROMPT=$VIM_MODE
  autoload -Uz compinit
  zmodload zsh/complist
  zmodload zsh/zle
  compinit -C
fi
