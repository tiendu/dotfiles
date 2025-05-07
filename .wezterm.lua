-- ~/.wezterm.lua 
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Appearance settings
config.color_scheme = 'OneHalfDark'  -- or 'Gruvbox Dark', 'Dracula', 'Builtin Solarized Dark'
config.font = wezterm.font_with_fallback {
  weight = 'Bold'
}
config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }  -- Turn off ligatures
config.font_size = 16.0
config.window_background_opacity = 0.8

-- Tab bar customization
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = true
config.colors = {
  tab_bar = {
    background = '#282828',
    active_tab = { bg_color = '#458588', fg_color = '#ffffff', intensity = 'Bold' },
    inactive_tab = { bg_color = '#3c3836', fg_color = '#a89984' },
  },
}

-- Scrollback settings
config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 500  -- milliseconds
config.force_reverse_video_cursor = true
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
config.enable_scroll_bar = true

-- Padding and window settings
config.window_padding = {
  left = 10,
  right = 10,
  top = 10,
  bottom = 10,
}
config.window_decorations = "RESIZE"

-- Improve pane border visibility
config.inactive_pane_hsb = {
  saturation = 0.9,
  brightness = 0.6,
}

-- Visual bell
config.visual_bell = {
  fade_in_function = 'EaseIn',
  fade_out_function = 'EaseOut',
  fade_in_duration_ms = 75,
  fade_out_duration_ms = 150,
}

-- Highlight active pane
config.colors.active_pane_border = '#ffcc00'

return config
