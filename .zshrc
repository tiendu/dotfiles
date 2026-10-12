# ~/.zshrc
##### Modules
zmodload zsh/zle

##### General environment
export EDITOR="nvim"
export VISUAL="nvim"
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
  alias e='nvim'
  alias h='fc -ln 1'
  alias ta='tmux attach || tmux new'
  alias config='command git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
  alias ..='cd ..'
  alias ...='cd ../..'
  alias ....='cd ../../..'
fi

##### Minimal safe git aliases
alias g='git'
alias gs='git status -sb'
alias gb='git branch --show-current'
alias gl='git log --oneline --decorate --graph --max-count=15'
alias gf='git fetch --prune'
alias ga='git add -p'
alias gr='git restore'
alias gp='git push'

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

##### Shell behavior
setopt INTERACTIVE_COMMENTS NO_FLOW_CONTROL
setopt PIPE_FAIL WARN_CREATE_GLOBAL

##### Job control
setopt LONG_LIST_JOBS NOTIFY

##### Safety
setopt NO_CLOBBER RM_STAR_WAIT NO_BEEP

##### Vim mode & Keybinds
bindkey -v
KEYTIMEOUT=15

autoload -Uz up-line-or-search down-line-or-search
bindkey -M viins '^P' up-line-or-search
bindkey -M viins '^N' down-line-or-search
bindkey -M vicmd '/' history-incremental-search-forward
bindkey -M vicmd '?' history-incremental-search-backward
bindkey -M viins 'jk' vi-cmd-mode
bindkey -M viins 'kj' vi-cmd-mode
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

zmodload -F zsh/stat b:zstat

typeset -gi LAST_STATUS=0
typeset -g VIM_MODE="INS"
typeset -g _prompt_dir_info="0 | 0 B"
typeset -g _prompt_path=""

##### Prompt
# Keep mode as plain data; style it only when building PROMPT.
_sync_vi_mode() {
  local mode=INS
  if (( REGION_ACTIVE )); then
    mode=VIS
  elif [[ $KEYMAP == vicmd || $KEYMAP == viopp ]]; then
    mode=NOR
  fi

  [[ $mode == $VIM_MODE ]] && return 0
  VIM_MODE=$mode
  _update_prompt "$LAST_STATUS"
  zle reset-prompt
}

zle-keymap-select() { _sync_vi_mode; }
zle -N zle-keymap-select
zle -N zle-line-init zle-keymap-select

# Compress names independently; preserve every path level when possible.
# 12/20 are maximum component widths, not fixed path-length limits.
typeset -gi ZSH_PATH_PARENT_MAX=${ZSH_PATH_PARENT_MAX:-12}
typeset -gi ZSH_PATH_LEAF_MAX=${ZSH_PATH_LEAF_MAX:-20}

