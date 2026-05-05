# ~/.bashrc
case $- in *i*) ;; *) return ;; esac

export EDITOR="nvim"
export VISUAL="nvim"
export LESS='-iMQRFX'

path_prepend() {
  [[ -d "$1" ]] || return
  case ":$PATH:" in *":$1:"*) ;; *) PATH="$1:$PATH" ;; esac
}

manpath_prepend() {
  [[ -d "$1" ]] || return
  case ":${MANPATH:-}:" in *":$1:"*) ;; *) MANPATH="$1${MANPATH:+:$MANPATH}" ;; esac
}

path_prepend "/opt/homebrew/bin"
for d in /opt/homebrew/opt/*/libexec/gnubin; do path_prepend "$d"; done
for d in /opt/homebrew/opt/*/libexec/gnuman; do manpath_prepend "$d"; done
path_prepend "$HOME/miniforge/bin"
export PATH MANPATH

if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
  alias ll='eza -l'
  alias la='eza -la'
  alias tree='eza --tree --level=3'
else
  if [[ "$OSTYPE" == darwin* ]]; then
    alias ls='ls -G'
  else
    alias ls='ls --color=auto'
  fi
fi

command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias l='ls'
alias e='nvim'
alias h='history'
alias ta='tmux attach || tmux new'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

config() {
  command git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" "$@"
}

alias g='git'
alias gs='git status -sb'
alias gl='git log --oneline --decorate --graph --max-count=15'
alias gf='git fetch --prune'
alias ga='git add -p'
alias gr='git restore'
alias gp='git push'

if [[ "$OSTYPE" == darwin* ]]; then
  pbcopy() { if (( $# )); then command cat -- "$@" | command pbcopy; else command pbcopy; fi; }
  pbpaste() { command pbpaste; }
elif command -v wl-copy >/dev/null 2>&1; then
  pbcopy() { if (( $# )); then command cat -- "$@" | command wl-copy; else command wl-copy; fi; }
  pbpaste() { command wl-paste; }
elif command -v xclip >/dev/null 2>&1; then
  pbcopy() { if (( $# )); then command cat -- "$@" | command xclip -selection clipboard; else command xclip -selection clipboard; fi; }
  pbpaste() { command xclip -selection clipboard -o; }
elif command -v xsel >/dev/null 2>&1; then
  pbcopy() { if (( $# )); then command cat -- "$@" | command xsel --clipboard --input; else command xsel --clipboard --input; fi; }
  pbpaste() { command xsel --clipboard --output; }
else
  pbcopy() { cat >/dev/null; }
  pbpaste() { return 1; }
fi

mkcd() {
  [[ -n "$1" ]] || return 1
  mkdir -p -- "$1" && cd -- "$1"
}

extract() {
  [[ -f "$1" ]] || { echo "Not a file: $1"; return 1; }
  case "$1" in
    *.tar.bz2) tar xjf "$1" ;;
    *.tar.gz)  tar xzf "$1" ;;
    *.zip)     unzip -q "$1" ;;
    *.tar.xz)  tar xJf "$1" ;;
    *.rar)     unrar x -idq "$1" ;;
    *) echo "Unknown archive"; return 1 ;;
  esac
}

HISTFILE="${HISTFILE:-$HOME/.bash_history}"
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoredups:erasedups
shopt -s histappend checkwinsize

set -o vi
set -o noclobber
set -o pipefail

bind '"jk": vi-movement-mode'
bind '"kj": vi-movement-mode'
bind '"\C-p": history-search-backward'
bind '"\C-n": history-search-forward'

_shorten_path() {
  local full="${1:-$PWD}" prefix=""
  [[ "$full" == "$HOME"* ]] && prefix="~" full="${full/#$HOME/}"

  IFS='/' read -ra parts <<< "${full#/}"

  if (( ${#parts[@]} == 0 )); then
    printf '%s/\n' "$prefix"
  elif (( ${#parts[@]} > 4 )); then
    printf '%s/%s/%s/.../%s/%s\n' \
      "$prefix" "${parts[0]}" "${parts[1]}" \
      "${parts[${#parts[@]}-2]}" "${parts[${#parts[@]}-1]}"
  else
    local joined
    joined="$(IFS=/; echo "${parts[*]}")"
    printf '%s/%s\n' "$prefix" "$joined"
  fi
}

__prompt() {
  local s="$1"
  local reset='\[\033[0m\]'
  local bold='\[\033[1m\]'
  local white='\[\033[1;37m\]'
  local red='\[\033[1;31m\]'
  local green='\[\033[1;32m\]'
  local cyan_bg='\[\033[46m\]'
  local blue_bg='\[\033[44m\]'
  local magenta='\[\033[1;35m\]'

  local st="${cyan_bg} ${green}0${reset} "
  [[ "$s" -ne 0 ]] && st="${cyan_bg} ${red}${s}${reset} "

  PS1="${blue_bg} ${white}\A${reset} :: ${magenta}$(_shorten_path)${reset} :: ${st}
${white}#${reset} "
  PS2="  "
}

__prompt_command() {
  local s=$?
  history -a
  history -n
  __prompt "$s"
}

PROMPT_COMMAND=__prompt_command