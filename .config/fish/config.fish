# ~/.config/fish/config.fish
##### Environment and paths
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx LESS -iMQRFX
if test -d /opt/homebrew/bin
    fish_add_path --global --path /opt/homebrew/bin
end
for d in /opt/homebrew/opt/*/libexec/gnubin
    test -d "$d"; and fish_add_path --global --path "$d"
end
for d in /opt/homebrew/opt/*/libexec/gnuman
    if test -d "$d"; and not contains -- "$d" $MANPATH
        # Empty final entry preserves the platform's default man search path.
        set -gx MANPATH "$d" $MANPATH
        contains -- '' $MANPATH; or set -a MANPATH ''
    end
end
if test -d "$HOME/miniforge/bin"
    fish_add_path --global --path "$HOME/miniforge/bin"
end
status is-interactive; or return

##### Tunables — set before sourcing this file to override
set -q VHS_PATH_PARENT_MAX; or set -g VHS_PATH_PARENT_MAX 12
set -q VHS_PATH_LEAF_MAX; or set -g VHS_PATH_LEAF_MAX 20
set -q VHS_DIR_CACHE_TTL; or set -g VHS_DIR_CACHE_TTL 30
set -q VHS_AP_MAX_LEN; or set -g VHS_AP_MAX_LEN 4000
set -q VHS_DIR_STATS; or set -g VHS_DIR_STATS 1
set -g fish_greeting
set -g fish_escape_delay_ms 150
set -g fish_sequence_key_delay_ms 150
set -g fish_cursor_default block
set -g fish_cursor_insert line
set -g fish_cursor_visual block
set -g fish_cursor_replace_one underscore
set -g fish_cursor_replace underscore

##### Aliases and tools
if type -q eza
    alias ls eza
    alias ll 'eza -l'
    alias la 'eza -la'
    alias tree 'eza --tree --level=3'
else if test (uname) = Darwin
    alias ls 'ls -G'
else
    alias ls 'ls --color=auto'
end
alias rm 'rm -i'
alias cp 'cp -i'
alias mv 'mv -i'
alias l ls
alias e nvim
alias h history
alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'
alias g git
alias gs 'git status -sb'
alias gb 'git branch --show-current'
alias gl 'git log --oneline --decorate --graph --max-count=15'
alias gf 'git fetch --prune'
alias ga 'git add -p'
alias gr 'git restore'
alias gp 'git push'
function ta
    command tmux attach $argv; or command tmux new
end
function config
    command git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" $argv
end
if type -q zoxide
    zoxide init fish | source
end

##### Clipboard — fish detects the platform backend
function copy --description 'Copy stdin or file contents to the system clipboard'
    if set -q argv[1]
        command cat -- $argv | fish_clipboard_copy
        set -l codes $pipestatus
        for code in $codes
            test "$code" -eq 0; or return "$code"
        end
    else
        fish_clipboard_copy
    end
end
# Keep p/P as raw system-clipboard pastes with vi cursor positioning.
# string collect -N preserves trailing newlines; a sentinel detects failure.
function __vhs_paste --argument-names where
    set -l payload (begin
        fish_clipboard_paste
        set -l rc $status
        printf '\x1f%s' $rc
    end | string collect --no-trim-newlines)
    set -l text ''
    if not string match -rq '(?s)^(?<text>.*)\x1f0$' -- "$payload"
        printf '\a'
        commandline -f repaint
        return 1
    end
    test -n "$text"; or return
    set -l pos (commandline -C)
    set -l buffer (commandline -b | string collect)
    if test "$where" = after; and test "$pos" -lt (string length -- "$buffer")
        set pos (math "$pos + 1")
    end
    commandline -C "$pos"
    commandline -i -- "$text"
    commandline -C (math "$pos + "(string length -- "$text")" - 1")
    commandline -f repaint
end

##### Helpers
function mkcd
    set -q argv[1]; or return 1
    command mkdir -p -- "$argv[1]"; and cd -- "$argv[1]"
end
function extract
    if not set -q argv[1]; or not test -f "$argv[1]"
        printf 'Not a file: %s\n' "$argv[1]" >&2
        return 1
    end
    # Prefix relative paths so filenames beginning with '-' are not options.
    set -l file "$argv[1]"
    string match -q '/*' -- "$file"; or set file "./$file"
    switch "$file"
        case '*.tar.bz2' '*.tbz2'
            command tar xjf "$file"
        case '*.tar.gz' '*.tgz'
            command tar xzf "$file"
        case '*.tar.xz' '*.txz'
            command tar xJf "$file"
        case '*.tar'
            command tar xf "$file"
        case '*.zip'
            command unzip -q "$file"
        case '*.rar'
            command unrar x -idq "$file"
        case '*'
            printf 'Unknown archive: %s\n' "$file" >&2
            return 1
    end
