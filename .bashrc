# ~/.bashrc
case $- in *i*) ;; *) return ;; esac

export LESS='-iMQRFX'
for d in /opt/homebrew/bin "$HOME/.local/bin" /opt/homebrew/opt/*/libexec/gnubin "$HOME/miniforge/bin"; do
  [[ -d $d && :$PATH: != *":$d:"* ]] && PATH="$d:$PATH"
done
export PATH
if command -v nvim >/dev/null 2>&1; then
  export EDITOR=nvim
  alias vi=nvim vim=nvim
elif command -v vim >/dev/null 2>&1; then export EDITOR=vim
else export EDITOR=vi
fi
export VISUAL="$EDITOR"

HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend checkwinsize promptvars
shopt -s globstar 2>/dev/null || :
set -o vi
bind 'set show-mode-in-prompt on' 2>/dev/null || :
bind 'set vi-ins-mode-string "\1\e[1;34m\2┗━━┫ \1\e[0;32m\2● INS\1\e[1;34m\2 ┣━━\1\e[0m\2"' 2>/dev/null || :
bind 'set vi-cmd-mode-string "\1\e[1;34m\2┗━━┫ \1\e[0;33m\2■ NOR\1\e[1;34m\2 ┣━━\1\e[0m\2"' 2>/dev/null || :
bind 'set keyseq-timeout 250' 2>/dev/null || :
bind -m vi-insert '"jk": vi-movement-mode'
bind 'set completion-ignore-case on'
bind -m vi-insert '"\e[A": history-search-backward'
bind -m vi-insert '"\e[B": history-search-forward'
bind -m vi-insert '"\eOA": history-search-backward'
bind -m vi-insert '"\eOB": history-search-forward'
# Native completion on Linux when already installed.
if [[ -r /usr/share/bash-completion/bash_completion ]]; then
  . /usr/share/bash-completion/bash_completion
fi

config() { command git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"; }
alias gs='git status -sb' gd='git diff' gds='git diff --staged' gl='git log --oneline --decorate --graph --max-count=15'
alias gf='git fetch --prune' ga='git add -p' gp='git push' ta='tmux attach || tmux new'
alias ..='cd ..' ...='cd ../..' ....='cd ../../..' .....='cd ../../../..'
mkcd() { [[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1"; }
extract() {
  [[ $# == 1 && -f $1 ]] || { printf 'usage: extract archive\n' >&2; return 2; }
  case $1 in
    *.tar.gz|*.tgz|*.tar.bz2|*.tar.xz|*.tar) tar -xf "$1" ;;
    *.zip) unzip "$1" ;;
    *) printf 'Unsupported archive: %s\n' "$1" >&2; return 2 ;;
  esac
}
copy() {
  if (( $# )); then (set -o pipefail; cat -- "$@" | _copy); else _copy; fi
}
_copy() {
  if [[ $OSTYPE == darwin* ]] && command -v pbcopy >/dev/null; then command pbcopy
  elif [[ -n ${WAYLAND_DISPLAY:-} ]] && command -v wl-copy >/dev/null; then wl-copy
  elif [[ -n ${DISPLAY:-} ]] && command -v xclip >/dev/null; then xclip -selection clipboard
  elif [[ -n ${DISPLAY:-} ]] && command -v xsel >/dev/null; then xsel --clipboard --input
  else printf 'copy: no clipboard backend (use tmux copy mode over SSH)\n' >&2; return 127; fi
}
paste() {
  if [[ $OSTYPE == darwin* ]] && command -v pbpaste >/dev/null; then command pbpaste
  elif [[ -n ${WAYLAND_DISPLAY:-} ]] && command -v wl-paste >/dev/null; then wl-paste
  elif [[ -n ${DISPLAY:-} ]] && command -v xclip >/dev/null; then xclip -selection clipboard -o
  elif [[ -n ${DISPLAY:-} ]] && command -v xsel >/dev/null; then xsel --clipboard --output
  else printf 'paste: no clipboard backend\n' >&2; return 127; fi
}
if ! command -v watch >/dev/null 2>&1; then
  watch() (
    local interval=2
    if [[ ${1:-} == -n ]]; then interval=${2:-}; shift 2 || return 2; fi
    [[ $interval =~ ^[0-9]+([.][0-9]+)?$ && $interval =~ [1-9] && $# -gt 0 ]] || return 2
    while :; do clear; date; "$@"; sleep "$interval" || return; done
  )
fi

if command -v eza >/dev/null 2>&1; then
  alias ll='eza -l' la='eza -la' tree='eza --tree --level=3'
else
  alias ll='ls -l' la='ls -la'
fi
if command -v zoxide >/dev/null 2>&1; then eval "$(zoxide init bash)"; fi
if command -v fzf >/dev/null 2>&1; then
  # fzf >= 0.48; older builds remain usable as a command.
  _fzf_init=$(fzf --bash 2>/dev/null) && eval "$_fzf_init"
  unset _fzf_init
fi
ff() {
  local root=${1:-.} file
  if command -v fzf >/dev/null 2>&1; then
    if command -v fd >/dev/null 2>&1; then file=$(fd -0 -t f . "$root" | fzf --read0 --print0 | tr -d '\000') || return
    else file=$(find "$root" -type f -print | fzf) || return; fi
    [[ -n $file ]] && "$EDITOR" -- "$file"
  else find "$root" -type f; fi
}

path_entries() { printf '%s\n' "$PATH" | tr ':' '\n'; }
ports() {
  if command -v ss >/dev/null 2>&1; then ss -lntup
  elif command -v lsof >/dev/null 2>&1; then lsof -nP -iTCP -sTCP:LISTEN
  else printf 'ports: ss or lsof required\n' >&2; return 127; fi
}

# Directory statistics: immediate entries only; reuse the current result for 30s.
_dir_path=''
_dir_time=0
_dir_info='≡ ? · □ ? · ?'

_directory_info() {
  [[ $_dir_path == "$PWD" ]] && (( SECONDS - _dir_time >= 0 && SECONDS - _dir_time < 30 )) && return 0
  local entry sizes n bytes=0 files=0 dirs=0 seen=0 complete=0 size='?' suffix=' …'
  local unit=1 label=B
  local -a paths=()
  _dir_path=$PWD
  _dir_info='≡ ? · □ ? · ?'
  if [[ -r . && -x . ]]; then
    # NUL-separated entries, no recursion. A final empty record marks success.
    while IFS= read -r -d '' entry; do
      if [[ -z $entry ]]; then complete=1; break; fi
      (( seen >= 512 )) && break
      (( seen += 1 ))
      if [[ -L $entry ]]; then continue
      elif [[ -d $entry ]]; then (( dirs += 1 ))
      elif [[ -f $entry ]]; then paths+=("$entry"); (( files += 1 ))
      fi
    done < <(command find . ! -name . -prune -print0 2>/dev/null && printf '\0')
    if (( ! complete && seen == 0 )); then _dir_time=$SECONDS; return 0; fi
    (( complete )) && suffix=''
    if (( files == 0 )); then size='0 B'
    else
      # One batch stat, not one process per file. macOS ships BSD stat.
      if [[ $OSTYPE == darwin* ]]; then
        sizes=$(/usr/bin/stat -f '%z' "${paths[@]}" 2>/dev/null) || sizes=''
      else
        sizes=$(command stat -c '%s' -- "${paths[@]}" 2>/dev/null) || sizes=''
      fi
      if [[ -n $sizes ]]; then
        local measured=0 valid=1
        while IFS= read -r n; do
          if [[ $n =~ ^[0-9]+$ ]]; then
            (( bytes += n, measured += 1 ))
            (( bytes >= 0 )) || valid=0
          else valid=0; fi
        done <<< "$sizes"
        if (( valid && measured == files )); then
          for label in B KiB MiB GiB TiB; do
            (( bytes / unit < 1024 )) && break
            [[ $label == TiB ]] && break
            (( unit *= 1024 ))
          done
          if (( unit == 1 )); then size="$bytes B"
          else printf -v size '%d.%d %s' "$((bytes / unit))" "$(((bytes % unit) * 10 / unit))" "$label"; fi
        fi
      fi
    fi
    _dir_info="≡ $files · □ $dirs · $size$suffix"
  fi
  _dir_time=$SECONDS
}

# Bash has no wcwidth builtin. Count UTF-8 bytes conservatively, except for
# our fixed single-cell prompt glyphs. Return the estimate in REPLY.
_cells() {
  local value=$1
  value=${value//…/.}; value=${value//≡/=}; value=${value//□/+}; value=${value//·/.}; value=${value//✗/x}
  local LC_ALL=C
  REPLY=${#value}
}

_fit_text() {
  local value=$1 budget=$2 style=${3:-middle} n left right piece REPLY
  _cells "$value"
  if (( REPLY <= budget )); then _fitted=$value; return 0; fi
  _fitted=''
  (( budget > 0 )) || return 0
  _fitted='…'
  n=$((budget-1)); (( n < ${#value} )) || n=$((${#value}-1))
  while (( n > 0 )); do
    if [[ $style == end ]]; then piece="${value:0:n}…"
    else
      left=$(((n+1)/2))
      if [[ $style == path && $n -gt 2 ]]; then left=$((n*2/5)); fi
      right=$((n-left))
      piece="${value:0:left}…"
      (( right )) && piece+=${value: -right}
    fi
    _cells "$piece"
    if (( REPLY <= budget )); then _fitted=$piece; return 0; fi
    (( n-- ))
  done
  return 0
}

_render_prompt() {
  local width=${COLUMNS:-80} host=${HOSTNAME%%.*} value=$PWD budget REPLY _fitted
  local path_cells fail_cells compact=0
  [[ $width =~ ^[0-9]+$ ]] || width=80
  host=${host:-localhost}
  host=${host//[[:cntrl:]]/?}
  if [[ $value == "$HOME" ]]; then value='~'
  elif [[ $value == "$HOME/"* ]]; then value="~/${value#"$HOME/"}"; fi
  value=${value//[[:cntrl:]]/?}
  _cells "$_exit_status"; fail_cells=$REPLY
  if [[ ${TERM:-dumb} == dumb ]] || (( width < 20 || width < 17 + fail_cells )); then compact=1; fi
  # Readline owns the live mode string on the final line. Hide it in tiny panes.
  if [[ ${_prompt_compact:-0} != "$compact" ]]; then
    if (( compact )); then bind 'set show-mode-in-prompt off' 2>/dev/null || :
    else bind 'set show-mode-in-prompt on' 2>/dev/null || :; fi
    _prompt_compact=$compact
  fi
  if (( compact )); then PS1='\$ '; return 0; fi
  # English month abbreviations without changing the interactive locale.
  # Bash 3.2 (macOS) falls back to the standard date utility.
  if (( BASH_VERSINFO[0] >= 4 )) && LC_ALL=C printf -v _prompt_time '%(%d %b %H:%M)T' -1 2>/dev/null; then
    _prompt_time=${_prompt_time^^}
  else
    _prompt_time=$(LC_ALL=C date '+%d %b %H:%M' | LC_ALL=C tr '[:lower:]' '[:upper:]')
  fi
  # Keep the clock and failure visible even when the hostname does not fit.
  _fit_text "$host" "$((width-20-fail_cells))"; _prompt_host=$_fitted
  PS1='\[\e[1;34m\]┏━━ \[\e[0m\]'
  [[ -n $_prompt_host ]] && PS1+='${_prompt_host} · '
  PS1+='${_prompt_time}\[\e[31m\]${_exit_status}\[\e[0m\]\n'
  budget=$((width-5)); (( budget > 40 )) && budget=40
  _fit_text "$value" "$budget" path; _prompt_path=$_fitted
  _cells "$_prompt_path"; path_cells=$REPLY
  _cells "$_dir_info"
  PS1+='\[\e[1;34m\]┣━━ \[\e[0;36m\]${_prompt_path}\[\e[0m\]'
  if (( 4 + path_cells + 4 + REPLY < width )); then
    _prompt_stats=$_dir_info
    PS1+='\[\e[1;34m\] ━━ \[\e[0m\]${_prompt_stats}\n'
  else
    _fit_text "$_dir_info" "$((width-5))" end; _prompt_stats=$_fitted
    PS1+='\n\[\e[1;34m\]┣━━ \[\e[0m\]${_prompt_stats}\n'
  fi
  # The final line begins with Readline's Vi-mode rail, not a right prompt.
  PS1+='❯ '
}

_prompt() {
  local rc=$? status=''
  history -a; history -n
  _directory_info
  (( rc )) && status=" ✗ $rc"
  _exit_status=$status
  _render_prompt
  return "$rc"
}
PROMPT_COMMAND=_prompt

# Keep arrowless editing available after optional fzf setup.
bind -m vi-insert '"\C-f": forward-char'
bind -m vi-insert '"\C-b": backward-char'
bind -m vi-insert '"\C-p": history-search-backward'
bind -m vi-insert '"\C-n": history-search-forward'
bind -m vi-insert '"\C-r": reverse-search-history'
bind -m vi-insert '"\C-a": beginning-of-line'
bind -m vi-insert '"\C-e": end-of-line'
bind -m vi-insert '"\C-@": menu-complete'
bind -m vi-insert '"\e[Z": menu-complete-backward'
