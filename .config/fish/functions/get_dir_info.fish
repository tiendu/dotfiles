function get_dir_info --description 'Show file count and dir size'
    set -l uname (uname)
    switch $uname
        case Darwin
            set block_size 512
        case Linux
            set block_size 1024
        case '*'
            set block_size 512
    end

    set -l blocks (command ls -lA . 2>/dev/null | awk '/^total/ { print $2 }')
    if test -z "$blocks"
        set blocks 0
    end

    set -l bytes (math "$blocks * $block_size")
    set -l size (printf "%.1fK" (math "$bytes / 1024.0"))
    set -l count (ls -A1 | wc -l | string trim)
	set -l cyan (set_color cyan)
	set -l blue (set_color blue)
	set -l magenta (set_color magenta)
	set -l normal (set_color normal)

  echo -n "($cyan$count$normal | $magenta$size$normal)"
end

