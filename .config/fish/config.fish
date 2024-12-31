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
    set dir (realpath $argv[1]) # Get the absolute path of the provided directory
    # Check if the directory exists
    if test -d "$dir"
        # Check if the directory is already in PATH
        if not contains -- ":$PATH:" ":$dir:"
            set PATH "$dir:$PATH" # Add the directory to PATH
            echo "$dir" >>"$HOME/.fish_added_paths"
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
if test -f "$HOME/.fish_added_paths"
    while read -l line
        if begin
                test -d "$line"; and ! contains -- "$line" $PATH
            end
            set -g PATH "$line" $PATH
        end
    end <$HOME/.fish_added_paths
end

# Clean PATH
function _clean_path --on-event fish_prompt
    set -l unique_paths
    set -l path_array (string split ':' $PATH)
    for path in $path_array
        if begin
                test -n "$path"; and test -d "$path"; and ! contains -- "$path" $unique_paths
            end
            set unique_paths $unique_paths $path
        end
    end
    # Rebuild the PATH with unique paths
    set -g PATH (string join ':' $unique_paths)
    # Clean up ~/.fish_added_paths to remove duplicates
    if test -e "$HOME/.fish_added_paths"
        sort -u "$HOME/.fish_added_paths" >"$HOME/.fish_added_paths.tmp"
        mv -f "$HOME/.fish_added_paths.tmp" "$HOME/.fish_added_paths"
    end
end

# Aliases for convenience
alias rm "rm -i" # Prompt before removing files
alias cp "cp -i" # Prompt before overwriting files
alias mv "mv -i" # Prompt before overwriting files
alias g git
alias e hx
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
        zoxide init fish | source # Automatically load Zoxide on every new tab or session
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
        if type -q xclip
            alias pbcopy "xclip -selection clipboard"
            alias pbpaste "xclip -selection clipboard -o"
        else if type -q xsel
            alias pbcopy "xsel --clipboard --input"
            alias pbpaste "xsel --clipboard --output"
        else
            echo "Install xclip or xsel for pbcopy/pbpaste."
        end
    case Darwin
end
