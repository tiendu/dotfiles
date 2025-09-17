# ~/.zshrc
##### Colors
autoload -U colors && colors
RESET="%f" RESET_BOLD="%f%b"
RED="%F{red}" BOLD_RED="%B%F{red}"
GREEN="%F{green}" BOLD_GREEN="%B%F{green}"
YELLOW="%F{yellow}" BOLD_YELLOW="%B%F{yellow}"
CYAN="%F{cyan}" BOLD_CYAN="%B%F{cyan}"
WHITE="%F{white}" BOLD_WHITE="%B%F{white}"
MAGENTA="%F{magenta}" BOLD_MAGENTA="%B%F{magenta}"
BLUE="%F{blue}" BOLD_BLUE="%B%F{blue}"

##### Modules
zmodload zsh/zle zsh/datetime; zmodload -F zsh/stat b:zstat

##### Env
export EDITOR="nvim" VISUAL="nvim" LESS="e M q R F X z -3"

##### Tool initializers
command -v rg >/dev/null && grep(){ command rg --hidden --smart-case "$@"; }
command -v fd >/dev/null && alias find="fd"
if command -v eza >/dev/null; then alias ls="eza" ll="eza -l" la="eza -la" tree="eza --tree --level=3"
else [[ "$OSTYPE" == darwin* ]] && alias ls="ls -G" tree="ls -R" || alias ls="ls --color=auto" tree="ls -R"
fi
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

##### Aliases (interactive only)
if [[ $- == *i* ]]; then
  alias rm='rm -i' cp='cp -i' mv='mv -i' l='ls' g='git' e='nvim' h='fc -ln 1' ta="tmux attach || tmux new"
  alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
  alias ..='cd ..' ...='cd ../..' ....='cd ../../..'
fi