_shorten_path() {
  emulate -L zsh

  local full=${1:-$PWD} prefix='' component
  local -a parts caps=() compact=()
  local -i budget=${2:-0}
  local -i n i length cap left right total stage floor best pick

  # Never compress the home marker or filesystem root.
  if [[ $full == "$HOME" ]]; then
    REPLY='~'
    return
  elif [[ $full == "$HOME/"* ]]; then
    prefix='~/'
    full=${full#"$HOME/"}
  elif [[ $full == /* ]]; then
    prefix='/'
    full=${full#/}
  fi

  [[ -n $full ]] || { REPLY=${prefix:-.}; return; }
  parts=("${(@s:/:)full}")
  n=${#parts}
  total=$(( ${#prefix} + n - 1 ))  # Slashes are never removed.

  # Initial limits: parents <= 12, leaf <= 20 (by default).
  for (( i = 1; i <= n; ++i )); do
    length=${#parts[i]}
    if (( i == n )); then
      cap=$ZSH_PATH_LEAF_MAX
    else
      cap=$ZSH_PATH_PARENT_MAX
    fi
    (( cap < 3 )) && cap=3
    (( cap > length )) && cap=$length
    caps[i]=$cap
    (( total += cap ))
  done

  # Narrow panes: progressively reduce components before losing any levels.
  # Keep the leaf more legible than parents, and favor nearby context.
  if (( budget > 0 && total > budget )); then
    for stage in 1 2 3 4 5; do
      while (( total > budget )); do
        pick=0
        if (( stage == 2 || stage == 4 )); then
          # Leaf: first to 12, and only later to 8 characters.
          if (( stage == 2 )); then floor=12; else floor=8; fi
          (( caps[n] > floor )) && pick=$n
        else
          # Parents: 12 -> 5 -> 3 -> 1, longest first.
          case $stage in
            1) floor=5 ;;
            3) floor=3 ;;
            5) floor=1 ;;
          esac
          best=0
          for (( i = 1; i < n; ++i )); do
            if (( caps[i] > floor && caps[i] > best )); then
              best=${caps[i]}
              pick=$i
            fi
          done
        fi
        (( pick )) || break
        (( caps[pick]--, total-- ))
      done
      (( total <= budget )) && break
    done
  fi

  # Always keep every slash. For shortened components, preserve both ends
  # whenever the width allows; one-cell parents keep their initial.
  for (( i = 1; i <= n; ++i )); do
    component=${parts[i]}
    length=${#component}
    cap=${caps[i]}
    if (( length > cap )); then
      if (( cap == 1 )); then
        component=${component[1]}
      elif (( cap == 2 )); then
        component="${component[1]}…"
      else
        left=$(( cap / 2 ))
        right=$(( cap - left - 1 ))
        component="${component[1,$left]}…${component[$((length - right + 1)),-1]}"
      fi
    fi
    compact+=("$component")
  done

  REPLY="${prefix}${(j:/:)compact}"
}

# Directory information cache
typeset -gi ZSH_DIR_CACHE_TTL=${ZSH_DIR_CACHE_TTL:-30}
typeset -gA _dir_cache_stamp=()
typeset -gA _dir_cache_time=()
typeset -gA _dir_cache_value=()

_prompt_directory_info() {
  emulate -L zsh

  local -A dir_info file_info after_info
  local entry formatted stamp after_stamp
  local key=$PWD
  local -i now=$SECONDS
  local -i count=0 bytes=0 incomplete=0

  if [[ ! -r . || ! -x . ]] ||
     ! zstat -H dir_info -- . 2>/dev/null; then
    _prompt_dir_info='? | ?'
    return
  fi

  # Directory checkpoint
  stamp="${dir_info[device]}:${dir_info[inode]}:${dir_info[mtime]}:${dir_info[ctime]}"

  # Reuse cache if unchanged and not expired
  if [[ ${_dir_cache_stamp[$key]-} == "$stamp" ]] &&
     (( now - ${_dir_cache_time[$key]:-0} < ZSH_DIR_CACHE_TTL )); then
    _prompt_dir_info="${_dir_cache_value[$key]}"
    return
  fi

  # Recompute direct regular files, including hidden files
  for entry in ./*(ND.); do
    if zstat -H file_info -- "$entry" 2>/dev/null; then
      (( ++count, bytes += file_info[size] ))
    else
      incomplete=1
    fi
  done

  if (( bytes < 1024 )); then
    formatted="$bytes B"
  elif (( bytes < 1048576 )); then
    printf -v formatted '%.1f KiB' $(( bytes / 1024.0 ))
  elif (( bytes < 1073741824 )); then
    printf -v formatted '%.1f MiB' $(( bytes / 1048576.0 ))
  else
    printf -v formatted '%.1f GiB' $(( bytes / 1073741824.0 ))
  fi

  _prompt_dir_info="$count | $formatted"
  (( incomplete )) && _prompt_dir_info+=' : partial'

  # Avoid caching a scan if directory entries changed during it
  if zstat -H after_info -- . 2>/dev/null; then
    after_stamp="${after_info[device]}:${after_info[inode]}:${after_info[mtime]}:${after_info[ctime]}"

    if [[ $stamp == "$after_stamp" ]]; then
      # Bound the cache to 64 directories
      if (( ${#_dir_cache_value} >= 64 )); then
        _dir_cache_stamp=()
        _dir_cache_time=()
        _dir_cache_value=()
      fi

      _dir_cache_stamp[$key]="$stamp"
      _dir_cache_time[$key]=$SECONDS
      _dir_cache_value[$key]="$_prompt_dir_info"
    fi
  fi
}

# Sculpted rail / VHS-mode prompt. Theme-adaptive named ANSI colors only.
# ● Insert (record), ■ Normal (stop), ▶ Visual (play).
# PROMPT_SUBST is deliberately disabled; values expand while building PROMPT.
_update_prompt() {
  emulate -L zsh

  local -i rc=${1:-0}
  local -i width=${COLUMNS:-80}
  local -i wide_budget narrow_budget
  local mode_seg mode_color path_seg time_seg stats_seg status_seg anchor
  local parent leaf count size partial_seg='' path_val
  local rail='%F{blue}╭─┤%f'
  local bar='%F{blue}├──%f'
  local join='%F{blue} ── %f'
  local layout=wide

  # Native Zsh colors: actual shades come from the terminal theme.
  case ${VIM_MODE:-INS} in
    NOR) mode_color=yellow;  mode_seg='%B%F{yellow}■ NOR%f%b' ;;
    VIS) mode_color=magenta; mode_seg='%B%F{magenta}▶ VIS%f%b' ;;
    *)   mode_color=green;   mode_seg='%B%F{green}● INS%f%b' ;;
  esac
  anchor="%B%F{${mode_color}}╰─❯%f%b"
  time_seg='%D{%H:%M:%S}'

  # Read cached directory statistics without rescanning.
  if [[ $_prompt_dir_info == *' | '* ]]; then
    count=${_prompt_dir_info%%' | '*}
    size=${_prompt_dir_info#*' | '}
    if [[ $size == *' : partial' ]]; then
      size=${size%' : partial'}
      partial_seg=' %F{yellow}~%f'
    fi
    stats_seg="%B%F{cyan}≡ ${count}%f%b · ${size}${partial_seg}"
  else
    stats_seg="${_prompt_dir_info}"
  fi

  # Keep successes quiet; reserve the error marker on either layout.
  status_seg=''
  (( rc != 0 )) && status_seg="${join}%B%F{red}✗ ${rc}%f%b"

  # A wide line contains rail/mode/time/path/stats/error. Use actual fixed
  # text lengths to decide whether it fits, not a fixed path-length cutoff.
  # 14: rail + mode + bar + spaces. 8: HH:MM:SS. 8: two joins.
  # Stats: '≡ count · size', approximately raw 'count | size' + 2.
  # A little slack prevents wrapping in fonts with unusual Unicode widths.
  wide_budget=$(( width - 14 - 8 - 8 - ${#_prompt_dir_info} - 2 - 2 ))
  (( rc != 0 )) && (( wide_budget -= 6 + ${#rc} ))

  # First try default per-component limits (12/20) in the full layout.
  _shorten_path "$PWD"
  if (( width < 85 || ${#REPLY} > wide_budget )); then
    layout=narrow
    # Only the rail, mode, path and optional error appear on line one.
    narrow_budget=$(( width - 14 - 2 ))
    (( rc != 0 )) && (( narrow_budget -= 6 + ${#rc} ))
    (( narrow_budget < 1 )) && narrow_budget=1
    _shorten_path "$PWD" "$narrow_budget"
  fi
  path_val=$REPLY

  # Sanitize control characters and escape prompt percent sequences.
  # PROMPT_SUBST stays disabled; these are plain rendered values.
  path_val=${path_val//$'\n'/↵}
  path_val=${path_val//$'\r'/}
  path_val=${path_val//$'\t'/⇥}
  path_val=${path_val//$'\e'/}
  path_val="${path_val//\%/%%}"

  # Parent path uses normal foreground; leaf remains highlighted.
  if [[ $path_val == */* && $path_val != / ]]; then
    parent=${path_val%/*}
    leaf=${path_val##*/}
    if [[ -z $parent ]]; then
      path_seg="/%B%F{magenta}${leaf}%f%b"
    else
      path_seg="${parent}/%B%F{magenta}${leaf}%f%b"
    fi
  else
    path_seg="%B%F{magenta}${path_val}%f%b"
  fi

  if [[ $layout == narrow ]]; then
    # Last-resort Zsh truncation only if even minimum components don't fit.
    # The rightmost component is preserved as far as the terminal allows.
    path_seg="%${narrow_budget}<…<${path_seg}%<<"
    PROMPT=$'\n'"${rail} ${mode_seg} ${bar} ${path_seg}${status_seg}"$'\n'\
"%F{blue}│%f  ${time_seg}${join}${stats_seg}"$'\n'"${anchor} "
  else
    PROMPT=$'\n'"${rail} ${mode_seg} ${bar} ${time_seg}${join}${path_seg}${join}${stats_seg}${status_seg}"$'\n'"${anchor} "
  fi

  PS2='%F{blue}│%f  '
}

_prompt_precmd() {
  LAST_STATUS=$?
  _prompt_directory_info
  _update_prompt "$LAST_STATUS"
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

typeset -g _hl_previous_buffer=''
typeset -gi _hl_previous_valid=0
_highlight_pre_redraw() {
  _sync_vi_mode

  if (( _hl_previous_valid )) &&
     [[ $BUFFER == "$_hl_previous_buffer" ]]; then
    return
  fi

  _custom_highlight

  _hl_previous_buffer=$BUFFER
  _hl_previous_valid=1
}

_highlight_finish() {
  region_highlight=()
  _hl_previous_valid=0
}

if [[ $- == *i* ]]; then
  autoload -Uz add-zle-hook-widget
  add-zle-hook-widget line-pre-redraw _highlight_pre_redraw
  add-zle-hook-widget line-finish     _highlight_finish
fi

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

    zle .backward-delete-char
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
    'm:{a-zA-Z}={A-Za-z}' \
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
