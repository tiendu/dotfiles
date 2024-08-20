local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Appearance settings
config.color_scheme = 'AdventureTime'       -- Set color scheme
config.font = wezterm.font_with_fallback {  -- Set font with fallback options
  'JetBrains Mono',                         -- Primary font
  'Fira Code',                              -- Fallback font
  'Noto Color Emoji',                       -- Emoji support
}
config.font_size = 16.0                     -- Font size
config.window_background_opacity = 0.8      -- Background transparency

-- Tab bar customization
config.hide_tab_bar_if_only_one_tab = true  -- Hide tab bar when only one tab
config.use_fancy_tab_bar = false            -- Disable fancy tab bar for minimalistic look

-- Cursor and Scrollback settings
config.cursor_blink_rate = 500              -- Set cursor blink rate (in ms)
config.scrollback_lines = 10000             -- Set scrollback buffer size

-- Keybindings
config.keys = {
  { key = 't', mods = 'CTRL|SHIFT', action = wezterm.action.SpawnTab 'CurrentPaneDomain' },  -- New tab
  { key = 'w', mods = 'CTRL|SHIFT', action = wezterm.action.CloseCurrentTab { confirm = true } },  -- Close tab
  { key = '"', mods = 'CTRL|SHIFT', action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' } }, -- Split pane vertically
  { key = '%', mods = 'CTRL|SHIFT', action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } }, -- Split pane horizontally
  { key = 'h', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection 'Left' },  -- Move to left pane
  { key = 'l', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection 'Right' }, -- Move to right pane
  { key = 'j', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection 'Down' },  -- Move to lower pane
  { key = 'k', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection 'Up' },    -- Move to upper pane
}

-- General behavior settings
config.check_for_updates = false            -- Disable automatic updates
config.audible_bell = 'Disabled'            -- Disable audible bell
config.enable_wayland = false               -- Disable Wayland support for better compatibility

-- Padding and window settings
config.window_padding = {                   -- Set padding around the terminal
  left = 5,
  right = 5,
  top = 5,
  bottom = 5,
}
config.window_decorations = "RESIZE"        -- Remove title bar and only allow resizing

return config