end
# One argument is a fish expression; multiple arguments are escaped literally.
# watch -n 1 'ps aux | string match "*python*"'
# watch -- bash -c 'your Bash pipeline here'
# Evaluates in this shell, retaining aliases/functions. Changes such as cd persist.
function watch
    argparse -s 'n/interval=' t/no-title -- $argv; or return 2
    set -l interval 2
    set -q _flag_interval; and set interval "$_flag_interval"
    if not string match -rq '^[0-9]+(\.[0-9]+)?$' -- "$interval"
        printf 'watch: interval must be a positive number\n' >&2
        return 2
    end
    if not test "$interval" -gt 0
        printf 'watch: interval must be a positive number\n' >&2
        return 2
    end
    if not set -q argv[1]
        printf 'usage: watch [-n seconds] [-t] [--] command\n' >&2
        return 2
    end
    set -l expression "$argv[1]"
    if test (count $argv) -gt 1
        set expression (string join ' ' -- (string escape -- $argv))
    end
    while true
        printf '\e[H\e[2J'
        if not set -q _flag_no_title
            set_color --bold
            printf watch
            set_color normal
            set_color cyan
            printf '  %ss' "$interval"
            set_color yellow
            printf '  %s' (date '+%Y-%m-%d %H:%M:%S')
            set_color magenta
            printf '  %s\n' "$hostname"
            set_color blue
            string repeat -n $COLUMNS -- -
            set_color normal
        end
        eval "$expression"
        set -l rc $status
        if not set -q _flag_no_title
            printf '\n'
            if test "$rc" -eq 0
                set_color green
            else
                set_color red
            end
            printf 'exit: %s\n' "$rc"
            set_color normal
        end
        command sleep "$interval"; or return
    end
end

##### Quote pairing — small, local implementation; no plugin
function __vhs_quote --argument-names quote
    set -l buffer (commandline -b | string collect)
    set -l pos (commandline -C)
    set -l prev ''
    set -l next (string sub -s (math "$pos + 1") -l 1 -- "$buffer")
    test "$pos" -gt 0; and set prev (string sub -s "$pos" -l 1 -- "$buffer")
    if test (string length -- "$buffer") -gt "$VHS_AP_MAX_LEN"; or test "$prev" = '\\'; or commandline --paging-mode
        commandline -i -- "$quote"
    else if test "$next" = "$quote"
        commandline -C (math "$pos + 1")
    else if test "$prev" = '='; and not string match -rq '^[[:alnum:]_]$' -- "$next"
        commandline -i -- "$quote$quote"
        commandline -C (math "$pos + 1")
    else if string match -rq '^[[:alnum:]_)\]}\\.=]$' -- "$prev"; or string match -rq '^[[:alnum:]_/~]$' -- "$next"
        commandline -i -- "$quote"
    else
        commandline -i -- "$quote$quote"
        commandline -C (math "$pos + 1")
    end
    commandline -f repaint
end
function __vhs_backspace
    set -l buffer (commandline -b | string collect)
    set -l pos (commandline -C)
    if test "$pos" -gt 0
        set -l pair (string sub -s "$pos" -l 2 -- "$buffer")
        if contains -- "$pair" "''" '""'
            commandline -f backward-delete-char delete-char repaint
            return
        end
    end
    commandline -f backward-delete-char
end
function __vhs_first_tab
    if test -z (commandline -b | string collect)
        commandline -r 'cd '
    end
    commandline -f complete
end
function fish_user_key_bindings
    bind -M insert \cp up-or-search
    bind -M insert \cn down-or-search
    bind -M insert \cv fish_clipboard_paste
    bind -M insert \ci __vhs_first_tab
    # Fish 4 uses comma-separated named sequences; 3.x uses raw sequences.
    if test (string split . -- $version)[1] -ge 4
        bind -M insert -m default j,k backward-char repaint-mode
        bind -M insert -m default k,j backward-char repaint-mode
    else
        bind -M insert -m default jk backward-char repaint-mode
        bind -M insert -m default kj backward-char repaint-mode
    end
    bind -M insert "'" '__vhs_quote "\'"'
    bind -M insert '"' "__vhs_quote '\"'"
    bind -M insert \x7f __vhs_backspace
    bind -M insert \ch __vhs_backspace
    bind -M default p '__vhs_paste after'
    bind -M default P '__vhs_paste before'
    bind -M default / history-search-forward
    bind -M default '?' history-search-backward
    bind -M default R history-pager
end
fish_vi_key_bindings
fish_user_key_bindings
# Empty mode prompt makes fish repaint the main prompt on vi-mode changes.
function fish_mode_prompt
end

