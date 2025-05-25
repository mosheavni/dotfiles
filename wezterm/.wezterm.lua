local wez = require 'wezterm'
local act = wez.action
local config = wez.config_builder()
local HOME = os.getenv 'HOME'

local color = 'Rosé Pine Moon (Gogh)'
config.color_scheme = color

-- performance
config.max_fps = 240
config.animation_fps = 240
config.front_end = 'WebGpu'
config.webgpu_power_preference = 'HighPerformance'
config.scrollback_lines = 10000

-- font
config.harfbuzz_features = {
  'calt=1',
  'clig=1',
  'liga=1',
  'zero=1',
  'ss02=1',
  'ss19=1',
}
config.font = wez.font_with_fallback { { family = 'CaskaydiaCove Nerd Font', weight = 'DemiBold' } }
config.font_size = 16
config.freetype_load_target = 'Normal'
config.custom_block_glyphs = false
config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 500
config.cursor_thickness = 2
config.line_height = 0.9

-- tab bar
config.use_fancy_tab_bar = true
config.show_close_tab_button_in_tabs = true
config.tab_max_width = 999
config.window_frame = {
  font = wez.font { family = 'Roboto', weight = 'Bold' },
  font_size = 13.0,
}
config.colors = {
  background = '#000000',
  scrollbar_thumb = 'white',
  tab_bar = {
    active_tab = {
      bg_color = '#5B5B5A',
      fg_color = '#FFFFFF',
    },
    inactive_tab = {
      bg_color = '#1B1B1B',
      fg_color = '#808080',
    },
  },
}

-- window
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.inactive_pane_hsb = {
  saturation = 0.4,
  brightness = 0.7,
}
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}
config.enable_scroll_bar = true
config.min_scroll_bar_height = '2cell'
config.native_macos_fullscreen_mode = true

-- background
config.background = {
  {
    source = {
      File = HOME .. '/Pictures/wallpaperflare1.jpg',
    },
    repeat_y = 'NoRepeat',
    hsb = {
      brightness = 0.17,
      hue = 1.0,
      saturation = 1.0,
    },
    height = 'Cover',
    width = 'Contain',
    opacity = 1.0,
  },
}
config.macos_window_background_blur = 50

-- mouse
config.mouse_bindings = {
  {
    event = { Down = { streak = 3, button = 'Left' } },
    action = act.SelectTextAtMouseCursor 'SemanticZone',
    mods = 'NONE',
  },
}

-- keys
config.keys = {
  -- Unmap Option+Enter
  { key = 'Enter', mods = 'OPT', action = act.DisableDefaultAssignment },

  -- split pane
  { key = 'd', mods = 'CMD', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'd', mods = 'SHIFT|CMD', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- command palette
  { key = 'P', mods = 'CTRL|SHIFT', action = act.ActivateCommandPalette },

  -- activate copy mode
  { key = 'C', mods = 'CMD|SHIFT', action = act.ActivateCopyMode },

  -- enter full screen with cmd+enter
  { key = 'Enter', mods = 'CMD', action = act.ToggleFullScreen },

  -- kill pane
  { key = 'w', mods = 'CMD', action = act.CloseCurrentPane { confirm = true } },

  -- increase/decrease font size by cmd+/-/=
  { key = '+', mods = 'CMD', action = act.IncreaseFontSize },
}

-- arrow keys keybindings
for _, direction in ipairs { 'Left', 'Right', 'Up', 'Down' } do
  -- move between panes
  -- table.insert(config.keys, { key = direction .. 'Arrow', mods = 'CMD|OPT', action = act.ActivatePaneDirection(direction) })

  -- resize panes
  -- table.insert(config.keys, { key = direction .. 'Arrow', mods = 'CTRL|CMD', action = act.AdjustPaneSize { direction, 3 } })

  if direction == 'Left' or direction == 'Right' then
    -- Sends ESC + b and ESC + f sequence, which is used
    -- for telling your shell to jump back/forward.
    local letter = direction == 'Left' and 'b' or 'f'
    table.insert(config.keys, {
      key = direction .. 'Arrow',
      mods = 'OPT',
      action = act.SendKey { key = letter, mods = 'OPT' },
    })

    -- Move to the left/right tab
    local relative = direction == 'Left' and -1 or 1
    table.insert(config.keys, { key = direction .. 'Arrow', mods = 'CMD', action = act.ActivateTabRelative(relative) })

    -- rotate panes
    local rotate = direction == 'Left' and 'CounterClockwise' or 'Clockwise'
    table.insert(config.keys, { key = direction .. 'Arrow', mods = 'CTRL|SHIFT', action = act.RotatePanes(rotate) })

    -- move tab to the left/right with cmd+shift+left/right
    table.insert(config.keys, { key = direction .. 'Arrow', mods = 'CMD|SHIFT', action = act.MoveTabRelative(relative) })
  else
    -- scroll up using option+arrow
    table.insert(config.keys, { key = direction .. 'Arrow', mods = 'OPT', action = act.ScrollByPage(direction == 'Up' and -0.2 or 0.2) })

    -- scroll to last command
    table.insert(config.keys, { key = direction .. 'Arrow', mods = 'CMD', action = act.ScrollToPrompt(direction == 'Up' and -1 or 1) })
  end
end

for i = 1, 9 do
  table.insert(config.keys, { key = tostring(i), mods = 'CMD', action = act.ActivateTab(i - 1) })
end

local smart_splits = wez.plugin.require 'https://github.com/mrjones2014/smart-splits.nvim'
smart_splits.apply_to_config(config, {
  -- the default config is here, if you'd like to use the default keys,
  -- you can omit this configuration table parameter and just use
  -- smart_splits.apply_to_config(config)

  -- directional keys to use in order of: left, down, up, right
  direction_keys = { 'h', 'j', 'k', 'l' },
  -- if you want to use separate direction keys for move vs. resize, you
  -- can also do this:
  -- direction_keys = {
  --   move = { 'h', 'j', 'k', 'l' },
  --   resize = { 'LeftArrow', 'DownArrow', 'UpArrow', 'RightArrow' },
  -- },
  -- modifier keys to combine with direction_keys
  modifiers = {
    move = 'CTRL', -- modifier to use for pane movement, e.g. CTRL+h to move left
    resize = 'META', -- modifier to use for pane resize, e.g. META+h to resize to the left
  },
  -- log level to use: info, warn, error
  log_level = 'info',
})

return config
