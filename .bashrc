# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc) for examples

# If not running interactively, don't do anything.
case $- in
    *i*) ;;
    *) return;;
esac

# Enable vi-style command-line editing
set -o vi

# Avoid duplicates in history.
export HISTCONTROL=ignoredups:erasedups:ignorespace

# For setting history length see HISTSIZE and HISTFILESIZE in bash(1).
export HISTSIZE=10000
export HISTFILESIZE=$HISTSIZE

# Append history entries.
shopt -s histappend

# After each command, save and reload history.
PROMPT_COMMAND="history -a; history -c; history -r"

# Check the window size after each command and, if necessary, update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Make less more friendly for non-text input files, see lesspipe(1).
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Enable color support of ls and also add handy aliases.
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Some more ls aliases.
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Enable programmable completion features.
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
    fi
fi

# Ignore case on auto-completion.
bind "set completion-ignore-case on"

# Show auto-completion list automatically, without double tab.
bind "set show-all-if-ambiguous On"

# Automatically set less with ignore case searching and show line numbers.
export LESS='-i -N'

# Prompt before copying, moving, deleting.
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# Make man easier to read.
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

# Check disk space.
alias diskspace="du -S | sort -n -r | more"

# Check folder space.
alias folders="find . -maxdepth 1 -type d -print | xargs du -sk | sort -rn"

# Extracts any archive(s) (if unp isn't installed)
extract() {
	for archive in $*; do
		if [ -f $archive ] ; then
			case $archive in
				*.tar.bz2)   tar xvjf $archive    ;;
				*.tar.gz)    tar xvzf $archive    ;;
				*.bz2)       bunzip2 $archive     ;;
				*.rar)       rar x $archive       ;;
				*.gz)        gunzip $archive      ;;
				*.tar)       tar xvf $archive     ;;
				*.tbz2)      tar xvjf $archive    ;;
				*.tgz)       tar xvzf $archive    ;;
				*.zip)       unzip $archive       ;;
				*.Z)         uncompress $archive  ;;
				*.7z)        7z x $archive        ;;
				*)           echo "don't know how to extract '$archive'..." ;;
			esac
		else
			echo "'$archive' is not a valid file!"
		fi
	done
}

