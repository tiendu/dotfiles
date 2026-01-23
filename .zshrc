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
  alias rm='rm -i' cp='cp -i' mv='mv -i' l='ls' e='nvim'
  alias h='fc -ln 1'
  alias ta="tmux attach || tmux new"
  alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
  alias ..='cd ..' ...='cd ../..' ....='cd ../../..'
fi

##### Minimal safe git aliases
alias g='git'
# status & log (always know where you are)
alias gs='git status -sb'
alias gl='git log --oneline --decorate --graph --max-count=15'
# update branch safely
alias gf='git fetch --prune'
alias gup='git fetch --prune && git rebase origin/main'
# staging / undo
alias ga='git add -p'                 # stage hunks (best habit)
alias gr='git restore'                # discard working changes (paths)
alias grs='git restore --staged'      # unstage
# push safely
alias gp='git push'
alias gpf='git push --force-with-lease'
# stash (with message)
alias gst='git stash push -m'
alias gstp='git stash pop'

##### Cross-platform clipboard
# pbcopy [file...] or stdin; pbpaste prints content
if [[ $OSTYPE == darwin* ]]; then
  pbcopy() {
    if (( $# )); then
      command cat -- "$@" | command pbcopy
    else
      command pbcopy  # reads from stdin
    fi
  }
  pbpaste() { command pbpaste; }
else
  if command -v wl-copy &>/dev/null; then
    pbcopy() {
      if (( $# )); then command cat -- "$@" | command wl-copy
      else command wl-copy
      fi
    }
    pbpaste() { command wl-paste; }
  elif command -v xclip &>/dev/null; then
    pbcopy() {
      if (( $# )); then command cat -- "$@" | command xclip -selection clipboard
      else command xclip -selection clipboard
      fi
    }
    pbpaste() { command xclip -selection clipboard -o; }
  elif command -v xsel &>/dev/null; then
    pbcopy() {
      if (( $# )); then command cat -- "$@" | command xsel --clipboard --input
      else command xsel --clipboard --input
      fi
    }
    pbpaste() { command xsel --clipboard --output; }
  else
    pbcopy() { :; }
    pbpaste() { printf ''; }
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
setopt PROMPT_SUBST NO_FLOW_CONTROL PIPE_FAIL ALWAYS_TO_END

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
bindkey -M viins $'\x7f' backward-delete-char
bindkey -M viins $'\x08' backward-delete-char

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

##### Vim mode
function zle-keymap-select {
  local normal="%K{yellow}${BOLD_WHITE} NOR %k${RESET_BOLD}"
  local insert="%K{green}${BOLD_WHITE} INS %k${RESET_BOLD}"
  VIM_MODE=$([[ $KEYMAP == vicmd ]] && echo $normal || echo $insert)
  _update_prompt $?
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
  local s=$1 d=$(_dir_info) vm="${VIM_MODE:-}"
  PROMPT=" ${vm} :: %K{blue} ${BOLD_WHITE}%D{%H:%M:%S}${RESET_BOLD} %k :: ${BOLD_MAGENTA}$(_shorten_path)${RESET_BOLD} :: ${d}
 $([[ $s -eq 0 ]] && echo "${BOLD_GREEN}>${RESET_BOLD}" || echo "${BOLD_RED}<${RESET_BOLD}") "
  PS2="${BOLD_BLUE}>>${RESET_BOLD} "
}
_prompt_precmd() {
  _update_prompt $?
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
  # Don't reset command-state on bare parentheses (less weird in shell)
  local -a delimiters=(";" "|" "||" "&&" "|&" "&" ";;&" ";|")
  local -a reserved=(if then else elif fi do done case esac while until for repeat select time function coproc '!' in)
  local -a starts_cmd_after=(then do elif else time '!' fi done esac)
  local expect_for_var=0 in_for_list=0 expect_func_name=0
  local in_test=0 in_arith=0
  for word in "${words[@]}"; do
    [[ -z "${word// }" ]] && continue
    rel_idx="${remaining%%${word}*}"
    idx_start=$((offset + ${#rel_idx}))
    idx_end=$((idx_start + ${#word}))
    offset=$((idx_end))
    remaining="${remaining#"$rel_idx$word"}"
    if [[ $word == '[[' ]]; then
      region_highlight+=("$idx_start $idx_end fg=yellow,bold")
      in_test=1; found_command=0
      continue
    fi
    if (( in_test )) && [[ $word == ']]' ]]; then
      region_highlight+=("$idx_start $idx_end fg=yellow,bold")
      in_test=0; found_command=0
      continue
    fi
    # full token like "((i++))" or "((a+=b))"
    if [[ $word == '((('* && $word == *'))' && ${#word} -ge 4 ]]; then
      region_highlight+=("$idx_start $((idx_start+2)) fg=yellow,bold")
      region_highlight+=("$((idx_end-2)) $idx_end fg=yellow,bold")
      if (( idx_end - idx_start > 4 )); then
        region_highlight+=("$((idx_start+2)) $((idx_end-2)) fg=white")
      fi
      found_command=0
      continue
    fi
    if [[ $word == \(\(* ]]; then
      region_highlight+=("$idx_start $((idx_start+2)) fg=yellow,bold")
      in_arith=1; found_command=0
      if (( idx_end - idx_start > 2 )); then
        region_highlight+=("$((idx_start+2)) $idx_end fg=white")
      fi
      continue
    fi
    if (( in_arith )) && [[ $word == *\)\) ]]; then
      if (( idx_end - idx_start > 2 )); then
        region_highlight+=("$idx_start $((idx_end-2)) fg=white")
      fi
      region_highlight+=("$((idx_end-2)) $idx_end fg=yellow,bold")
      in_arith=0; found_command=0
      continue
    fi
    if [[ $word == '((' || $word == '(((' ]]; then
      region_highlight+=("$idx_start $idx_end fg=yellow,bold")
      in_arith=1; found_command=0
      continue
    fi
    if (( in_arith )) && [[ $word == '))' ]]; then
      region_highlight+=("$idx_start $idx_end fg=yellow,bold")
      in_arith=0; found_command=0
      continue
    fi
    if (( in_test || in_arith )); then
      region_highlight+=("$idx_start $idx_end fg=white")
      continue
    fi
    if [[ " ${delimiters[*]} " == *" $word "* ]]; then
      found_command=0
      in_for_list=0
      expect_for_var=0
      expect_func_name=0
      continue
    fi
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
    if (( expect_for_var )); then
      region_highlight+=("$idx_start $idx_end fg=blue,bold")
      expect_for_var=0
      continue
    fi
    if (( expect_func_name )); then
      region_highlight+=("$idx_start $idx_end fg=blue,bold")
      expect_func_name=0
      continue
    fi
    if (( in_for_list )); then
      region_highlight+=("$idx_start $idx_end fg=white")
      continue
    fi
    if (( found_command == 0 )) && [[ $word == [A-Za-z_][A-Za-z0-9_]*=* ]]; then
      region_highlight+=("$idx_start $idx_end fg=blue")
      continue
    fi
    # variables
    if [[ $word == '$'* || $word == '${'* ]]; then
      region_highlight+=("$idx_start $idx_end fg=blue")
      continue
    fi
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
  _autopair_open() {
    (( ${#BUFFER} > AP_MAX )) && { LBUFFER+="$1"; return; }
    local key="$1" close="$2" mode="${3:-boundary}"
    local prev="${LBUFFER[-1]-}" next="${RBUFFER[1]-}"
    # escaped char, or completion/menu/pending input -> literal
    if [[ $prev == \\ || ( -n "$COMPSYS" && ( $WIDGET == menu-* || $PENDING -gt 0 ) ) ]]; then
      LBUFFER+="$key"; return
    fi
    # double-tap opener -> still insert a fresh pair
    if [[ $prev == "$key" ]]; then
      LBUFFER+="$key$close"; zle backward-char
      return
    fi
    # quotes are conservative: no pairing after words/closers or x="word"
    if [[ $key == \' || $key == \" ]]; then
      if [[ $prev == "=" ]]; then
        # allow only if next is boundary
        if [[ -z $next || $next == [[:space:][:punct:]] ]]; then
          LBUFFER+="$key$close"; zle backward-char; return
        else
          LBUFFER+="$key"; return
        fi
      fi
      if [[ $next == [[:alnum:]_] || $prev == [[:alnum:]_\)\]\}] ]]; then
        LBUFFER+="$key"; return
      fi
    fi
    # hard stops: after dot/equals -> literal (keep obj.method( and x=( simple)
    if [[ $prev == [.=] ]]; then
      LBUFFER+="$key"; return
    fi
    # skip when next looks like a path start
    if [[ $next == [/~] ]]; then
      LBUFFER+="$key"; return
    fi
    # mode-based pairing
    if [[ $mode == always ]]; then
      LBUFFER+="$key$close"; zle backward-char; return
    fi
    if [[ $mode == boundary ]]; then
      # do not boundary-pair immediately after a closer
      if [[ $prev != [\)\]\}] ]]; then
        if [[ ( -z $prev || $prev == [[:space:][:punct:]] ) && ( -z $next || $next == [[:space:][:punct:]] ) ]]; then
          LBUFFER+="$key$close"; zle backward-char; return
        fi
      fi
    fi
    # default: literal insert
    LBUFFER+="$key"
  }
  _autopair_backspace() {
    if [[ -n $LBUFFER && -n $RBUFFER ]]; then
      local l="${LBUFFER[-1]}" r="${RBUFFER[1]}"
      case "$l$r" in
        "''"|'""'|"()"|"[]"|"{}")
          LBUFFER=${LBUFFER[1,-2]}
          RBUFFER=${RBUFFER[2,-1]}
          return
        ;;
      esac
    fi
    zle .backward-delete-char
  }
  # Thin wrappers
  _ap_apos(){ _autopair_open $'\'' $'\'' boundary }
  _ap_quot(){ _autopair_open $'\"' $'\"' boundary }
  # Widgets
  zle -N _ap_apos
  zle -N _ap_quot
  zle -N _autopair_backspace
  # Bindings (vi insert mode)
  bindkey -M viins \
    "'"  _ap_apos   '"'  _ap_quot \
    $'\x7f' _autopair_backspace  $'\x08' _autopair_backspace
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
