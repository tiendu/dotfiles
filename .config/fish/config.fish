# ~/.config/fish/config.fish

##### General
set -g fish_greeting ''
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx LESS '-iMQRFX'

##### PATH
fish_add_path -g "$HOME/.pixi/bin"

if test -d "$HOME/miniforge/bin"
    fish_add_path -g "$HOME/miniforge/bin"
end

if test -d /opt/homebrew/bin
    fish_add_path -g /opt/homebrew/bin
end

for d in /opt/homebrew/opt/*/libexec/gnubin
    test -d "$d"; and fish_add_path -g "$d"
end

##### Added paths persistence
set -g fish_added_paths_file "$HOME/.fish_added_paths"

function a2p --description 'Add directory to PATH and make files executable'
    if test (count $argv) -eq 0
        echo "Usage: a2p DIR"
        return 1
    end

    set -l dir (realpath $argv[1] 2>/dev/null)

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
        if test -f "$file"
            chmod +x "$file"
        end
    end
end

if test -f "$fish_added_paths_file"
    for line in (cat "$fish_added_paths_file")
        test -d "$line"; and fish_add_path -g "$line"
    end
end

##### Interactive only
if status is-interactive

    ##### Vi mode
    fish_vi_key_bindings

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
    end

    ##### Cursor
    set fish_cursor_default block
    set fish_cursor_insert line blink
    set fish_cursor_replace_one underscore
    set fish_cursor_visual block

    ##### Aliases
    alias rm 'rm -i'
    alias cp 'cp -i'
    alias mv 'mv -i'
    alias l 'ls'
    alias g 'git'
    alias gs 'git status -sb'
    alias gl 'git log --oneline --decorate --graph --max-count=15'
    alias gf 'git fetch --prune'
    alias ga 'git add -p'
    alias gr 'git restore'
    alias gp 'git push'
    alias e '_nvim'
    alias ta 'tmux attach || tmux new'
    alias config '/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

    ##### Editor helper
    function _nvim --description 'Open file with nvim, delete if left empty'
        if test (count $argv) -eq 0
            nvim
            return
        end

        set -l file $argv[1]

        if not test -e "$file"
            touch "$file"
        end

        nvim "$file"

        if test -f "$file"; and not test -s "$file"
            rm -f "$file"
        end
    end

    ##### mkcd
    function mkcd
        test -n "$argv[1]"; or return 1
        mkdir -p -- "$argv[1]"
        cd -- "$argv[1]"
    end

    ##### extract
    function extract
        test -f "$argv[1]"; or begin
            echo "Not a file: $argv[1]"
            return 1
        end

        switch "$argv[1]"
            case '*.tar.bz2'
                tar xjf "$argv[1]"
            case '*.tar.gz'
                tar xzf "$argv[1]"
            case '*.tar.xz'
                tar xJf "$argv[1]"
            case '*.zip'
                unzip -q "$argv[1]"
            case '*.rar'
                unrar x -idq "$argv[1]"
            case '*'
                echo "Unknown archive: $argv[1]"
                return 1
        end
    end

    ##### Multi cd: .. ... ....
    function multicd
        echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)
    end

    abbr --add dotdot --regex '^\.\.+$' --function multicd

    ##### sd: cd to selected file's directory
    if type -q fzf
        function sd
            set -l target (find . -type f 2>/dev/null | fzf)
            test -n "$target"; and cd (dirname "$target")
        end
    end

    ##### zoxide
    if type -q zoxide
        zoxide init fish | source
    end

    ##### grep -> rg
    if type -q rg
        alias grep 'rg'
    end

    ##### ls -> eza/exa/fallback
    if type -q eza
        alias ls 'eza --icons'
        alias ll 'eza -l --icons'
        alias la 'eza -la --icons'
        alias tree 'eza --tree --level=2'
    else if type -q exa
        alias ls 'exa --icons'
        alias ll 'exa -l --icons'
        alias la 'exa -la --icons'
        alias tree 'exa --tree --level=2'
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

    ##### Clipboard
    switch (uname)
        case Darwin
            # macOS already has pbcopy/pbpaste

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

    ##### Prompt colors
    set fish_color_cwd white
    set fish_color_command white

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

    ##### Disable default fish vi-mode prompt, because we show mode ourselves
    function fish_mode_prompt
    end

    ##### Prompt: use # instead of >
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
