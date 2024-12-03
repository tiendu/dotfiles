-- ~/.wezterm.lua 
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Appearance settings
config.color_scheme = 'Dracula (Official)'
config.font = wezterm.font_with_fallback {
  weight = 'Bold'
}
config.font_size = 16.0
config.window_background_opacity = 0.9

-- Tab bar customization
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = true
config.colors = {
  tab_bar = {
    background = '#282828',
    active_tab = { bg_color = '#458588', fg_color = '#ebdbb2' },
    inactive_tab = { bg_color = '#3c3836', fg_color = '#a89984' },
  },
}

-- Cursor and Scrollback settings
config.default_cursor_style = 'SteadyBlock'
config.scrollback_lines = 10000

-- Keybindings
config.keys = {
  { key = 't', mods = 'CTRL|SHIFT', action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CTRL|SHIFT', action = wezterm.action.CloseCurrentTab { confirm = true } },
  { key = '"', mods = 'CTRL|SHIFT', action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = '%', mods = 'CTRL|SHIFT', action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'h', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection 'Left' },
  { key = 'l', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection 'Right' },
  { key = 'j', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection 'Up' },
}

-- General behavior settings
config.check_for_updates = false
config.audible_bell = 'Disabled'
config.enable_wayland = false

-- Padding and window settings
config.window_padding = {
  left = 10,
  right = 10,
  top = 10,
  bottom = 10,
}
config.window_decorations = "RESIZE"

return config
