# ~/.zshrc
[[ -o interactive ]] || return
##### Modules
zmodload zsh/zle

##### General environment
if (( $+commands[nvim] )); then
  export EDITOR=nvim
  alias vi=nvim vim=nvim
elif (( $+commands[vim] )); then export EDITOR=vim
else export EDITOR=vi
fi
export VISUAL="$EDITOR"
export LESS='-iMQRFX'

##### Tunables
typeset -gi ZSH_HL_MAX_LEN=${ZSH_HL_MAX_LEN:-1000}
typeset -gi ZSH_AP_MAX_LEN=${ZSH_AP_MAX_LEN:-4000}

##### Path
typeset -Ug path fpath manpath
[[ -d "/opt/homebrew/bin" ]] && path=(/opt/homebrew/bin $path)
for d in /opt/homebrew/opt/*/libexec/gnubin(N/); do
  path=("$d" $path)
done
for d in /opt/homebrew/opt/*/libexec/gnuman(N/); do
  manpath=("$d" $manpath)
done
[[ -d "$HOME/miniforge/bin" ]] && path=($HOME/miniforge/bin $path)

##### Tool initializers
if command -v eza >/dev/null; then
  alias ls="eza"
  alias ll="eza -l"
  alias la="eza -la"
  alias tree="eza --tree --level=3"
else
  if [[ "$OSTYPE" == darwin* ]]; then
    alias ls="ls -G"
  else
    alias ls="ls --color=auto"
  fi
fi

if [[ $- == *i* ]] && command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh)"
fi

##### Aliases for interactive shell
if [[ $- == *i* ]]; then
  alias rm='rm -i'
  alias cp='cp -i'
  alias mv='mv -i'
  alias l='ls'
  alias e='$EDITOR'
  alias h='fc -ln 1'
  alias ta='tmux attach || tmux new'
  alias config='command git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
fi

##### Minimal safe git aliases
alias g='git'
alias gs='git status -sb'
alias gd='git diff'
alias gds='git diff --staged'
alias ga='git add -p'
alias gc='git commit'
alias gp='git push'
alias gf='git fetch --prune'
alias gb='git branch --show-current'
alias gl='git log --oneline --decorate --graph --max-count=15'
gxi() (
  set -o pipefail
  cd "$(git rev-parse --show-toplevel)" || return
  git ls-files -ci --exclude-standard -z |
    xargs -0 sh -c '
      [ "$#" -eq 0 ] || git --literal-pathspecs rm --cached -- "$@"
    ' sh
)

##### Cross-platform clipboard
typeset -ga _clip_copy_cmd=()
typeset -ga _clip_paste_cmd=()
typeset -g _clip_backend=""

if [[ $OSTYPE == darwin* ]] \
  && (( $+commands[pbcopy] && $+commands[pbpaste] ))
then
  _clip_copy_cmd=(pbcopy)
  _clip_paste_cmd=(pbpaste)
  _clip_backend="macOS"

elif [[ -n ${WAYLAND_DISPLAY:-} ]] \
  && (( $+commands[wl-copy] && $+commands[wl-paste] ))
then
  _clip_copy_cmd=(wl-copy)
  _clip_paste_cmd=(wl-paste)
  _clip_backend="Wayland"

elif [[ -n ${DISPLAY:-} ]] && (( $+commands[xclip] )); then
  _clip_copy_cmd=(xclip -selection clipboard)
  _clip_paste_cmd=(xclip -selection clipboard -o)
  _clip_backend="X11/xclip"

elif [[ -n ${DISPLAY:-} ]] && (( $+commands[xsel] )); then
  _clip_copy_cmd=(xsel --clipboard --input)
  _clip_paste_cmd=(xsel --clipboard --output)
  _clip_backend="X11/xsel"
fi

