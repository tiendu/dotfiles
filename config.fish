# ~/.config/fish/config.fish
# Turn off greeting message
set -g fish_greeting ''

# Enable vi mode
fish_vi_key_bindings

# Map 'jk' and 'kj' to escape from insert mode to normal mode
# Map Ctrl + J/K to navigate in history search
function fish_user_key_bindings
    for seq in jk kj
        bind -M insert $seq 'if commandline -P
                                commandline -f cancel
                            else
                                set fish_bind_mode default
                                commandline -f backward-char force-repaint
                            end'
    end
    for mode in insert default visual
        bind -M $mode \ck 'history --merge; commandline -f up-line'
        bind -M $mode \cj 'history --merge; commandline -f down-line'
        bind -M $mode \ch 'history --merge; commandline -f backward-char'
        bind -M $mode \cl 'history --merge; commandline -f forward-char'
    end
end
fish_user_key_bindings

# Add new directory to PATH
function add2path
    set dir (realpath $argv[1])  # Get the absolute path of the provided directory
    # Check if the directory exists
    if test -d "$dir"
        # Check if the directory is already in PATH
        if not contains -- ":$PATH:" ":$dir:"
            set PATH "$dir:$PATH"  # Add the directory to PATH
            echo "Directory '$dir' added to PATH."
        else
            echo "Directory '$dir' is already in PATH."
        end
        # Make all files in the directory executable
        for file in "$dir"/*
            if test -f "$file" 
                chmod +x "$file"
                if test $status -ne 0
                    echo "Failed to make $file executable."
                end
            end
        end
    else
        echo "Directory '$dir' does not exist."
    end
end

# Clean PATH
function _clean_path
    set NEW_PATH '';  # Initialize NEW_PATH as an empty string
    for dir in (echo "$PATH" | sed 's/:/\n/g')  # Loop through each directory in PATH
        if test -d "$dir"  # Check if the directory exists
            set NEW_PATH "$NEW_PATH:$dir"  # Append the valid directory to NEW_PATH
        end
    end
    set NEW_PATH (echo "$NEW_PATH" | sed 's/^://g')  # Remove the leading colon from NEW_PATH
end
_clean_path

# Create new file with neovim
function _nvim
    set file $argv[1]
    if test ! -e $file
        touch $file
    end
    nvim $file
    if test ! -s $file
        rm -f $file
    end
end

# Aliases for convenience
alias gs "git status"
alias ga "git add"
alias gc "git commit"
alias gp "git push"
alias gl "git log --oneline --graph --all"
alias rm "rm -i"  # Prompt before removing files
alias cp "cp -i"  # Prompt before overwriting files
alias mv "mv -i"  # Prompt before overwriting files
alias e "_nvim"
alias sd "cd ~ && cd (find * -type d | fzf)"

# Multi cd
function multicd
    echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)
end
abbr --add dotdot --regex '^\.\.+$' --function multicd

# History settings
set -g fish_history_size 10000

# Set up Zoxide
function _init_zoxide --on-event fish_prompt
    if type -q zoxide
        zoxide init fish | source  # Automatically load Zoxide on every new tab or session
    end
end

# Replace grep with ripgrep if available
if type -q rg
    alias grep="rg"
end

# Replace ls with exa/eza if available
if type -q exa
    alias ls="exa --icons"
    alias ll="exa -l --icons"
    alias la="exa -la --icons"
    alias tree="exa --tree --level=2"
else if type -q eza
    alias ls="eza --icons"
    alias ll="eza -l --icons"
    alias la="eza -la --icons"
    alias tree="eza --tree --level=2"
else
    alias ls="ls --color=auto"
    alias tree="ls -R"
end

# Alias for cross-platform pbcopy/pbpaste
switch (uname)
    case Linux
        if test -q xclip
            alias pbcopy "xclip -selection clipboard"
            alias pbpaste "xclip -selection clipboard -o"
        else if test -q xsel
            alias pbcopy "xsel --clipboard --input"
            alias pbpaste "xsel --clipboard --output"
        else
            echo "Install xclip or xsel for pbcopy/pbpaste."
        end
    case Darwin
end