##### Adaptive path — preserve every directory, shorten each middle
# All prompt text is sanitized BEFORE measuring. Widths are terminal cells.
function __vhs_clean --argument-names value
    string replace -a \n '↵' -- "$value" | string replace -a \t '⇥' | string replace -ar '[\x00-\x1f\x7f]' ''
end
function __vhs_middle --argument-names value cap
    if test (string length --visible -- "$value") -le "$cap"
        printf '%s' "$value"
        return
    end
    if test "$cap" -le 1
        string shorten --max "$cap" --char='' -- "$value"
        return
    end
    set -l left_width (math "floor($cap / 2)")
    set -l right_width (math "$cap - $left_width - 1")
    set -l left (string shorten --max "$left_width" --char='' -- "$value")
    set -l right ''
    if test "$right_width" -gt 0
        set right (string shorten --left --max "$right_width" --char='' -- "$value")
    end
    printf '%s…%s' "$left" "$right"
end
function __vhs_shorten_path --argument-names full budget
    set -l prefix ''
    if test "$full" = "$HOME"
        printf '~'
        return
    else if string match -q -- "$HOME/*" "$full"
        set prefix '~/'
        set full (string sub -s (math (string length -- "$HOME")" + 2") -- "$full" | string collect)
    else if string match -q '/*' -- "$full"
        set prefix /
        set full (string sub -s 2 -- "$full" | string collect)
    end
    if test -z "$full"
        printf '%s' "$prefix"
        return
    end
    set full (__vhs_clean "$full" | string collect)
    set -l parts (string split / -- "$full")
    set -l n (count $parts)
    set -l caps
    set -l total (math (string length --visible -- "$prefix")" + $n - 1")
    for i in (seq "$n")
        set -l cap "$VHS_PATH_PARENT_MAX"
        test "$i" -eq "$n"; and set cap "$VHS_PATH_LEAF_MAX"
        set cap (math "max(3, $cap)")
        set cap (math "min($cap, "(string length --visible -- "$parts[$i]")")")
        set -a caps "$cap"
        set total (math "$total + $cap")
    end
    if test -n "$budget"; and test "$budget" -gt 0; and test "$total" -gt "$budget"
        for stage in 1 2 3 4 5
            while test "$total" -gt "$budget"
                set -l pick 0
                if contains -- "$stage" 2 4
                    set -l floor 12
                    test "$stage" -eq 4; and set floor 8
                    test "$caps[$n]" -gt "$floor"; and set pick "$n"
                else
                    set -l floor 5
                    test "$stage" -eq 3; and set floor 3
                    test "$stage" -eq 5; and set floor 1
                    set -l best 0
                    if test "$n" -gt 1
                        for i in (seq (math "$n - 1"))
                            if test "$caps[$i]" -gt "$floor"; and test "$caps[$i]" -gt "$best"
                                set best "$caps[$i]"
                                set pick "$i"
                            end
                        end
                    end
                end
                test "$pick" -gt 0; or break
                set caps[$pick] (math "$caps[$pick] - 1")
                set total (math "$total - 1")
            end
            test "$total" -le "$budget"; and break
        end
    end
    set -l compact
    for i in (seq "$n")
        set -a compact (__vhs_middle "$parts[$i]" "$caps[$i]" | string collect)
    end
    printf '%s%s' "$prefix" (string join / -- $compact)
end

##### Directory statistics — direct regular files, including hidden; no symlinks
# Directory timestamp + TTL cache, bounded to 64 directories.
# Content changes can remain cached for up to VHS_DIR_CACHE_TTL seconds.
# Uses platform stat/find/awk, not Python or an extra package.
set -g __vhs_cache_keys
set -g __vhs_cache_stamps
set -g __vhs_cache_times
set -g __vhs_cache_values
set -g __vhs_dir_info '0 | 0 B'
if command stat -c '%d:%i:%Y:%Z' . >/dev/null 2>&1
    set -g __vhs_stat_style gnu
else
    set -g __vhs_stat_style bsd
end
function __vhs_stamp
    if test "$__vhs_stat_style" = gnu
        command stat -c '%d:%i:%Y:%Z' -- . 2>/dev/null
    else
        command stat -f '%d:%i:%m:%c' . 2>/dev/null
    end
