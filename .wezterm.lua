-- ~/.wezterm.lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Appearance
config.color_scheme = 'Sakura'
config.font = wezterm.font_with_fallback {
  { family = 'Intel One Mono' },
  { family = 'JetBrains Mono' },
}
config.font_size = 16.0
config.window_background_opacity = 0.75
config.window_decorations = "RESIZE"
config.enable_scroll_bar = true
config.enable_wayland = false
config.warn_about_missing_glyphs = false

-- Padding
config.window_padding = { left = 10, right = 10, top = 10, bottom = 10 }

-- Cursor
config.default_cursor_style = 'BlinkingBlock'
config.cursor_blink_rate = 500
config.force_reverse_video_cursor = true

-- Scrollback
config.scrollback_lines = 10000

-- Bell settings
config.audible_bell = 'Disabled'
config.visual_bell = {
  fade_in_function = 'EaseIn',
  fade_out_function = 'EaseOut',
  fade_in_duration_ms = 75,
  fade_out_duration_ms = 150,
}

-- Tab bar
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = true
config.colors = {
  tab_bar = {
    background = '#282828',
    active_tab = {
      bg_color = '#458588',
      fg_color = '#ffffff',
      intensity = 'Bold',
    },
    inactive_tab = {
      bg_color = '#3c3836',
      fg_color = '#a89984',
    },
  },
}

-- Inactive pane visibility
config.inactive_pane_hsb = {
  saturation = 0.9,
  brightness = 0.6,
}

-- Keybindings (Vim-style splits + Tab management)
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

-- Disable auto-updates (if managed manually)
config.check_for_updates = false

return config
