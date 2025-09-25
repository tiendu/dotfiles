# ~/.zshrc
##### Global Color Variables
autoload -U colors && colors
RESET="%f"            RESET_BOLD="%f%b"
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

##### General environment
export EDITOR="nvim"
export VISUAL="nvim"
export LESS="e M q R F X z -3"

##### Tool initializers
if [[ $- == *i* ]]; then
  command -v rg >/dev/null && alias grep='rg --hidden --smart-case'
  command -v fd >/dev/null && alias find='fd'
fi
if command -v eza >/dev/null; then
  alias ls="eza"; alias ll="eza -l"; alias la="eza -la"; alias tree="eza --tree --level=3"
else
  if [[ "$OSTYPE" == darwin* ]]; then
    alias ls="ls -G"; alias tree="ls -R"
  else
    alias ls="ls --color=auto"; alias tree="ls -R"
  fi
fi
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

##### Aliases for interactive shell
if [[ $- == *i* ]]; then
  alias rm='rm -i' cp='cp -i' mv='mv -i' l='ls' g='git' e='nvim'
  alias h='fc -ln 1'
  alias ta="tmux attach || tmux new"
  alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
  alias ..='cd ..' ...='cd ../..' ....='cd ../../..'
fi

##### Cross-platform clipboard
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
    pbcopy() { :; }; pbpaste() { echo ""; }
  fi
fi
_paste_clip_after()  { LBUFFER+=$(pbpaste); }
_paste_clip_before() { RBUFFER="$(pbpaste)$RBUFFER"; }
zle -N _paste_clip_after
zle -N _paste_clip_before
bindkey -M vicmd 'p' _paste_clip_after
bindkey -M vicmd 'P' _paste_clip_before
bindkey -M viins '^V' _paste_clip_after

##### Tiny helpers
mkcd(){ mkdir -p -- "$1" && cd -- "$1"; }
extract(){ case "$1" in
  *.tar.bz2) tar xjf "$1" ;; *.tar.gz) tar xzf "$1" ;; *.zip) unzip -q "$1" ;;
  *.tar.xz) tar xJf "$1" ;; *.rar) unrar x -idq "$1" ;; *) echo "Unknown archive"; return 1;;
esac }

##### History & Shell options
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=${HISTFILE:-$HOME/.zsh_history}
setopt APPEND_HISTORY SHARE_HISTORY INC_APPEND_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE HIST_REDUCE_BLANKS HIST_VERIFY
setopt EXTENDED_HISTORY HIST_FIND_NO_DUPS HIST_SAVE_NO_DUPS
setopt INC_APPEND_HISTORY_TIME HIST_FCNTL_LOCK

setopt CORRECT MENUCOMPLETE AUTO_MENU LIST_PACKED
setopt AUTOCD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_MINUS
setopt INTERACTIVE_COMMENTS LONG_LIST_JOBS NO_BEEP GLOBDOTS
setopt PROMPT_SUBST NO_FLOW_CONTROL PIPE_FAIL

setopt NO_CLOBBER RM_STAR_WAIT

setopt AUTO_PARAM_SLASH NO_CASE_GLOB NUMERIC_GLOBSORT
setopt COMPLETE_ALIASES NOTIFY WARN_CREATE_GLOBAL

##### Vim mode & Keybinds
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

##### RPROMPT for Vim mode
function zle-keymap-select {
  local normal="%K{yellow}${BOLD_WHITE} NOR %k${RESET_BOLD}"
  local insert="%K{green}${BOLD_WHITE} INS %k${RESET_BOLD}"
  VIM_MODE=$([[ $KEYMAP == vicmd ]] && echo $normal || echo $insert)
  RPROMPT=$VIM_MODE
  zle reset-prompt
}
zle -N zle-keymap-select
zle -N zle-line-init zle-keymap-select

##### Directory metrics
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
chpwd() { _dm_ts=0; }  # invalidate cache on cd
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
  PROMPT=" %K{blue} ${BOLD_WHITE}%D{%H:%M:%S}${RESET_BOLD} %k :: ${BOLD_MAGENTA}$(_shorten_path)${RESET_BOLD} :: ${d}
 $([[ $s -eq 0 ]] && echo "${BOLD_GREEN}>${RESET_BOLD}" || echo "${BOLD_RED}<${RESET_BOLD}") "
  PS2="${BOLD_BLUE}>>${RESET_BOLD} "
}
_prompt_precmd() {
  _update_prompt $?
  # RPROMPT="${VIM_MODE:-}"
}

