local wez = require 'wezterm'
local act = wez.action
local config = wez.config_builder()
local HOME = os.getenv 'HOME'

local color = 'Catppuccin Mocha'
config.color_scheme = color

-- font
config.harfbuzz_features = {
  'calt=1',
  'clig=1',
  'liga=1',
  'zero=1',
  'ss02=1',
  'ss19=1',
}
config.font = wez.font_with_fallback { { family = 'Cascadia Code', weight = 'DemiBold' } }
config.font_size = 15
config.freetype_load_target = 'Normal'
config.custom_block_glyphs = false
config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 500
config.cursor_thickness = 2
config.line_height = 0.9

-- tab bar
config.use_fancy_tab_bar = true
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
config.window_decorations = 'TITLE | RESIZE'
config.window_decorations = 'RESIZE'
config.inactive_pane_hsb = {
  saturation = 0.4,
  brightness = 0.5,
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
      File = HOME .. '/Pictures/wallpaperflare4.jpg',
    },
    repeat_y = 'NoRepeat',
    hsb = {
      brightness = 0.13,
      hue = 1.0,
      saturation = 1.0,
    },
    height = 'Cover',
    width = 'Contain',
    opacity = 0.92,
  },
}
config.macos_window_background_blur = 100

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

  -- Open the configuration file with Cmd+,
  {
    key = ',',
    mods = 'SUPER',
    action = act.SpawnCommandInNewTab {
      cwd = wez.home_dir,
      args = { HOME .. '/.asdf/shims/nvim', wez.config_file },
    },
  },
}

-- arrow keys keybindings
for _, direction in ipairs { 'Left', 'Right', 'Up', 'Down' } do
  -- move between panes
  table.insert(config.keys, { key = direction .. 'Arrow', mods = 'CMD|OPT', action = act.ActivatePaneDirection(direction) })

  -- resize panes
  table.insert(config.keys, { key = direction .. 'Arrow', mods = 'CTRL|CMD', action = act.AdjustPaneSize { direction, 3 } })

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
  end
end

for i = 1, 9 do
  table.insert(config.keys, { key = tostring(i), mods = 'CMD', action = act.ActivateTab(i - 1) })
end

return config