treels() {
    function list_contents() {
        local prefix="$2"
        local item

        for item in "$1"/*; do
            if [ -d "$item" ]; then
                echo "${prefix}├── $(basename "$item")/"
                list_contents "$item" "${prefix}│   "
            else
                ls -lh "$item" | awk -v prefix="$prefix" -v name="$(basename "$item")" '{print prefix "├── " $1 " " $3 " " $4 " " $5 " " $6 " " $7 " " $8 " " name}'
            fi
        done
    }

    local dir="$1"

    # Check if the argument is provided
    if [ -z "$dir" ]; then
        echo "Please provide a directory."
        return 1
    fi

    # Remove trailing slash if it exists
    dir="${dir%/}"

    # Check if the argument is a directory
    if [ ! -d "$dir" ]; then
        echo "\"$dir\" is not a directory."
        return 1
    fi

    list_contents "$dir"
}

# Check for gawk
! [ -x "$(command -v gawk)" ] && echo "Please install gawk for full functionality"

# Welcome screen.
function welcome_screen {
    let upSeconds="$(/usr/bin/cut -d. -f1 /proc/uptime)"
    let secs=$((${upSeconds}%60))
    let mins=$((${upSeconds}/60%60))
    let hours=$((${upSeconds}/3600%24))
    let days=$((${upSeconds}/86400))
    UPTIME=`printf "%d days, %02dh %02dm %02ds" "$days" "$hours" "$mins" "$secs"`

    read one five fifteen rest < /proc/loadavg

    clear
    . /etc/lsb-release
    echo "$(tput setaf 2)`date +"WN %V %A, %e %B %Y, %r"`
`uname -srmo` $DISTRIB_ID $DISTRIB_RELEASE $DISTRIB_CODENAME$(tput setaf 1)
Uptime.............: ${UPTIME}
Memory.............: `cat /proc/meminfo | grep MemFree | awk {'print $2'}` kB (Free) / `cat /proc/meminfo | grep MemTotal | awk {'print $2'}` kB (Total)
Load Averages......: ${one}, ${five}, ${fifteen} (1, 5, 15 min)
Running Processes..: `ps ax | wc -l | tr -d " "`
IP Addresses.......: `ip a | awk '{match($0, /inet ([^ ]+) /, ip); for (i in ip) {if (ip[i]!~/inet/ && ip[i]~/\./) printf "%s ", ip[i]}}' | sed 's/ /; /g; s/; $/\n/g'`
$(tput sgr0)"
}
welcome_screen

# Command prompt
alias cpu="grep 'cpu ' /proc/stat | awk '{usage=(\$2+\$4)*100/(\$2+\$4+\$5)} END {print usage}' | awk '{printf(\"%.1f\n\", \$1)}'"
function __setprompt {
    local LAST_COMMAND=$? # Must come first!

    # Define colors
    local LIGHTGRAY="\033[0;37m"
    local WHITE="\033[1;37m"
    local BLACK="\033[0;30m"
    local DARKGRAY="\033[1;30m"
    local RED="\033[0;31m"
    local LIGHTRED="\033[1;31m"
    local GREEN="\033[0;32m"
    local LIGHTGREEN="\033[1;32m"
    local BROWN="\033[0;33m"
    local YELLOW="\033[1;33m"
    local BLUE="\033[0;34m"
    local LIGHTBLUE="\033[1;34m"
    local MAGENTA="\033[0;35m"
    local LIGHTMAGENTA="\033[1;35m"
    local CYAN="\033[0;36m"
    local LIGHTCYAN="\033[1;36m"
    local NOCOLOR="\033[0m"

    # Show error exit code if there is one
    if [[ $LAST_COMMAND -ne 0 ]]; then
        PS1="\[${DARKGRAY}\](\[${LIGHTRED}\]ERROR\[${DARKGRAY}\])-(\[${RED}\]Exit Code \[${LIGHTRED}\]${LAST_COMMAND}\[${DARKGRAY}\])-(\[${RED}\]"
        if [[ $LAST_COMMAND -eq 1 ]]; then
            PS1+="General error"
        elif [ $LAST_COMMAND -eq 2 ]; then
            PS1+="Missing keyword, command, or permission problem"
        elif [ $LAST_COMMAND -eq 126 ]; then
            PS1+="Permission problem or command is not an executable"
        elif [ $LAST_COMMAND -eq 127 ]; then
            PS1+="Command not found"
        elif [ $LAST_COMMAND -eq 128 ]; then
            PS1+="Invalid argument to exit"
        elif [ $LAST_COMMAND -eq 129 ]; then
            PS1+="Fatal error signal 1"
        elif [ $LAST_COMMAND -eq 130 ]; then
            PS1+="Script terminated by Control-C"
        elif [ $LAST_COMMAND -eq 131 ]; then
            PS1+="Fatal error signal 3"
        elif [ $LAST_COMMAND -eq 132 ]; then
            PS1+="Fatal error signal 4"
        elif [ $LAST_COMMAND -eq 133 ]; then
            PS1+="Fatal error signal 5"
        elif [ $LAST_COMMAND -eq 134 ]; then
            PS1+="Fatal error signal 6"
        elif [ $LAST_COMMAND -eq 135 ]; then
            PS1+="Fatal error signal 7"
        elif [ $LAST_COMMAND -eq 136 ]; then
            PS1+="Fatal error signal 8"
        elif [ $LAST_COMMAND -eq 137 ]; then
            PS1+="Fatal error signal 9"
        elif [ $LAST_COMMAND -gt 255 ]; then
            PS1+="Exit status out of range"
        else
            PS1+="Unknown error code"
        fi
        PS1+="\[${DARKGRAY}\])\[${NOCOLOR}\]\n"
    else
        PS1=""
    fi

    # Date
    PS1+="\[${DARKGRAY}\](\[${CYAN}\]\$(date +%a) $(date +%b-'%-d')" # Date
    PS1+="${BLUE} $(date +'%-I':%M:%S%P)\[${DARKGRAY}\])-" # Time

    # CPU
    PS1+="(\[${MAGENTA}\]CPU $(cpu)%"

    # Jobs
    PS1+="\[${DARKGRAY}\]:\[${MAGENTA}\]\j"

    # Network Connections (for a server - comment out for non-server)
    PS1+="\[${DARKGRAY}\]:\[${MAGENTA}\]Net $(awk 'END {print NR}' /proc/net/tcp)"

    PS1+="\[${DARKGRAY}\])-"

    # User and server
    local SSH_IP=`echo $SSH_CLIENT | awk '{ print $1 }'`
    local SSH2_IP=`echo $SSH2_CLIENT | awk '{ print $1 }'`
    if [ $SSH2_IP ] || [ $SSH_IP ] ; then
        PS1+="(\[${RED}\]\u@\h"
    else
        PS1+="(\[${RED}\]\u"
    fi

    # Current directory
    PS1+="\[${DARKGRAY}\]:\[${BROWN}\]\w\[${DARKGRAY}\])-"

    # Total size of files in current directory
    PS1+="(\[${GREEN}\]$(/bin/ls -lah | /bin/grep -m 1 total | /bin/sed 's/total //')\[${DARKGRAY}\]:"

    # Number of files
    PS1+="\[${GREEN}\]\$(/bin/ls -A -1 | /usr/bin/wc -l)\[${DARKGRAY}\])"

    # Skip to the next line
    PS1+="\n"

    if [[ $EUID -ne 0 ]]; then
        PS1+="\[${GREEN}\]>\[${NOCOLOR}\] " # Normal user
    else
        PS1+="\[${RED}\]>\[${NOCOLOR}\] " # Root user
    fi

    # PS2 is used to continue a command using the \ character
    PS2="\[${DARKGRAY}\]>\[${NOCOLOR}\] "

    # PS3 is used to enter a number choice in a script
    PS3='Please enter a number from above list: '

    # PS4 is used for tracing a script in debug mode
    PS4='\[${DARKGRAY}\]+\[${NOCOLOR}\] '
    
    # Show git branch
    parse_git_branch() {
        git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
    }
    [[ $CONDA_DEFAULT_ENV != "" && $(parse_git_branch) != "" ]] && \
    PS1+="\[${DARKGRAY}\](\[${YELLOW}\]$CONDA_DEFAULT_ENV\[${DARKGRAY}\]:\[${YELLOW}\]$(parse_git_branch)\[${DARKGRAY}\])\[${NOCOLOR}\] " || \
    PS1+="\[${DARKGRAY}\](\[${YELLOW}\]$CONDA_DEFAULT_ENV$(parse_git_branch)\[${DARKGRAY}\])\[${NOCOLOR}\] "
}
PROMPT_COMMAND="__setprompt; $PROMPT_COMMAND"
