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
export EDITOR="nvim"
export VISUAL="nvim"
export LESS="e M q R F X z -3"

##### Tool Initializers
command -v rg >/dev/null && alias grep="rg"
command -v fd >/dev/null && alias find="fd"
if command -v eza >/dev/null; then
  alias ls="eza"
  alias ll="eza -l"
  alias la="eza -la"
  alias tree="eza --tree --level=3"
else
  alias ls="ls --color=auto"
  alias tree="ls -R"
fi
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

##### Aliases
alias rm='rm -i' cp='cp -i' mv='mv -i' l='ls' g='git' e='nvim' f='find' r='grep'
alias h="fc -l 1 | awk '{\$1=\"\"; print substr(\$0,2)}'"
alias ta="tmux attach || tmux new"
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias ..='cd ..' ...='cd ../..' ....='cd ../../..'

##### Clipboard Cross-platform
case "$OSTYPE" in
  darwin*) alias pbcopy='pbcopy'; alias pbpaste='pbpaste' ;;
  *)  if command -v xclip &>/dev/null; then
        alias pbcopy='xclip -selection clipboard'
        alias pbpaste='xclip -selection clipboard -o'
      elif command -v xsel &>/dev/null; then
        alias pbcopy='xsel --clipboard --input'
        alias pbpaste='xsel --clipboard --output'
      else
        alias pbcopy='cat > /dev/null'; alias pbpaste='echo ""'
      fi
  ;;
esac

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
  local normal="${WHITE}[${RESET}${BOLD_YELLOW}N${RESET_BOLD}${WHITE}]${RESET}"
  local insert="${WHITE}[${RESET}${BOLD_CYAN}I${RESET_BOLD}${WHITE}]${RESET}"
  VIM_MODE=$([[ $KEYMAP == vicmd ]] && echo $normal || echo $insert)
  RPROMPT=$VIM_MODE
  zle reset-prompt
}
zle -N zle-keymap-select
zle -N zle-line-init zle-keymap-select

##### Path & Prompt Info
_humanize_size() {
  awk '{s=$1; split("B KB MB GB TB",u); for(i=1;s>=1024&&i<5;i++)s/=1024; printf "%.1f%s", s, u[i]}'
}
_dir_size() {
  local bytes
  if [[ $(uname) == Darwin ]]; then
    bytes=$(find . -maxdepth 1 -type f -exec stat -f%z {} + 2>/dev/null)
  else
    bytes=$(find . -maxdepth 1 -type f -exec stat --format=%s {} + 2>/dev/null)
  fi
  echo "${bytes}" | awk '{s+=$1} END {print s}' | _humanize_size
}
_dir_info() {
  local size=$(_dir_size)
  local count=$(command ls -A1 2>/dev/null | wc -l | tr -d '[:space:]')
  echo "${BOLD_CYAN}${count} | ${size}${RESET_BOLD}"
}
_shorten_path() {
  local full="${1:-$PWD}" prefix=""
  [[ "$full" == "$HOME"* ]] && prefix="~" full="${full/#$HOME/}"
  IFS='/' read -rA parts <<< "${full#/}"
  (( ${#parts[@]} > 4 )) && echo "${prefix}/${(j:/:)parts[1,2]}/.../${(j:/:)parts[-2,-1]}" || echo "${prefix}/${(j:/:)parts}"
}

_update_prompt() {
  local s=$1 d=$(_dir_info)
  PROMPT="${BOLD_WHITE}┏━${RESET_BOLD}${BOLD_BLUE}%D{%H:%M:%S}${RESET_BOLD} :: ${BOLD_MAGENTA}$(_shorten_path)${RESET_BOLD} :: $d
${BOLD_WHITE}┗━${RESET_BOLD}$([[ $s -eq 0 ]] && echo "${BOLD_GREEN}❯${RESET_BOLD}" || echo "${BOLD_RED}❮${RESET_BOLD}") "
  PS2="${BOLD_BLUE}»${RESET_BOLD} "
}
_prompt_precmd() {
  _update_prompt $?
  RPROMPT="${VIM_MODE:-}"
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

##### Init Interactive Shell
if [[ $- == *i* ]]; then
  autoload -Uz compinit
  zmodload zsh/complist
  zmodload zsh/zle
  compinit -C
fi
