function fish_prompt
    set -l last_pipestatus $pipestatus
    set -lx __fish_last_status $status
    set -l normal (set_color normal)
    set -l green (set_color green)
    set -q fish_color_status
    or set -g fish_color_status red

    set -l color_cwd $fish_color_cwd

    # Default suffix and color (non-root, success)
    set -l suffix '❯'
    set -l suffix_color (set_color green)

    # Root user?
    if functions -q fish_is_root_user; and fish_is_root_user
        if set -q fish_color_cwd_root
            set color_cwd $fish_color_cwd_root
        end
        set suffix '➤'
        if test $__fish_last_status -eq 0
            set suffix_color (set_color --bold yellow)
        else
            set suffix_color (set_color --bold red)
        end
    else
        # Normal user
        if test $__fish_last_status -ne 0
            set suffix_color (set_color red)
            set suffix '⚠'
        end
    end

    set -l bold_flag --bold
    set -q __fish_prompt_status_generation; or set -g __fish_prompt_status_generation $status_generation
    if test $__fish_prompt_status_generation = $status_generation
        set bold_flag
    end
    set __fish_prompt_status_generation $status_generation
    set -l status_color (set_color $fish_color_status)
    set -l statusb_color (set_color $bold_flag $fish_color_status)
    set -l prompt_status (__fish_print_pipestatus "[" "]" " | " "$status_color" "$statusb_color" $last_pipestatus)

    # Line 1: user@host full-path vcs dir-info status
    echo -n -s (prompt_login) ' ' (set_color $color_cwd) (pwd) $normal (fish_vcs_prompt) ' ' (get_dir_info) ' ' $prompt_status
    echo ""
    echo -n -s $suffix_color$suffix$normal " "
end