_clip_available() {
  (( ${#_clip_copy_cmd} && ${#_clip_paste_cmd} ))
}

# Public clipboard command:
#
#   print -n "hello" | copy
#   copy README.md
#
clipcopy() {
  if ! _clip_available; then
    print -u2 -- "copy: no supported clipboard backend available"
    return 127
  fi

  if (( $# )); then
    command cat -- "$@" | command "${_clip_copy_cmd[@]}"
  else
    command "${_clip_copy_cmd[@]}"
  fi
}

if [[ $- == *i* ]]; then
  alias copy='clipcopy'
fi

# Shared result from _clip_read.
typeset -g _clip_text=""

# Internal clipboard reader used by ZLE widgets.
# The marker preserves trailing newlines through command substitution.
_clip_read() {
  local marker=$'\x1f'
  local output rc

  if ! _clip_available; then
    return 127
  fi

  output="$(
    command "${_clip_paste_cmd[@]}" 2>/dev/null
    rc=$?
    print -rn -- "$marker"
    exit "$rc"
  )" || return 1

  _clip_text="${output%$marker}"
}

##### Clipboard ZLE widgets
if [[ $- == *i* ]] && _clip_available; then
  _paste_clip_here() {
    if ! _clip_read; then
      zle -M "Clipboard read failed"
      return 1
    fi

    LBUFFER+="$_clip_text"
  }

  # Vi p: paste after the character under the cursor.
  _paste_clip_after() {
    if ! _clip_read; then
      zle -M "Clipboard read failed"
      return 1
    fi

    [[ -n $_clip_text ]] || return 0

    if [[ -n $RBUFFER ]]; then
      LBUFFER+="${RBUFFER[1]}"
      RBUFFER="${RBUFFER[2,-1]}"
    fi

    LBUFFER+="$_clip_text"
    zle backward-char
  }

  # Vi P: paste before the character under the cursor.
  _paste_clip_before() {
    if ! _clip_read; then
      zle -M "Clipboard read failed"
      return 1
    fi

    [[ -n $_clip_text ]] || return 0

    LBUFFER+="$_clip_text"
    zle backward-char
  }

  zle -N _paste_clip_here
  zle -N _paste_clip_after
  zle -N _paste_clip_before

  bindkey -M vicmd 'p' _paste_clip_after
  bindkey -M vicmd 'P' _paste_clip_before
  bindkey -M viins '^V' _paste_clip_here
fi

##### Tiny helpers
mkcd() {
  [[ -n $1 ]] || return 1
  mkdir -p -- "$1" && cd -- "$1"
}

extract() {
  [[ -f $1 ]] || { echo "Not a file: $1"; return 1; }
  case "$1" in
    *.tar.bz2) tar xjf "$1" ;;
    *.tar.gz)  tar xzf "$1" ;;
    *.zip)     unzip -q "$1" ;;
    *.tar.xz)  tar xJf "$1" ;;
    *.rar)     unrar x -idq "$1" ;;
    *) echo "Unknown archive"; return 1 ;;
  esac
}

