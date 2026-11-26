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
shopt -s histappend checkwinsize
shopt -s globstar 2>/dev/null || :
set -o vi
bind 'set show-mode-in-prompt on' 2>/dev/null || :
bind 'set vi-ins-mode-string "[INS] "' 2>/dev/null || :
bind 'set vi-cmd-mode-string "[NOR] "' 2>/dev/null || :
bind 'set keyseq-timeout 250' 2>/dev/null || :
bind -m vi-insert '"jk": vi-movement-mode'
bind 'set completion-ignore-case on'
bind -m vi-insert '"\e[A": history-search-backward'
bind -m vi-insert '"\e[B": history-search-forward'
bind -m vi-insert '"\eOA": history-search-backward'
bind -m vi-insert '"\eOB": history-search-forward'
bind -m vi-insert '"\C-p": history-search-backward'
bind -m vi-insert '"\C-n": history-search-forward'
# Native completion on Linux when already installed.
if [[ -r /usr/share/bash-completion/bash_completion ]]; then
  . /usr/share/bash-completion/bash_completion
fi

config() { command git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"; }
alias gs='git status -sb' gd='git diff' gds='git diff --staged' gl='git log --oneline --decorate --graph --max-count=15'
alias gf='git fetch --prune' ga='git add -p' gp='git push' ta='tmux attach || tmux new'
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

# Git status is calculated once per prompt; never interpolate it as shell code.
_prompt() {
  local rc=$? branch='' dirty='' status='' git_info=''
  history -a; history -n
  if command -v git >/dev/null 2>&1; then
    branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null) || branch=''
    if [[ -n $branch ]]; then
      git_info=$(git --no-optional-locks status --porcelain --untracked-files=normal 2>/dev/null) && [[ -n $git_info ]] && dirty='*'
    fi
  fi
  (( rc )) && status=" exit:$rc"
  # Use literal parameter expansion in PS1 (no recursive evaluation of values).
  _git_branch=${branch:+ $branch$dirty}
  _exit_status=$status
  PS1='\[\e[34m\]╭─ \t ── \h\[\e[0m\]\n\[\e[36m\]╰─ \w\[\e[35m\]${_git_branch}\[\e[31m\]${_exit_status}\[\e[0m\] \$ '
  return "$rc"
}
PROMPT_COMMAND=_prompt
