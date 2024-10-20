# `grep default` highlight color
export GREP_COLOR="1;32"

# EDITOR
export EDITOR="nano"
export SUDO_EDITOR="nano"
export VISUAL="nano"

# Colored man
export MANPAGER="less -R --use-color -Dd+g -Du+b"

# History settings
export HISTCONTROL=ignoredups:erasedups:ignorespace

# For setting history length see HISTSIZE and HISTFILESIZE in bash(1).
export HISTSIZE=10000
export HISTFILESIZE=$HISTSIZE

# Append history entries.
shopt -s histappend

# After each command, save and reload history.
PROMPT_COMMAND="history -a; history -c; history -r; $PROMP_COMMAND"

# Check the window size after each command and, if necessary, update the values of LINES and COLUMNS.
shopt -s checkwinsize

# load results of history substitution into the readline editing buffer
shopt -s histverify

# Autocompletion

# cycle through all matches with 'TAB' key
bind 'TAB:menu-complete'

# necessary for programmable completion
shopt -s extglob # cd when entering just a path
shopt -s autocd

# Prompt

function __setprompt() {
    local exit_status=$?
    local arrow_color="\[\033[1;37m\]"
    local conda_env="\[\033[1;33m\]$CONDA_DEFAULT_ENV\[\033[1;33m\]"
    local git_branch=""

    if [[ $exit_status != 0 ]]; then
        arrow_color="\[\033[1;31m\]"
    fi

    if command -v git &>/dev/null; then
        git_branch=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
    fi

    if [[ ! -z $git_branch ]]; then
        git_branch="\[\033[1;33m\]${git_branch}\[\033[1;33m\]"
    fi

    if [[ "${CONDA_DEFAULT_ENV}" != "" && "${git_branch}" != "" ]]; then
        env_branch="\[\033[0;37m\](${conda_env}\[\033[0;37m\]:${git_branch}\[\033[0;37m\])"
    else
        env_branch="\[\033[0;37m\](${conda_env}${git_branch}\[\033[0;37m\])"
    fi

    PS1="\[\033[0;32m\]\u@\h ${arrow_color}➜ \[\033[1;34m\]\w ${env_branch} \[\033[1;37m\]$ \[\033[00m\]"
}

PROMPT_COMMAND="__setprompt; $PROMPT_COMMAND"

# Aliases

# enable color support of ls, grep and ip, also add handy aliases
if [[ -x /usr/bin/dircolors ]]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
	alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias diff='diff --color=auto'
    alias ip='ip -color'
fi

# common commands
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias lm='ls | more'
alias ll='ls -lFh'
alias la='ls -alFh --group-directories-first'
alias l1='ls -1F --group-directories-first'
alias l1m='ls -1F --group-directories-first | more'
alias lh='ls -ld .??*'
alias lsn='ls | cat -n'
alias mkdir='mkdir -p -v'
alias cp='cp --preserve=all'
alias cpv='cp --preserve=all -v'
alias cpr='cp --preserve=all -R'
alias cpp='rsync -ahW --info=progress2'
alias cs='printf "\033c"'
alias q='exit'

# memory/CPU
alias df='df -Tha --total'
alias free='free -mt'
alias ps='ps auxf'
alias ht='htop'
alias cputemp='sensors | grep Core'

# applications shortcuts
alias myip='curl -s -m 5 https://ipleak.net/json/'
alias w3m='w3m https://duckduckgo.com'

# If user has entered command which invokes non-available
# utility, command-not-found will give a package suggestions.
if [ -x /data/data/com.termux/files/usr/libexec/termux/command-not-found ]; then
	command_not_found_handle() {
		/data/data/com.termux/files/usr/libexec/termux/command-not-found "$1"
	}
fi

# nnn "cd on quit"
n() {
    # Block nesting of nnn in subshells
    if [ -n $NNNVL ] && [ "${NNNVL:-0}" -ge 1 ]; then
        echo "nnn is already running"
        return
    fi

    # The behaviour is set to cd on quit (nnn checks if NNN_TMPFILE is set)
    # If NNN_TMPFILE is set to a custom path, it must be exported for nnn to
    # see. To cd on quit only on ^G, remove the "export" and make sure not to
    # use a custom path, i.e. set NNN_TMPFILE *exactly* as follows:
    #   NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
    export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"

    # Unmask ^Q (, ^V etc.) (if required, see `stty -a`) to Quit nnn
    # stty start undef
    # stty stop undef
    # stty lwrap undef
    # stty lnext undef

    nnn "$@"

    if [ -f "$NNN_TMPFILE" ]; then
        . "$NNN_TMPFILE"
        rm -f "$NNN_TMPFILE" > /dev/null
    fi
}

eval "$(zoxide init bash)"
