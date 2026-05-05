# ~/.config/fish/config.fish
##### General
set -g fish_greeting ''
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx LESS '-iMQRFX'

##### Tunables
set -g FISH_AP_MAX_LEN 4000

##### PATH
fish_add_path -g "$HOME/.pixi/bin"

test -d "$HOME/miniforge/bin"; and fish_add_path -g "$HOME/miniforge/bin"
test -d /opt/homebrew/bin; and fish_add_path -g /opt/homebrew/bin

for d in /opt/homebrew/opt/*/libexec/gnubin
    test -d "$d"; and fish_add_path -g "$d"
end

for d in /opt/homebrew/opt/*/libexec/gnuman
    test -d "$d"; and set -gx MANPATH "$d" $MANPATH
end

##### Persistent user-added PATH entries
set -g fish_added_paths_file "$HOME/.fish_added_paths"

function a2p --description 'Add directory to PATH permanently and chmod files executable'
    if test (count $argv) -eq 0
        echo "Usage: a2p DIR"
        return 1
    end

    set -l dir (realpath "$argv[1]" 2>/dev/null)

    if not test -d "$dir"
        echo "Directory does not exist: $argv[1]"
        return 1
    end

    if not contains -- "$dir" $PATH
        fish_add_path -g "$dir"
        echo "$dir" >> "$fish_added_paths_file"
        sort -u "$fish_added_paths_file" -o "$fish_added_paths_file"
        echo "Added to PATH: $dir"
    else
        echo "Already in PATH: $dir"
    end

    for file in "$dir"/*
        test -f "$file"; and chmod +x "$file"
    end
end

if test -f "$fish_added_paths_file"
    for line in (cat "$fish_added_paths_file")
        test -d "$line"; and fish_add_path -g "$line"
    end
end

##### Interactive shell only
if status is-interactive

    ##### Syntax highlighting colors
    # Fish already has built-in syntax highlighting.
    # These variables only tune the colors.

    set fish_color_normal white
    set fish_color_command green --bold
    set fish_color_keyword yellow --bold
    set fish_color_quote yellow
    set fish_color_redirection magenta --bold
    set fish_color_end cyan
    set fish_color_error red --bold
    set fish_color_param white
    set fish_color_option cyan
    set fish_color_comment brblack
    set fish_color_operator yellow --bold
    set fish_color_escape cyan
    set fish_color_autosuggestion brblack
    set fish_color_valid_path --underline
    set fish_color_cwd magenta --bold
    set fish_color_cwd_root red --bold
    set fish_color_host normal
    set fish_color_user normal
    set fish_color_cancel red --reverse
    set fish_color_search_match --background=brblack

    ##### Vi mode + keybindings
    function fish_user_key_bindings
        fish_vi_key_bindings

        for seq in jk kj
            bind -M insert $seq '
                if commandline -P
                    commandline -f cancel
                else
                    set fish_bind_mode default
                    commandline -f backward-char force-repaint
                end
            '
        end

        for mode in insert default visual
            bind -M $mode \ck 'history merge; commandline -f up-line'
            bind -M $mode \cj 'history merge; commandline -f down-line'
            bind -M $mode \ch 'commandline -f backward-char'
            bind -M $mode \cl 'commandline -f forward-char'
        end

        # Autopair quotes, insert mode only.
        bind -M insert "'" __fish_ap_single_quote
        bind -M insert '"' __fish_ap_double_quote

        # Smart backspace for empty paired quotes.
        bind -M insert \b __fish_ap_backspace
        bind -M insert \x7f __fish_ap_backspace
    end

    ##### Cursor shape
    set fish_cursor_default block
    set fish_cursor_insert line blink
    set fish_cursor_replace_one underscore
    set fish_cursor_visual block

    ##### Autopair helpers
    function __fish_ap_is_word
        test -n "$argv[1]"; and string match -qr '^[A-Za-z0-9_]$' -- "$argv[1]"
    end

    function __fish_ap_is_closer
        test -n "$argv[1]"; and string match -qr '^[\)\]\}]$' -- "$argv[1]"
    end

    function __fish_ap_is_boundary
        test -z "$argv[1]"; and return 0
        string match -qr '^[[:space:][:punct:]]$' -- "$argv[1]"
    end

    function __fish_ap_insert_pair
        set -l open "$argv[1]"
        set -l close "$argv[2]"

        set -l buf (commandline -b)
        set -l cursor (commandline -C)

        if test (string length -- "$buf") -gt $FISH_AP_MAX_LEN
            commandline -i "$open"
            return
        end

        set -l prev ''
        set -l next ''

        if test "$cursor" -gt 0
            set prev (string sub -s "$cursor" -l 1 -- "$buf")
        end

        set next (string sub -s (math "$cursor + 1") -l 1 -- "$buf")

        # Escaped quote: \" or \'
        if test "$prev" = '\\'
            commandline -i "$open"
            return
        end

        # After assignment: VAR="|"
        if test "$prev" = '='
            if __fish_ap_is_boundary "$next"
                commandline -i "$open$close"
                commandline -C (math (commandline -C) - 1)
                return
            end
        end

        # Do not pair inside words or right after a closer.
        if __fish_ap_is_word "$prev"; or __fish_ap_is_word "$next"; or __fish_ap_is_closer "$prev"
            commandline -i "$open"
            return
        end

        # Pair only at clean boundaries.
        if __fish_ap_is_boundary "$prev"; and __fish_ap_is_boundary "$next"
            commandline -i "$open$close"
            commandline -C (math (commandline -C) - 1)
            return
        end

        commandline -i "$open"
    end

    function __fish_ap_single_quote
        __fish_ap_insert_pair "'" "'"
    end

    function __fish_ap_double_quote
        __fish_ap_insert_pair '"' '"'
    end

    function __fish_ap_backspace
        set -l buf (commandline -b)
        set -l cursor (commandline -C)

        if test "$cursor" -gt 0
            set -l prev (string sub -s "$cursor" -l 1 -- "$buf")
            set -l next (string sub -s (math "$cursor + 1") -l 1 -- "$buf")

            switch "$prev$next"
                case "''" '""'
                    commandline -C (math "$cursor - 1")
                    commandline -f delete-char
                    commandline -f delete-char
                    return
            end
        end

        commandline -f backward-delete-char
    end

    ##### Safer core utils
    alias rm 'rm -i'
    alias cp 'cp -i'
    alias mv 'mv -i'

    ##### Short aliases
    alias l 'ls'
    alias e '_nvim'
    alias ta 'tmux attach || tmux new'
    alias config '/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

    ##### Git aliases
    alias g 'git'
    alias gs 'git status -sb'
    alias gl 'git log --oneline --decorate --graph --max-count=15'
    alias gf 'git fetch --prune'
    alias ga 'git add -p'
    alias gr 'git restore'
    alias gp 'git push'

    ##### Open file with nvim; delete new empty file afterwards
    function _nvim --description 'Open file with nvim, remove if left empty'
        if test (count $argv) -eq 0
            nvim
            return
        end

        set -l file "$argv[1]"

        if not test -e "$file"
            touch "$file"
        end

        nvim "$file"

        if test -f "$file"; and not test -s "$file"
            rm -f "$file"
        end
    end

    ##### mkdir + cd
    function mkcd --description 'Create directory and cd into it'
        test -n "$argv[1]"; or return 1
        mkdir -p -- "$argv[1]"
        cd -- "$argv[1]"
    end

    ##### Extract archives
    function extract --description 'Extract common archive formats'
        set -l file "$argv[1]"

        if not test -f "$file"
            echo "Not a file: $file"
            return 1
        end

        switch "$file"
            case '*.tar.bz2'
                tar xjf "$file"
            case '*.tar.gz' '*.tgz'
                tar xzf "$file"
            case '*.tar.xz' '*.txz'
                tar xJf "$file"
            case '*.zip'
                unzip -q "$file"
            case '*.rar'
                unrar x -idq "$file"
            case '*.7z'
                7z x "$file"
            case '*'
                echo "Unknown archive: $file"
                return 1
        end
    end

    ##### Multi cd: .. ... ....
    function multicd
        echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)
    end

    abbr --add dotdot --regex '^\.\.+$' --function multicd

    ##### sd: fuzzy cd to selected file's directory
    if type -q fzf
        function sd --description 'cd to directory of selected file'
            if type -q fd
                set -l target (fd --type f --hidden --exclude .git | fzf)
            else
                set -l target (find . -type f 2>/dev/null | fzf)
            end

            test -n "$target"; and cd (dirname "$target")
        end
    end

    ##### zoxide
    if type -q zoxide
        zoxide init fish | source
    end

    ##### grep -> ripgrep
    if type -q rg
        alias grep 'rg'
    end

    ##### ls -> eza/exa/fallback
    if type -q eza
        alias ls 'eza --icons'
        alias ll 'eza -l --icons'
        alias la 'eza -la --icons'
        alias tree 'eza --tree --level=2 --icons'
    else if type -q exa
        alias ls 'exa --icons'
        alias ll 'exa -l --icons'
        alias la 'exa -la --icons'
        alias tree 'exa --tree --level=2 --icons'
    else
        switch (uname)
            case Darwin
                alias ls 'ls -G'
            case '*'
                alias ls 'ls --color=auto'
        end

        alias ll 'ls -lh'
        alias la 'ls -lah'
        alias tree 'ls -R'
    end

    ##### Cross-platform clipboard
    switch (uname)
        case Darwin
            # macOS already provides pbcopy/pbpaste.

        case Linux
            if type -q wl-copy
                function pbcopy
                    if test (count $argv) -gt 0
                        cat -- $argv | wl-copy
                    else
                        wl-copy
                    end
                end

                function pbpaste
                    wl-paste
                end

            else if type -q xclip
                function pbcopy
                    if test (count $argv) -gt 0
                        cat -- $argv | xclip -selection clipboard
                    else
                        xclip -selection clipboard
                    end
                end

                function pbpaste
                    xclip -selection clipboard -o
                end

            else if type -q xsel
                function pbcopy
                    if test (count $argv) -gt 0
                        cat -- $argv | xsel --clipboard --input
                    else
                        xsel --clipboard --input
                    end
                end

                function pbpaste
                    xsel --clipboard --output
                end
            end
    end

    ##### Git prompt
    set __fish_git_prompt_show_informative_status true
    set __fish_git_prompt_showcolorhints true
    set __fish_git_prompt_showuntrackedfiles true
    set __fish_git_prompt_showstashstate true

    set __fish_git_prompt_color_flags normal
    set __fish_git_prompt_color_branch cyan
    set __fish_git_prompt_color_stagedstate red
    set __fish_git_prompt_color_dirtystate blue
    set __fish_git_prompt_color_untrackedfiles yellow
    set __fish_git_prompt_color_stashstate white

    ##### Disable default vi mode prompt
    function fish_mode_prompt
    end

    ##### Prompt
    function fish_prompt
        set -l last_status $status
        set -l mode_label

        switch $fish_bind_mode
            case default
                set mode_label (set_color -b yellow white --bold)' NOR '(set_color normal)
            case insert
                set mode_label (set_color -b green white --bold)' INS '(set_color normal)
            case replace_one replace
                set mode_label (set_color -b red white --bold)' REP '(set_color normal)
            case visual
                set mode_label (set_color -b magenta white --bold)' VIS '(set_color normal)
            case '*'
                set mode_label (set_color -b green white --bold)' INS '(set_color normal)
        end

        set -l time_block (set_color -b blue white --bold)" "(date '+%H:%M:%S')" "(set_color normal)
        set -l path_block (set_color magenta --bold)(prompt_pwd)(set_color normal)

        if test $last_status -eq 0
            set -l status_block (set_color -b cyan green --bold)' 0 '(set_color normal)
        else
            set -l status_block (set_color -b cyan red --bold)" $last_status "(set_color normal)
        end

        printf '%s :: %s :: %s :: %s' $mode_label $time_block $path_block $status_block

        set -l git_info (__fish_git_prompt)
        if test -n "$git_info"
            printf ' %s' $git_info
        end

        printf '\n%s#%s ' (set_color white --bold) (set_color normal)
    end
end