watch() {
  emulate -L zsh
  setopt pipefail

  local interval=2
  local show_title=1

  while (( $# )); do
    case "$1" in
      -n|--interval)
        [[ -n ${2:-} ]] || {
          print -u2 "watch: missing interval"
          return 2
        }
        interval="$2"
        if [[ $interval != <-> && $interval != <->.<-> ]] ||
          (( interval <= 0 )); then
          print -u2 -- "watch: interval must be a positive number"
          return 2
        fi
        shift 2
        ;;
      -t|--no-title)
        show_title=0
        shift
        ;;
      --)
        shift
        break
        ;;
      -*)
        print -u2 "watch: unknown option: $1"
        return 2
        ;;
      *)
        break
        ;;
    esac
  done

  (( $# )) || {
    print -u2 "usage: watch [-n seconds] [-t] command"
    return 2
  }

  local cmd
  if (( $# == 1 )); then
    cmd=$1
  else
    cmd="${(j: :)${(q)@}}"
  fi
  local rc=0

  while true; do
    printf '\033[H\033[2J'

    if (( show_title )); then
      print -P \
        "%Bwatch%b  %F{cyan}${interval}s%f  %F{yellow}%D{%Y-%m-%d %H:%M:%S}%f  %F{magenta}${HOST}%f"
      print -P "%F{blue}${(l:$COLUMNS::-:)}%f"
    fi

    (
      eval -- "$cmd"
    )
    rc=$?

    if (( show_title )); then
      print

      if (( rc == 0 )); then
        print -P "%F{green}exit: ${rc}%f"
      else
        print -P "%F{red}exit: ${rc}%f"
      fi
    fi

    sleep "$interval"
  done
}

##### History & Shell options
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=${HISTFILE:-$HOME/.zsh_history}
setopt SHARE_HISTORY HIST_FCNTL_LOCK
setopt HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS HIST_SAVE_NO_DUPS
setopt HIST_IGNORE_SPACE HIST_REDUCE_BLANKS HIST_NO_STORE
setopt HIST_VERIFY

##### Completion
setopt MENU_COMPLETE LIST_PACKED ALWAYS_TO_END

##### Navigation
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_MINUS
alias ..='cd ..' ...='cd ../..' ....='cd ../../..' .....='cd ../../../..'

##### Shell behavior
setopt INTERACTIVE_COMMENTS NO_FLOW_CONTROL
setopt PIPE_FAIL WARN_CREATE_GLOBAL

##### Job control
setopt LONG_LIST_JOBS NOTIFY

##### Safety
setopt NO_CLOBBER RM_STAR_WAIT NO_BEEP

##### Vim mode & Keybinds
bindkey -v
KEYTIMEOUT=25

autoload -Uz up-line-or-search down-line-or-search
bindkey -M viins '^P' up-line-or-search
bindkey -M viins '^N' down-line-or-search
bindkey -M viins '^[[A' history-beginning-search-backward
bindkey -M viins '^[[B' history-beginning-search-forward
bindkey -M viins '^[OA' history-beginning-search-backward
bindkey -M viins '^[OB' history-beginning-search-forward
bindkey -M vicmd '/' history-incremental-search-forward
bindkey -M vicmd '?' history-incremental-search-backward
bindkey -M viins 'jk' vi-cmd-mode
bindkey -M viins $'\x7f' backward-delete-char
bindkey -M viins $'\x08' backward-delete-char

autoload -Uz history-beginning-search-menu
zle -N history-beginning-search-menu
bindkey -M vicmd 'R' history-beginning-search-menu

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

##### Prompt: bounded directory statistics, no Git lookup.
typeset -gi LAST_STATUS=0 _dir_time=0
typeset -g VIM_MODE=INS _exit_status='' _dir_path='' _dir_info='≡ ? · □ ? · ?'
zmodload -F zsh/stat b:zstat 2>/dev/null || :

_directory_info() {
  emulate -L zsh
  [[ $_dir_path == "$PWD" ]] && (( SECONDS - _dir_time >= 0 && SECONDS - _dir_time < 30 )) && return 0
  local -a entries
  local -A file_info
  local entry size='?' suffix='' label=B
  local -i files=0 dirs=0 bytes=0 unit=1 valid=1 seen=0
  _dir_path=$PWD
  _dir_info='≡ ? · □ ? · ?'
  if [[ -r . && -x . ]]; then
    # Y513 short-circuits glob traversal, including hidden entries; the extra
    # entry distinguishes complete results from a truncated sample.
    entries=(./*(NDY513))
    if (( ${#entries} > 512 )); then
      suffix=' …'
    fi
    for entry in "${entries[@]}"; do
      (( seen >= 512 )) && break
      (( seen += 1 ))
      if [[ -L $entry ]]; then continue
      elif [[ -d $entry ]]; then (( dirs += 1 ))
      elif [[ -f $entry ]]; then
        (( files += 1 ))
        if (( $+builtins[zstat] )) && zstat -H file_info -- "$entry" 2>/dev/null; then
          (( bytes += file_info[size] ))
          (( bytes >= 0 )) || valid=0
        else valid=0; fi
      fi
    done
    if (( valid )); then
      for label in B KiB MiB GiB TiB; do
        (( bytes / unit < 1024 )) && break
        [[ $label == TiB ]] && break
        (( unit *= 1024 ))
      done
      if (( unit == 1 )); then size="$bytes B"
      else printf -v size '%d.%d %s' "$((bytes / unit))" "$(((bytes % unit) * 10 / unit))" "$label"; fi
    fi
    _dir_info="≡ $files · □ $dirs · $size$suffix"
  fi
  _dir_time=$SECONDS
}

# The (m) length flag counts terminal cells rather than code points.
_fit_text() {
  emulate -L zsh
  local value=$1 style=${3:-middle} piece
  local -i budget=$2 n left right
  REPLY=$value
  (( ${(m)#value} > budget )) || return 0
  REPLY=''
  (( budget > 0 )) || return 0
  REPLY='…'
  n=$((budget-1)); (( n < ${#value} )) || n=$(( ${#value}-1 ))
  while (( n > 0 )); do
    if [[ $style == end ]]; then piece="${value[1,n]}…"
    else
      left=$(((n+1)/2))
      if [[ $style == path && $n -gt 2 ]]; then left=$((n*2/5)); fi
      right=$((n-left))
      piece="${value[1,left]}…"
      (( right )) && piece+=${value[-right,-1]}
    fi
    if (( ${(m)#piece} <= budget )); then REPLY=$piece; return 0; fi
    (( n-- ))
  done
  return 0
}

typeset -gi _prompt_width=0
_update_prompt() {
  emulate -L zsh
  local mode_color=green mode_symbol=● host=${(%):-%m} value=${(%):-%~}
  local display stats meta mode_label
  local -i width=${COLUMNS:-80} budget path_cells meta_cells
  local REPLY
  case $VIM_MODE in
    NOR) mode_color=yellow; mode_symbol=■ ;;
    VIS) mode_color=magenta; mode_symbol=▶ ;;
  esac
  host=${host//[[:cntrl:]]/?}
  value=${value//[[:cntrl:]]/?}
  _prompt_width=$width
  PS2='%B%F{blue}┃%f%b   '
  if [[ ${TERM:-dumb} == dumb ]] || (( width < 20 )); then
    PROMPT="%# "
    return 0
  fi
  _fit_text "$host" "$((width-16-${(m)#_exit_status}))"; host=$REPLY
  meta='%D{%H:%M:%S}'
  meta_cells=8
  if [[ -n $host ]]; then
    meta="${host//\%/%%} · $meta"
    (( meta_cells += ${(m)#host} + 3 ))
  fi
  mode_label="%F{${mode_color}}$mode_symbol $VIM_MODE%f"
  PROMPT="%B%F{blue}┏━━┫ %f%b${mode_label}%B%F{blue} ┣━━%f%b"
  if (( 15 + meta_cells + ${(m)#_exit_status} < width )); then
    PROMPT+=" $meta%F{red}${_exit_status}%f"$'\n'
  else
    PROMPT+=$'\n'"%B%F{blue}┣━━ %f%b$meta%F{red}${_exit_status}%f"$'\n'
  fi
  budget=$((width-5)); (( budget > 40 )) && budget=40
  _fit_text "$value" "$budget" path
  path_cells=${(m)#REPLY}; display=${REPLY//\%/%%}
  PROMPT+="%B%F{blue}┣━━ %f%b%F{cyan}$display%f"
  if (( 4 + path_cells + 4 + ${(m)#_dir_info} < width )); then
    PROMPT+="%B%F{blue} ━━ %f%b${_dir_info}"$'\n'
  else
    _fit_text "$_dir_info" "$((width-5))" end; stats=$REPLY
    PROMPT+=$'\n'"%B%F{blue}┣━━ %f%b$stats"$'\n'
  fi
  PROMPT+="%B%F{blue}┗━━%f%b%F{${mode_color}}❯%f "
}

_sync_vi_mode() {
  local mode=INS
  if (( REGION_ACTIVE )); then mode=VIS
  elif [[ $KEYMAP == vicmd || $KEYMAP == viopp ]]; then mode=NOR; fi
  [[ $mode == $VIM_MODE && ${COLUMNS:-80} == $_prompt_width ]] && return 0
  VIM_MODE=$mode
  _update_prompt
  zle reset-prompt
}
zle-keymap-select() { _sync_vi_mode; }
zle-line-init() { _sync_vi_mode; }
zle -N zle-keymap-select
zle -N zle-line-init
_prompt_precmd() {
  LAST_STATUS=$?
  _exit_status=''
  (( LAST_STATUS )) && _exit_status=" ✗ $LAST_STATUS"
  _directory_info
  _update_prompt
}
setopt PROMPT_PERCENT PROMPT_CR
unsetopt PROMPT_SUBST
autoload -Uz add-zsh-hook
add-zsh-hook precmd _prompt_precmd

##### Syntax highlighting
typeset -ga region_highlight

_custom_highlight() {
  emulate -L zsh
  setopt localoptions noksharrays extendedglob

  region_highlight=()

  local buffer="$BUFFER"
  (( ${#buffer} > ZSH_HL_MAX_LEN )) && return

  local pos=0 idx_start idx_end word check_word tail
  local found_command=0
  local -a words
  local -a delimiters=(";" "|" "||" "&&" "|&" "&" ";;" ";&" ";|")
  local -a redirects=("<" ">" ">>" "<<" "<<<" "<>" ">|" "2>" "2>>" "&>" "&>>" "1>" "1>>" "1>&2" "2>&1")
  local -a reserved=(
    if then else elif fi do done case esac while until for repeat select
    time function coproc foreach nocorrect declare export integer local
    readonly typeset '!' in
  )
  local -a starts_cmd_after=(then do elif else time '!' fi done esac)

  local expect_for_var=0
  local in_for_list=0
  local expect_func_name=0
  local in_test=0
  local in_arith=0
  local expect_redir_target=0

  # Quote the ${(z)...} result so literal globs such as "*" stay literal
  # instead of being eligible for another round of shell expansion.
  words=("${(z)buffer}")

  for word in "${words[@]}"; do
    [[ -z $word ]] && continue

    # ${(z)} preserves the shell token text. Walk forward through BUFFER
    # and skip only the whitespace before the next token. This avoids the
    # old pattern-search bug with *, ?, $(...), brackets, and friends.
    tail="${buffer[$((pos + 1)),-1]}"
    (( pos += ${#tail} - ${#${tail##[[:space:]]#}} ))

    idx_start=$pos
    idx_end=$((idx_start + ${#word}))
    pos=$idx_end

    if [[ $word == '[[' ]]; then
      region_highlight+=("$idx_start $idx_end fg=yellow,bold")
      in_test=1
      found_command=0
      continue
    fi

    if (( in_test )) && [[ $word == ']]' ]]; then
      region_highlight+=("$idx_start $idx_end fg=yellow,bold")
      in_test=0
      found_command=0
      continue
    fi

    if [[ $word == \(\(* && $word == *\)\) && ${#word} -ge 4 ]]; then
      region_highlight+=("$idx_start $((idx_start + 2)) fg=yellow,bold")
      region_highlight+=("$((idx_end - 2)) $idx_end fg=yellow,bold")
      if (( idx_end - idx_start > 4 )); then
        region_highlight+=("$((idx_start + 2)) $((idx_end - 2)) fg=white")
      fi
      found_command=0
      continue
    fi

    if [[ $word == \(\(* ]]; then
      region_highlight+=("$idx_start $((idx_start + 2)) fg=yellow,bold")
      in_arith=1
      found_command=0
      if (( idx_end - idx_start > 2 )); then
        region_highlight+=("$((idx_start + 2)) $idx_end fg=white")
      fi
      continue
    fi

    if (( in_arith )) && [[ $word == *\)\) ]]; then
      if (( idx_end - idx_start > 2 )); then
        region_highlight+=("$idx_start $((idx_end - 2)) fg=white")
      fi
      region_highlight+=("$((idx_end - 2)) $idx_end fg=yellow,bold")
      in_arith=0
      found_command=0
      continue
    fi

    if [[ $word == '((' || $word == '(((' ]]; then
      region_highlight+=("$idx_start $idx_end fg=yellow,bold")
      in_arith=1
      found_command=0
      continue
    fi

    if (( in_arith )) && [[ $word == '))' ]]; then
      region_highlight+=("$idx_start $idx_end fg=yellow,bold")
      in_arith=0
      found_command=0
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
      expect_redir_target=0
      continue
    fi

    if [[ " ${redirects[*]} " == *" $word "* ]]; then
      region_highlight+=("$idx_start $idx_end fg=yellow,bold")
      expect_redir_target=1
      continue
    fi

    if (( expect_redir_target )); then
      region_highlight+=("$idx_start $idx_end fg=magenta")
      expect_redir_target=0
      continue
    fi

    if [[ " ${reserved[*]} " == *" $word "* ]]; then
      region_highlight+=("$idx_start $idx_end fg=yellow,bold")

      case $word in
        for)      expect_for_var=1; found_command=0 ;;
        in)       in_for_list=1; found_command=0 ;;
        do)       in_for_list=0; found_command=0 ;;
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
      # Keep loop values readable. Highlight command substitution as a
      # distinct shell expression rather than letting it confuse positions.
      if [[ $word == '$('*')' ]]; then
        region_highlight+=("$idx_start $idx_end fg=cyan")
      elif [[ $word == *[\*\?\[]* ]]; then
        region_highlight+=("$idx_start $idx_end fg=magenta")
      else
        region_highlight+=("$idx_start $idx_end fg=white")
      fi
      continue
    fi

    if (( found_command == 0 )) &&
       [[ $word == [A-Za-z_][A-Za-z0-9_]#=* ]]; then
      region_highlight+=("$idx_start $idx_end fg=blue")
      continue
    fi

    if [[ $word == '$'* || $word == '${'* ]]; then
      region_highlight+=("$idx_start $idx_end fg=blue")
      continue
    fi

    if [[ $word == '(' || $word == ')' || $word == '{' || $word == '}' || $word == '[' || $word == ']' ]]; then
      region_highlight+=("$idx_start $idx_end fg=white")
      found_command=0
      continue
    fi

    # Use the unquoted shell word for command lookup.
    check_word="${(Q)word}"

    if (( found_command == 0 )); then
      if whence -w -- "$check_word" &>/dev/null; then
        region_highlight+=("$idx_start $idx_end fg=green,bold")
      else
        region_highlight+=("$idx_start $idx_end fg=red,bold")
      fi
      found_command=1
    fi
  done
}

autoload -Uz add-zle-hook-widget

##### Autopair
if [[ $- == *i* ]]; then
  _ap_is_word()     { [[ -n $1 && $1 == [[:alnum:]_] ]]; }
  _ap_is_closer()   { [[ -n $1 && $1 == [\)\]\}] ]]; }
  _ap_is_hardstop() { [[ -n $1 && $1 == [\\.=] ]]; }
  _ap_is_boundary() { [[ -z $1 || $1 == [[:space:][:punct:]] ]]; }
  _ap_is_pathstart(){ [[ -n $1 && $1 == [/~] ]]; }

  _autopair_open() {
    (( ${#BUFFER} > ZSH_AP_MAX_LEN )) && { LBUFFER+="$1"; return; }

    local key="$1" close="$2" mode="${3:-boundary}"
    local prev="${LBUFFER[-1]-}" next="${RBUFFER[1]-}"

    if [[ $prev == \\ || ( -n "$COMPSYS" && ( $WIDGET == menu-* || $PENDING -gt 0 ) ) ]]; then
      LBUFFER+="$key"
      return
    fi

    if [[ $next == "$key" ]]; then
      zle forward-char
      return
    fi

    if [[ $key == \' || $key == \" ]]; then
      if [[ $prev == "=" ]]; then
        if _ap_is_boundary "$next"; then
          LBUFFER+="$key$close"
          zle backward-char
          return
        else
          LBUFFER+="$key"
          return
        fi
      fi

      if _ap_is_word "$next" || _ap_is_word "$prev" || _ap_is_closer "$prev"; then
        LBUFFER+="$key"
        return
      fi
    fi

    if _ap_is_hardstop "$prev"; then
      LBUFFER+="$key"
      return
    fi

    if _ap_is_pathstart "$next"; then
      LBUFFER+="$key"
      return
    fi

    if [[ $mode == always ]]; then
      LBUFFER+="$key$close"
      zle backward-char
      return
    fi

    if [[ $mode == boundary ]]; then
      if ! _ap_is_closer "$prev"; then
        if _ap_is_boundary "$prev" && _ap_is_boundary "$next"; then
          LBUFFER+="$key$close"
          zle backward-char
          return
        fi
      fi
    fi

    LBUFFER+="$key"
  }

  _autopair_backspace() {
    if [[ -n $LBUFFER && -n $RBUFFER ]]; then
      local l="${LBUFFER[-1]}" r="${RBUFFER[1]}"
      case "$l$r" in
        "''"|'""')
          LBUFFER=${LBUFFER[1,-2]}
          RBUFFER=${RBUFFER[2,-1]}
          return
          ;;
      esac
    fi

    zle backward-delete-char
  }

  _ap_apos() { _autopair_open $'\'' $'\'' boundary; }
  _ap_quot() { _autopair_open $'"'  $'"'  boundary; }

  zle -N _ap_apos
  zle -N _ap_quot
  zle -N _autopair_backspace

  bindkey -M viins "'"  _ap_apos
  bindkey -M viins '"'  _ap_quot
  bindkey -M viins $'\x7f' _autopair_backspace
  bindkey -M viins $'\x08' _autopair_backspace
fi

##### Interactive-only setup
if [[ $- == *i* ]]; then
  autoload -Uz compinit compaudit
  zmodload zsh/complist

  typeset -gi _completion_insecure=0
  [[ -n $(compaudit 2>/dev/null) ]] && _completion_insecure=1

  typeset -g _compdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compdump"
  typeset -g _compcache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compcache"
  mkdir -p -- "$_compcache" "${_compdump:h}"

  compinit -i -d "$_compdump"

  zstyle ':completion:*' use-cache on
  zstyle ':completion:*' cache-path "$_compcache"
  zstyle ':completion:*' menu select
  zstyle ':completion:*' matcher-list \
    '' 'm:{a-zA-Z}={A-Za-z}' \
    'r:|[._-]=* r:|=*'
  zstyle ':completion:*' group-name ''
  zstyle ':completion:*' list-colors ''
  zstyle ':completion:*:history-words' menu yes select
  zstyle ':completion:*:history-words' list-colors ''
  zstyle ':completion:*' rehash true

  export PROMPT_EOL_MARK=""

  if (( _completion_insecure )); then
    print -P "%F{yellow}warning:%f insecure completion dirs detected"
  fi
fi

# Native history suggestion: show a matching command without inserting it.
zmodload zsh/parameter
_suggest() {
  POSTDISPLAY=''
  [[ ( $KEYMAP == viins || $KEYMAP == main ) && -n $BUFFER && $CURSOR == ${#BUFFER} && $BUFFER != *$'\n'* ]] || return 0
  local item
  local -i event floor
  floor=$(( HISTCMD > 200 ? HISTCMD - 200 : 1 ))
  for (( event=HISTCMD-1; event>=floor; --event )); do
    item=${history[$event]-}
    if [[ $item == "$BUFFER"* && $item != "$BUFFER" && $item != *$'\n'* ]]; then
      POSTDISPLAY=${item[${#BUFFER}+1,-1]}
      break
    fi
  done
  if [[ -n $POSTDISPLAY ]]; then
    region_highlight+=("${#BUFFER} $((${#BUFFER}+${#POSTDISPLAY})) fg=8")
  fi
}
_accept() {
  if [[ -n $POSTDISPLAY && $CURSOR == ${#BUFFER} ]]; then
    BUFFER+=$POSTDISPLAY; CURSOR=${#BUFFER}; POSTDISPLAY=''
  else zle forward-char; fi
}
zle -N _accept
bindkey -M viins '^[[C' _accept
bindkey -M viins '^[OC' _accept
# Recompute highlighting before adding the hint to avoid accumulating regions.
typeset -ga _base_highlight=()
typeset -g _last_buffer=''
typeset -gi _highlight_valid=0
_redraw() {
  _sync_vi_mode
  if (( _highlight_valid )) && [[ $BUFFER == "$_last_buffer" ]]; then
    region_highlight=("${_base_highlight[@]}")
  else
    _custom_highlight
    _base_highlight=("${region_highlight[@]}")
    _last_buffer=$BUFFER
    _highlight_valid=1
  fi
  _suggest
}
_finish() { POSTDISPLAY=''; region_highlight=(); _highlight_valid=0; }
add-zle-hook-widget line-pre-redraw _redraw
add-zle-hook-widget line-finish _finish

paste() { _clip_available && command "${_clip_paste_cmd[@]}"; }
path_entries() { print -rl -- "${path[@]}"; }
ports() {
  if (( $+commands[ss] )); then ss -lntup
  elif (( $+commands[lsof] )); then lsof -nP -iTCP -sTCP:LISTEN
  else print -u2 'ports: ss or lsof required'; return 127; fi
}
ff() {
  local root=${1:-.} file
  if (( $+commands[fzf] )); then
    if (( $+commands[fd] )); then file=$(fd -t f . "$root" | fzf) || return
    else file=$(find "$root" -type f -print | fzf) || return; fi
    [[ -n $file ]] && "$EDITOR" -- "$file"
  else find "$root" -type f; fi
}
if (( $+commands[fzf] )); then
  _fzf_init=$(fzf --zsh 2>/dev/null) && eval "$_fzf_init"
  unset _fzf_init
fi

# Arrowless Insert-mode editing (and separate completion-menu navigation).
bindkey -M viins '^F' _accept
bindkey -M viins '^B' backward-char
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^P' up-line-or-search
bindkey -M viins '^N' down-line-or-search
bindkey -M viins '^R' history-incremental-search-backward
bindkey -M viins '^@' expand-or-complete
bindkey -M viins '^[[Z' reverse-menu-complete
# zsh/complist supplies the menuselect keymap.
if bindkey -M menuselect >/dev/null 2>&1; then
  bindkey -M menuselect '^P' reverse-menu-complete
  bindkey -M menuselect '^N' menu-complete
  bindkey -M menuselect '^B' backward-char
  bindkey -M menuselect '^F' forward-char
  bindkey -M menuselect '^I' menu-complete
  bindkey -M menuselect '^[[Z' reverse-menu-complete
fi