##### Cross-platform clipboard
if [[ "$OSTYPE" == darwin* ]]; then
  pbcopy(){ (( $# )) && { local f; for f in "$@"; do command cat "$f"; done; } | command pbcopy || command pbcopy; }
  pbpaste(){ command pbpaste; }
else
  if command -v wl-copy &>/dev/null; then pbcopy(){ (( $# )) && cat -- "$@" | wl-copy || wl-copy; }; pbpaste(){ wl-paste; }
  elif command -v xclip &>/dev/null; then pbcopy(){ (( $# )) && cat -- "$@" | xclip -selection clipboard || xclip -selection clipboard; }; pbpaste(){ xclip -selection clipboard -o; }
  elif command -v xsel &>/dev/null; then pbcopy(){ (( $# )) && cat -- "$@" | xsel --clipboard --input || xsel --clipboard --input; }; pbpaste(){ xsel --clipboard --output; }
  else pbcopy(){ :; }; pbpaste(){ echo ""; }
  fi
fi
_paste_clip_after(){ LBUFFER+="$(pbpaste)"; }; _paste_clip_before(){ RBUFFER="$(pbpaste)$RBUFFER"; }
zle -N _paste_clip_after; zle -N _paste_clip_before
bindkey -M vicmd 'p' _paste_clip_after 'P' _paste_clip_before
bindkey -M viins '^V' _paste_clip_after

##### History & Options
HISTSIZE=10000 SAVEHIST=10000 HISTFILE=${HISTFILE:-$HOME/.zsh_history}
setopt APPEND_HISTORY SHARE_HISTORY INC_APPEND_HISTORY \
       HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS \
       HIST_IGNORE_SPACE HIST_REDUCE_BLANKS HIST_VERIFY \
       EXTENDED_HISTORY HIST_FIND_NO_DUPS HIST_SAVE_NO_DUPS \
       CORRECT MENUCOMPLETE AUTO_MENU LIST_PACKED \
       AUTOCD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_MINUS \
       INTERACTIVE_COMMENTS LONG_LIST_JOBS NO_BEEP GLOBDOTS \
       PROMPT_SUBST NO_FLOW_CONTROL PIPE_FAIL \
       NO_CLOBBER RM_STAR_WAIT \
       AUTO_PARAM_SLASH NO_CASE_GLOB NUMERIC_GLOBSORT \
       COMPLETE_ALIASES NOTIFY WARN_CREATE_GLOBAL

##### Vim mode & keybinds
bindkey -v
autoload -Uz up-line-or-search down-line-or-search history-beginning-search-menu
bindkey -M viins '^P' up-line-or-search '^N' down-line-or-search 'jk' vi-cmd-mode 'kj' vi-cmd-mode '^?' backward-delete-char '^H' backward-delete-char
bindkey -M vicmd '/' history-incremental-search-forward '?' history-incremental-search-backward 'R' history-beginning-search-menu
zle -N history-beginning-search-menu
_first_tab(){ [[ -z $BUFFER ]] && { BUFFER="cd "; CURSOR=${#BUFFER}; zle list-choices; } || zle expand-or-complete; }
zle -N _first_tab; bindkey -M viins '^I' _first_tab

##### RPROMPT for Vim mode
zle-keymap-select(){ local n="%K{yellow}${BOLD_WHITE} NOR %k${RESET_BOLD}" i="%K{green}${BOLD_WHITE} INS %k${RESET_BOLD}"; VIM_MODE=$([[ $KEYMAP == vicmd ]] && echo $n || echo $i); RPROMPT=$VIM_MODE; zle reset-prompt; }
zle -N zle-keymap-select; zle -N zle-line-init zle-keymap-select

##### Dir metrics (fast + cached)
typeset -g _dm_pwd="" _dm_size="" _dm_count=0; typeset -gi _dm_ts=0 _DM_TTL=3 _DM_MAX_ENTRIES=4000
_humanize_size(){ local -F 2 s=$1; local -a u=(B KB MB GB TB PB); local i=1; while (( s>=1024 && i<${#u} )); do s=$(( s/1024.0 )); ((i++)); done; printf '%.1f%s' $s $u[i]; }
_dir_metrics(){
  local now=$EPOCHSECONDS; [[ $_dm_pwd == "$PWD" && $((now-_dm_ts)) -lt _DM_TTL ]] && return
  local -a entries; entries=( *(DN) ); _dm_count=${#entries}
  if   (( _dm_count==0 )); then _dm_size="0B"
  elif (( _dm_count>_DM_MAX_ENTRIES )); then _dm_size="--"
  else local -A S; local -i bytes=0; local f; for f in *(.DN); do zstat -H S -- "$f" 2>/dev/null && (( bytes+=S[size] )); done; _dm_size=$(_humanize_size $bytes)
  fi
  _dm_pwd=$PWD; _dm_ts=$now
}
chpwd(){ _dm_ts=0; }  # invalidate on cd
_dir_info(){ _dir_metrics; print -r -- "${BOLD_CYAN}${_dm_count} | ${_dm_size}${RESET_BOLD}"; }
_shorten_path(){ local full="${1:-$PWD}" prefix=""; [[ "$full" == "$HOME"* ]] && prefix="~" full="${full/#$HOME/}"; local -a parts; IFS='/' read -rA parts <<< "${full#/}"; (( ${#parts}==0 )) && { print -r -- "${prefix}/"; return; }; (( ${#parts}>4 )) && print -r -- "${prefix}/${(j:/:)parts[1,2]}/.../${(j:/:)parts[-2,-1]}" || print -r -- "${prefix}/${(j:/:)parts}"; }
_update_prompt(){ local s=$1 d=$(_dir_info); PROMPT=" %K{blue} ${BOLD_WHITE}%D{%H:%M:%S}${RESET_BOLD} %k :: ${BOLD_MAGENTA}$(_shorten_path)${RESET_BOLD} :: ${d}
 $([[ $s -eq 0 ]] && echo "${BOLD_GREEN}>${RESET_BOLD}" || echo "${BOLD_RED}<${RESET_BOLD}") "; PS2="${BOLD_BLUE}>>${RESET_BOLD} "; }
_prompt_precmd(){ _update_prompt $?; }
setopt PROMPT_CR
autoload -Uz add-zsh-hook; add-zsh-hook precmd _prompt_precmd

##### Syntax highlighting (first word of each command)
_custom_highlight(){
  emulate -L zsh; setopt extended_glob
  region_highlight=(); local buffer="$BUFFER" remaining="$buffer" offset=0 found_command=0
  local -a words=(${(z)buffer}) delims=(";" "|" "||" "&&" "|&" "&" "(" ")" ";;&" ";|")
  for word in "${words[@]}"; do
    [[ -z "${word// }" ]] && continue
    local rel="${remaining%%${word}*}" idx=$((offset + ${#rel})) end=$((idx + ${#word})); offset=$end; remaining="${remaining#"$rel$word"}"
    if (( ${delims[(Ie)$word]} )); then found_command=0; continue; fi
    if (( ! found_command )); then
      if whence -w -- "$word" &>/dev/null; then region_highlight+=("$idx $end fg=green,bold"); else region_highlight+=("$idx $end fg=red,bold"); fi
      found_command=1
    fi
  done
}
_highlight_pre_redraw(){ emulate -L zsh; (( ${#BUFFER} > 4000 )) && { region_highlight=(); return; }; _custom_highlight; }
_highlight_finish(){ region_highlight=(); }
zle -N zle-line-pre-redraw _highlight_pre_redraw; zle -N zle-line-finish _highlight_finish

##### Autopair (interactive)
if [[ $- == *i* ]]; then
  : ${AP_MAX:=4000}
  _autopair(){
    (( ${#BUFFER} > AP_MAX )) && return
    local key="$1" close="$2" mode="$3" prev="${LBUFFER[-1]}" next="${RBUFFER[1]}"
    [[ $prev == '\' ]] && { LBUFFER+="$key"; return; }
    if [[ $prev == "$key" ]]; then LBUFFER+="$key"; [[ $next == "$close" ]] && RBUFFER="$close$RBUFFER"; return; fi
    if [[ -n $COMPSYS && ( $WIDGET == (menu-*) || $PENDING -gt 0 ) ]]; then LBUFFER+="$key"; return; fi
    if [[ $mode == always ]]; then LBUFFER+="$key$close"; zle backward-char; return; fi
    if [[ $mode == boundary ]]; then
      if [[ -z "$prev" || "$prev" == [[:space:][:punct:]] ]] && [[ -z "$next" || "$next" == [[:space:][:punct:]] ]]; then LBUFFER+="$key$close"; zle backward-char; return; fi
    fi
    LBUFFER+="$key"
  }
  _autopair_close(){ local close="$1"; [[ ${RBUFFER[1]} == "$close" ]] && zle forward-char || LBUFFER+="$close"; }
  _ap_backspace(){
    if [[ -n $LBUFFER && -n $RBUFFER ]]; then local l="${LBUFFER[-1]}" r="${RBUFFER[1]}"; case "$l$r" in "''"|\"\"|\(\)|\[\]|\{\}) LBUFFER=${LBUFFER[1,-2]}; RBUFFER=${RBUFFER[2,-1]}; return;; esac; fi
    zle backward-delete-char
  }
  _ap_apos(){ _autopair "'" "'" boundary }; _ap_quot(){ _autopair '"' '"' boundary }
  _ap_open-paren(){ _autopair "(" ")" boundary }; _ap_close-paren(){ _autopair_close ")" }
  _ap_open-brack(){ _autopair "[" "]" boundary }; _ap_close-brack(){ _autopair_close "]" }
  _ap_open-brace(){ _autopair "{" "}" boundary }; _ap_close-brace(){ _autopair_close "}" }
  zle -N _ap_apos; zle -N _ap_quot; zle -N _ap_open-paren; zle -N _ap_close-paren; zle -N _ap_open-brack; zle -N _ap_close-brack; zle -N _ap_open-brace; zle -N _ap_close-brace; zle -N _ap_backspace
  bindkey -M viins "'" _ap_apos '"' _ap_quot '(' _ap_open-paren ')' _ap_close-paren '[' _ap_open-brack ']' _ap_close-brack '{' _ap_open-brace '}' _ap_close-brace '^?' _ap_backspace '^H' _ap_backspace
fi

##### Interactive completion (fast + cached)
if [[ $- == *i* ]]; then
  autoload -Uz compinit compaudit; compaudit | while read -r p; do chmod g-w,o-w "$p" 2>/dev/null || true; done
  zmodload zsh/complist
  typeset -g _compdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compdump" _compcache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compcache"
  mkdir -p -- "$_compcache" "${_compdump:h}"
  compinit -C -d "$_compdump"
  zstyle ':completion:*' use-cache on; zstyle ':completion:*' cache-path "$_compcache"
  zstyle ':completion:*' menu select; zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*'
  zstyle ':completion:*' group-name ''; zstyle ':completion:*' list-colors ''; zstyle ':completion:*:history-words' menu yes select; zstyle ':completion:*:history-words' list-colors ''
  zstyle ':completion:*' rehash true
  export PROMPT_EOL_MARK=""
fi

##### PATH
[[ -d "$HOME/miniforge/bin" ]] && PATH="$HOME/miniforge/bin:$PATH"
[[ -d "/opt/homebrew/bin" ]]   && PATH="/opt/homebrew/bin:$PATH"
export PATH