# Cleaner redraw
setopt PROMPT_CR

autoload -Uz add-zsh-hook
add-zsh-hook precmd _prompt_precmd

##### Syntax highlighting
_custom_highlight() {
  region_highlight=()
  local buffer="$BUFFER"
  local offset=0 remaining="$buffer" found_command=0 word rel_idx idx_start idx_end
  local -a words=(${(z)buffer})
  local -a delimiters=(";" "|" "||" "&&" "|&" "&" "(" ")" ";;&" ";|")
  local -a reserved=(if then else elif fi do done case esac while until for repeat select time function coproc '!' in)
  local -a starts_cmd_after=(then do elif else time '!' fi done esac)
  local expect_for_var=0
  local in_for_list=0
  local expect_func_name=0
  for word in "${words[@]}"; do
    [[ -z "${word// }" ]] && continue
    rel_idx="${remaining%%${word}*}"
    idx_start=$((offset + ${#rel_idx}))
    idx_end=$((idx_start + ${#word}))
    offset=$((idx_end))
    remaining="${remaining#"$rel_idx$word"}"
    # delimiters reset
    if [[ " ${delimiters[*]} " == *" $word "* ]]; then
      found_command=0
      in_for_list=0
      expect_for_var=0
      expect_func_name=0
      continue
    fi
    # reserved words
    if [[ " ${reserved[*]} " == *" $word "* ]]; then
      region_highlight+=("$idx_start $idx_end fg=yellow,bold")
      case $word in
        for) expect_for_var=1; found_command=0 ;;
        in)  in_for_list=1; found_command=0 ;;
        do)  in_for_list=0; found_command=0 ;;
        function) expect_func_name=1; found_command=0 ;;
      esac
      if [[ " ${starts_cmd_after[*]} " == *" $word "* ]]; then
        found_command=0
      fi
      continue
    fi
    # after "for" --> variable
    if (( expect_for_var )); then
      region_highlight+=("$idx_start $idx_end fg=blue,bold")
      expect_for_var=0
      continue
    fi
    # after "function" --> function name
    if (( expect_func_name )); then
      region_highlight+=("$idx_start $idx_end fg=blue,bold")
      expect_func_name=0
      continue
    fi
    # inside "in" list
    if (( in_for_list )); then
      region_highlight+=("$idx_start $idx_end fg=white")
      continue
    fi
    # assignments at command start
    if (( found_command == 0 )) && [[ $word == [A-Za-z_][A-Za-z0-9_]*=* ]]; then
      region_highlight+=("$idx_start $idx_end fg=blue")
      continue
    fi
    # first word = command check
    if (( found_command == 0 )); then
      if whence -w -- "$word" &>/dev/null; then
        region_highlight+=("$idx_start $idx_end fg=green,bold")
      else
        region_highlight+=("$idx_start $idx_end fg=red,bold")
      fi
      found_command=1
    fi
  done
}
_highlight_pre_redraw() { (( ${#BUFFER} > 4000 )) && { region_highlight=(); return; }; _custom_highlight }
_highlight_finish() { region_highlight=() }
zle -N zle-line-pre-redraw _highlight_pre_redraw
zle -N zle-line-finish _highlight_finish

##### Autopair
if [[ $- == *i* ]]; then
  : ${AP_MAX:=4000}
  _autopair() {
    (( ${#BUFFER} > AP_MAX )) && return
    local key="$1" close="$2" mode="$3" prev="${LBUFFER[-1]}" next="${RBUFFER[1]}"
    [[ $prev == '\' ]] && { LBUFFER+="$key"; return; }
    if [[ $prev == "$key" ]]; then
      LBUFFER+="$key"; [[ $next == "$close" ]] && RBUFFER="$close$RBUFFER"; return
    fi
    # Don't meddle during completion/menu or when input is pending, just insert literally
    if [[ -n $COMPSYS && ( $WIDGET == (menu-*) || $PENDING -gt 0 ) ]]; then
      LBUFFER+="$key"; return
    fi
    if [[ "$key" == '"' || "$key" == "'" ]]; then
      if [[ "$next" == [[:alnum:]_] ]]; then LBUFFER+="$key"; return; fi
      # Extra conservative: right after '=' with a word ahead, insert single
      if [[ "$prev" == "=" && "$next" == [[:alnum:]_] ]]; then LBUFFER+="$key"; return; fi
    fi
    # Skip for variable declarations
    if [[ "$next" == [\$\?\!\.\,\:\;\=] && "$next" != "$close" ]]; then LBUFFER+="$key"; return; fi
    # Skip before path
    if [[ "$next" == /* || "$next" == "~"* ]]; then LBUFFER+="$key"; return; fi
    if [[ $mode == always ]]; then LBUFFER+="$key$close"; zle backward-char; return; fi
    if [[ $mode == boundary ]]; then
      if [[ -z "$prev" || "$prev" == [[:space:][:punct:]] ]] && [[ -z "$next" || "$next" == [[:space:][:punct:]] ]]; then
        LBUFFER+="$key$close"; zle backward-char; return
      fi
    fi
    LBUFFER+="$key"
  }
  _autopair_close() { local close="$1"; [[ ${RBUFFER[1]} == "$close" ]] && zle forward-char || LBUFFER+="$close"; }
  _ap_backspace() {
    if [[ -n $LBUFFER && -n $RBUFFER ]]; then
      local l="${LBUFFER[-1]}" r="${RBUFFER[1]}"
      case "$l$r" in "''"|\"\"|\(\)|\[\]|\{\}) LBUFFER=${LBUFFER[1,-2]}; RBUFFER=${RBUFFER[2,-1]}; return;;
      esac
    fi
    zle backward-delete-char
  }
  # Thin wrappers
  _ap_apos(){ _autopair "'" "'" boundary }; _ap_quot(){ _autopair '"' '"' boundary }
  _ap_open-paren(){ _autopair "(" ")" boundary }; _ap_close-paren(){ _autopair_close ")" }
  _ap_open-brack(){ _autopair "[" "]" boundary }; _ap_close-brack(){ _autopair_close "]" }
  _ap_open-brace(){ _autopair "{" "}" boundary }; _ap_close-brace(){ _autopair_close "}" }
  # Widgets
  zle -N _ap_apos; zle -N _ap_quot; zle -N _ap_open-paren; zle -N _ap_close-paren
  zle -N _ap_open-brack; zle -N _ap_close-brack; zle -N _ap_open-brace; zle -N _ap_close-brace
  zle -N _ap_backspace
  # Bindings (vi insert mode)
  bindkey -M viins \
    "'"  _ap_apos   '"'  _ap_quot \
    '('  _ap_open-paren  ')'  _ap_close-paren \
    '['  _ap_open-brack  ']'  _ap_close-brack \
    '{'  _ap_open-brace  '}'  _ap_close-brace \
    '^?' _ap_backspace   '^H' _ap_backspace
fi

##### Interactive-only setup (keeps non-interactive shells fast)
if [[ $- == *i* ]]; then
  autoload -Uz compinit compaudit
  # Harden completion dirs (safe + quiet)
  compaudit | while read -r p; do
    [[ $p == $HOME/* ]] && chmod g-w,o-w "$p" 2>/dev/null || true
  done
  zmodload zsh/complist
  # Cache locations
  typeset -g _compdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compdump"
  typeset -g _compcache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compcache"
  mkdir -p -- "$_compcache" "${_compdump:h}"
  # Fast init with cache file
  compinit -C -d "$_compdump"
  # Completion styles
  zstyle ':completion:*' use-cache on
  zstyle ':completion:*' cache-path "$_compcache"
  zstyle ':completion:*' menu select
  zstyle ':completion:*' matcher-list \
  'm:{a-z}={A-Za-z}' \
  'r:|[._-]=** r:|=*'
  zstyle ':completion:*' group-name ''
  zstyle ':completion:*' list-colors ''
  zstyle ':completion:*:history-words' menu yes select
  zstyle ':completion:*:history-words' list-colors ''
  # Detect newly installed commands without restarting shell
  zstyle ':completion:*' rehash true
  export PROMPT_EOL_MARK=""
fi

typeset -Ug path fpath
[[ -d "/opt/homebrew/bin" ]]   && path=(/opt/homebrew/bin $path)
[[ -d "$HOME/miniforge/bin" ]] && path=($HOME/miniforge/bin $path)
export PATH
