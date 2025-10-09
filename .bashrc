# ~/.bashrc
# only for interactive shells
case $- in *i*) ;; *) return ;; esac

#### env
export EDITOR=nvim
export VISUAL=nvim

#### history
HISTSIZE=10000
HISTFILESIZE=10000
HISTFILE=${HISTFILE:-$HOME/.bash_history}
shopt -s histappend
HISTCONTROL=ignoredups:erasedups:ignorespace

#### vi mode
set -o vi
bind -m vi-insert '"jk": vi-movement-mode'
bind -m vi-insert '"kj": vi-movement-mode'

#### tool aliases
command -v rg >/dev/null && alias grep='rg --hidden --smart-case'
command -v fd >/dev/null && alias find='fd'

if command -v eza >/dev/null; then
  alias ls='eza'
  alias ll='eza -l'
  alias la='eza -la'
  alias tree='eza --tree --level=3'
else
  alias ll='ls -alF'
  alias la='ls -A'
  alias l='ls -CF'
fi

command -v zoxide >/dev/null && eval "$(zoxide init bash)"

#### general aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias g='git'
alias e='nvim'
alias ta='tmux attach || tmux new'
alias ..='cd ..'; alias ...='cd ../..'; alias ....='cd ../../..'

#### tiny helpers
mkcd(){ mkdir -p -- "$1" && cd -- "$1"; }
extract(){ case "$1" in
  *.tar.gz)  tar xzf "$1" ;;
  *.tar.bz2) tar xjf "$1" ;;
  *.tar.xz)  tar xJf "$1" ;;
  *.zip)     unzip "$1" ;;
  *) echo "unknown archive" ;;
esac }

#### clipboard
if command -v pbcopy >/dev/null && command -v pbpaste >/dev/null; then
  : # mac has it
elif command -v xclip >/dev/null; then
  pbcopy(){ xclip -selection clipboard; }
  pbpaste(){ xclip -selection clipboard -o; }
elif command -v xsel >/dev/null; then
  pbcopy(){ xsel --clipboard --input; }
  pbpaste(){ xsel --clipboard --output; }
else
  pbcopy(){ :; }; pbpaste(){ :; }
fi

#### prompt (time :: cwd, newline, arrow)
__last_status=0
__ps1(){
  __last_status=$?
  local arrow=">"
  [ $__last_status -ne 0 ] && arrow="<"
  PS1="[\t] \w\n$arrow "
}
PROMPT_COMMAND=__ps1