# ~/.zshrc
##### Global Color Variables
autoload -U colors && colors
RESET="%f%k"          RESET_BOLD="%f%k%b"
RED="%F{red}"         BOLD_RED="%B%F{red}"
GREEN="%F{green}"     BOLD_GREEN="%B%F{green}"
YELLOW="%F{yellow}"   BOLD_YELLOW="%B%F{yellow}"
CYAN="%F{cyan}"       BOLD_CYAN="%B%F{cyan}"
WHITE="%F{white}"     BOLD_WHITE="%B%F{white}"
MAGENTA="%F{magenta}" BOLD_MAGENTA="%B%F{magenta}"
BLUE="%F{blue}"       BOLD_BLUE="%B%F{blue}"

##### Modules
zmodload zsh/zle
zmodload -F zsh/stat b:zstat
zmodload zsh/datetime

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
if [[ $- == *i* ]]; then
  alias rm='rm -i' cp='cp -i' mv='mv -i' l='ls' g='git' e='nvim'
  alias h='fc -ln 1'
  alias ta="tmux attach || tmux new"
  alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
  alias ..='cd ..' ...='cd ../..' ....='cd ../../..'
fi

##### Cross-platform clipboard (functions for consistent behavior)
# pbcopy [file...] or stdin; pbpaste prints content
if [[ "$OSTYPE" == darwin* ]]; then
  pbcopy() {
    if (( $# )); then
      { local f; for f in "$@"; do command cat "$f"; done; } | command pbcopy
    else
      command pbcopy
    fi
  }
  pbpaste() { command pbpaste; }
else
  if command -v wl-copy &>/dev/null; then
    pbcopy() { (( $# )) && cat -- "$@" | wl-copy || wl-copy; }
    pbpaste() { wl-paste; }
  elif command -v xclip &>/dev/null; then
    pbcopy() { (( $# )) && cat -- "$@" | xclip -selection clipboard || xclip -selection clipboard; }
    pbpaste() { xclip -selection clipboard -o; }
  elif command -v xsel &>/dev/null; then
    pbcopy() { (( $# )) && cat -- "$@" | xsel --clipboard --input || xsel --clipboard --input; }
    pbpaste() { xsel --clipboard --output; }
  else
    pbcopy() { :; } ; pbpaste() { echo ""; }
  fi
fi
_paste_clip_after()  { LBUFFER+=$(pbpaste); }
_paste_clip_before() { RBUFFER="$(pbpaste)$RBUFFER"; }
zle -N _paste_clip_after
zle -N _paste_clip_before
bindkey -M vicmd 'p' _paste_clip_after
bindkey -M vicmd 'P' _paste_clip_before
bindkey -M viins '^V' _paste_clip_after

##### History & Shell Options
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=${HISTFILE:-$HOME/.zsh_history}
setopt APPEND_HISTORY SHARE_HISTORY INC_APPEND_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE HIST_REDUCE_BLANKS HIST_VERIFY
setopt EXTENDED_HISTORY HIST_FIND_NO_DUPS HIST_SAVE_NO_DUPS

setopt CORRECT MENUCOMPLETE AUTO_MENU LIST_PACKED
setopt AUTOCD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_MINUS
setopt INTERACTIVE_COMMENTS LONG_LIST_JOBS NO_BEEP GLOBDOTS
setopt PROMPT_SUBST NO_FLOW_CONTROL PIPE_FAIL

##### Vim Mode & Keybinds
bindkey -v
autoload -Uz up-line-or-search down-line-or-search
bindkey -M viins '^P' up-line-or-search
bindkey -M viins '^N' down-line-or-search
bindkey -M vicmd '/' history-incremental-search-forward
bindkey -M vicmd '?' history-incremental-search-backward
bindkey -M viins 'jk' vi-cmd-mode
bindkey -M viins 'kj' vi-cmd-mode
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char

# History menu: list all matches that start with current prefix
autoload -Uz history-beginning-search-menu
zle -N history-beginning-search-menu
bindkey -M viins '^R' history-beginning-search-menu
bindkey -M vicmd 'R' history-beginning-search-menu

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
  local normal="%K{yellow}${BOLD_WHITE} NOR %k${RESET_BOLD}"
  local insert="%K{green}${BOLD_WHITE} INS %k${RESET_BOLD}"
  VIM_MODE=$([[ $KEYMAP == vicmd ]] && echo $normal || echo $insert)
  RPROMPT=$VIM_MODE
  zle reset-prompt
}
zle -N zle-keymap-select
zle -N zle-line-init zle-keymap-select

##### Directory metrics (fast path + caching)
typeset -g  _dm_pwd="" _dm_size="" _dm_count=0
typeset -gi _dm_ts=0 _DM_TTL=3 _DM_MAX_ENTRIES=4000

_humanize_size() {
  local -F 2 s=$1; local -a u=(B KB MB GB TB PB); local i=1
  while (( s >= 1024 && i < ${#u} )); do s=$(( s / 1024.0 )); (( i++ )); done
  printf '%.1f%s' $s $u[i]
}
_dir_metrics() {
  local now=$EPOCHSECONDS
  if [[ $_dm_pwd == "$PWD" ]] && (( now - _dm_ts < _DM_TTL )); then
    return
  fi
  local -a entries
  entries=( *(DN) )
  _dm_count=${#entries}
  if (( _dm_count == 0 )); then
    _dm_size="0B"
  elif (( _dm_count > _DM_MAX_ENTRIES )); then
    _dm_size="--"
  else
    local -A S; local -i bytes=0
    local f
    for f in *(.DN); do
      zstat -H S -- "$f" 2>/dev/null && (( bytes += S[size] ))
    done
    _dm_size=$(_humanize_size $bytes)
  fi
  _dm_pwd=$PWD
  _dm_ts=$now
}
chpwd() { _dm_ts=0; }  # Invalidate cache on cd
_dir_info() { _dir_metrics; print -r -- "${BOLD_CYAN}${_dm_count} | ${_dm_size}${RESET_BOLD}"; }
_shorten_path() {
  local full="${1:-$PWD}" prefix=""
  [[ "$full" == "$HOME"* ]] && prefix="~" full="${full/#$HOME/}"
  local -a parts; IFS='/' read -rA parts <<< "${full#/}"
  (( ${#parts} == 0 )) && { print -r -- "${prefix}/"; return; }
  if (( ${#parts} > 4 )); then
    print -r -- "${prefix}/${(j:/:)parts[1,2]}/.../${(j:/:)parts[-2,-1]}"
  else
    print -r -- "${prefix}/${(j:/:)parts}"
  fi
}

_update_prompt() {
  local s=$1 d=$(_dir_info)
  PROMPT=" %K{blue} ${BOLD_WHITE}%D{%H:%M:%S}${RESET_BOLD}  %k :: ${BOLD_MAGENTA}$(_shorten_path)${RESET_BOLD} :: ${d}
 $([[ $s -eq 0 ]] && echo "${BOLD_GREEN}>${RESET_BOLD}" || echo "${BOLD_RED}<${RESET_BOLD}") "
  PS2="${BOLD_BLUE}>>${RESET_BOLD} "
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
  local -a delimiters=(";" "|" "||" "&&" "|&" "&" "(" ")" ";;&" ";|")
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
_highlight_pre_redraw() { emulate -L zsh; (( ${#BUFFER} > 4000 )) && { region_highlight=(); return; }; _custom_highlight }
_highlight_finish() { region_highlight=() }
zle -N zle-line-pre-redraw _highlight_pre_redraw
zle -N zle-line-finish _highlight_finish

##### Autopair
if [[ $- == *i* ]]; then
  _autopair() {
    local key="$1" close="$2" mode="$3"
    local prev="${LBUFFER[-1]}"
    if [[ "$prev" == "$key" ]]; then
      LBUFFER+="$key"
      if [[ $RBUFFER[1] == "$close" ]]; then
        RBUFFER="$close$RBUFFER"
      fi
      return
    fi
    if [[ $RBUFFER[1] == "$close" ]]; then
      zle forward-char
      return
    fi
    if [[ "$mode" == "always" ]]; then
      LBUFFER+="$key$close"
      zle backward-char
      return
    fi
    if [[ "$mode" == "boundary" ]]; then
      local next="${RBUFFER[1]}"
      if [[ -z "$prev" || "$prev" == [[:space:][:punct:]] ]] && \
         [[ -z "$next" || "$next" == [[:space:][:punct:]] ]]; then
        LBUFFER+="$key$close"
        zle backward-char
        return
      fi
    fi
    LBUFFER+="$key"
  }
  zle -N _ap-apos  ; _ap-apos()  { _autopair "'" "'" "boundary" }
  zle -N _ap-quot  ; _ap-quot()  { _autopair '"' '"' "boundary" }
  bindkey -M viins "'" _ap-apos
  bindkey -M viins '"' _ap-quot
  _autopair-close() {
    local close="$1"
    if [[ $RBUFFER[1] == "$close" ]]; then
      zle forward-char
    else
      LBUFFER+="$close"
    fi
  }
  zle -N _ap-open-paren ; _ap-open-paren() { _autopair "(" ")" "boundary" }
  zle -N _ap-close-paren; _ap-close-paren(){ _autopair-close ")" }
  bindkey -M viins '(' _ap-open-paren
  bindkey -M viins ')' _ap-close-paren
  zle -N _ap-open-brack ; _ap-open-brack() { _autopair "[" "]" "boundary" }
  zle -N _ap-close-brack; _ap-close-brack(){ _autopair-close "]" }
  bindkey -M viins '[' _ap-open-brack
  bindkey -M viins ']' _ap-close-brack
  zle -N _ap-open-brace ; _ap-open-brace() { _autopair "{" "}" "boundary" }
  zle -N _ap-close-brace; _ap-close-brace(){ _autopair-close "}" }
  bindkey -M viins '{' _ap-open-brace
  bindkey -M viins '}' _ap-close-brace
  _ap-backspace() {
    if [[ -n $LBUFFER && -n $RBUFFER ]]; then
      local l="${LBUFFER[-1]}" r="${RBUFFER[1]}"
      case "$l$r" in
        "''"|\"\"|\(\)|\[\]|\{\})
          LBUFFER=${LBUFFER[1,-2]}
          RBUFFER=${RBUFFER[2,-1]}
          return
        ;;
      esac
    fi
    zle backward-delete-char
  }
  zle -N _ap-backspace
  bindkey -M viins '^?' _ap-backspace
  bindkey -M viins '^H' _ap-backspace
fi

##### Interactive-only setup (keeps non-interactive shells fast)
if [[ $- == *i* ]]; then
  autoload -Uz compinit
  zmodload zsh/complist
  local _compdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compdump"
  mkdir -p -- "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compcache"
  compinit -C -d "$_compdump"
  zstyle ':completion:*' use-cache on
  zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compcache"
  zstyle ':completion:*' menu select
  zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' \
                                 'r:|[._-]=* r:|=*'  # Partial/fuzzy-ish
  zstyle ':completion:*' group-name ''
  zstyle ':completion:*' list-colors ''
  zstyle ':completion:*:history-words' menu yes select
  zstyle ':completion:*:history-words' list-colors ''
  export PROMPT_EOL_MARK=""
fi

[[ -d "$HOME/miniforge/bin" ]] && PATH="$HOME/miniforge/bin:$PATH"
[[ -d "/opt/homebrew/bin" ]]   && PATH="/opt/homebrew/bin:$PATH"
export PATH