end
function __vhs_directory_info --on-event fish_prompt
    if test "$VHS_DIR_STATS" -eq 0
        set -g __vhs_dir_info 'stats off'
        return
    end
    set -l stamp (__vhs_stamp)
    if not test -r .; or not test -x .; or test -z "$stamp"
        set -g __vhs_dir_info '? | ?'
        return
    end
    set -l now (date +%s)
    set -l index (contains -i -- "$PWD" $__vhs_cache_keys)
    if test -n "$index"
        if test "$stamp" = "$__vhs_cache_stamps[$index]"; and test (math "$now - $__vhs_cache_times[$index]") -lt "$VHS_DIR_CACHE_TTL"
            set -g __vhs_dir_info "$__vhs_cache_values[$index]"
            return
        end
    end
    set -l stat_args -c %s --
    test "$__vhs_stat_style" = bsd; and set stat_args -f %z
    set -l scan (begin
        command find . ! -name . -prune -type f -exec stat $stat_args '{}' + 2>/dev/null | command awk '
            /^[0-9]+$/ { n++; bytes += $0 }
            END {
                if (bytes < 1024) size = sprintf("%.0f B", bytes)
                else if (bytes < 1048576) size = sprintf("%.1f KiB", bytes/1024)
                else if (bytes < 1073741824) size = sprintf("%.1f MiB", bytes/1048576)
                else size = sprintf("%.1f GiB", bytes/1073741824)
                printf "%d | %s\n", n, size
            }'
        printf '%s\n' $pipestatus
    end)
    set -g __vhs_dir_info "$scan[1]"
    if test "$scan[2]" -ne 0; or test "$scan[3]" -ne 0
        set -g __vhs_dir_info "$__vhs_dir_info : partial"
        return
    end
    if test "$stamp" = (__vhs_stamp)
        if test -z "$index"
            if test (count $__vhs_cache_keys) -ge 64
                set -g __vhs_cache_keys
                set -g __vhs_cache_stamps
                set -g __vhs_cache_times
                set -g __vhs_cache_values
            end
            set index (math (count $__vhs_cache_keys)' + 1')
        end
        set -g __vhs_cache_keys[$index] "$PWD"
        set -g __vhs_cache_stamps[$index] "$stamp"
        set -g __vhs_cache_times[$index] "$now"
        set -g __vhs_cache_values[$index] "$__vhs_dir_info"
    end
end

##### VHS prompt — named ANSI colors follow the terminal theme
function fish_prompt
    set -l last_status $status
    set -l mode '● INS'
    set -l color green
    switch "$fish_bind_mode"
        case default replace replace_one
            set mode '■ NOR'
            set color yellow
        case visual
            set mode '▶ VIS'
            set color magenta
    end
    set -l stats (string replace ' | ' ' · ' -- "$__vhs_dir_info")
    set stats "≡ $stats"
    set -l error ''
    test "$last_status" -ne 0; and set error " ── ✗ $last_status"
    set -l width 80
    set -q COLUMNS; and set width "$COLUMNS"
    set -l path (__vhs_shorten_path "$PWD" | string collect)
    set -l budget (math "$width - 14 - 8 - 8 - "(string length --visible -- "$stats")" - "(string length --visible -- "$error")" - 2")
    set -l narrow 0
    if test "$width" -lt 85; or test (string length --visible -- "$path") -gt "$budget"
        set narrow 1
        set budget (math "max(1, $width - 14 - "(string length --visible -- "$error")" - 2)")
        set path (__vhs_shorten_path "$PWD" "$budget" | string collect)
        # Last resort only: extremely narrow panes may lose leftmost levels.
        set path (string shorten --left --max "$budget" --char='…' -- "$path" | string collect)
    end
    printf '\n'
    set_color blue
    printf '╭─┤ '
    set_color --bold "$color"
    printf '%s' "$mode"
    set_color normal
    set_color blue
    printf ' ├── '
    set_color normal
    if test "$narrow" -eq 0
        printf '%s' (date +%H:%M:%S)
        set_color blue
        printf ' ── '
        set_color normal
    end
    if string match -q '*/*' -- "$path"; and test "$path" != /
        set -l parent (string replace -r '[^/]*$' '' -- "$path")
        set -l leaf (string replace -r '^.*/' '' -- "$path")
        printf '%s' "$parent"
        set_color --bold magenta
        printf '%s' "$leaf"
    else
        set_color --bold magenta
        printf '%s' "$path"
    end
    set_color normal
    if test "$narrow" -eq 0
        set_color blue
        printf ' ── '
        set_color cyan
        printf '%s' "$stats"
        set_color normal
    end
    if test "$last_status" -ne 0
        set_color blue
        printf ' ── '
        set_color --bold red
        printf '✗ %s' "$last_status"
        set_color normal
    end
    if test "$narrow" -eq 1
        printf '\n'
        set_color blue
        printf '│  '
        set_color normal
        printf '%s' (date +%H:%M:%S)
        set_color blue
        printf ' ── '
        # Keep the stats line inside very narrow terminal panes too.
        set_color cyan
        string shorten --max (math "max(1, $width - 16)") -- "$stats"
        set_color normal
    else
        printf '\n'
    end
    set_color --bold "$color"
    printf '╰─❯ '
    set_color normal
end
