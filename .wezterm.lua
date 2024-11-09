local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()
local HOME = os.getenv 'HOME'

config.color_scheme = 'Batman'

-- font
config.font = wezterm.font_with_fallback {
  { family = 'Cascadia Code' },
  { family = 'Hack Nerd Font' },
}
config.font_size = 15
config.window_frame = {
  -- Berkeley Mono for me again, though an idea could be to try a
  -- serif font here instead of monospace for a nicer look?
  font_size = 13,
}

-- tab bar
wezterm.on('update-status', function(window)
  -- Grab the utf8 character for the "powerline" left facing
  -- solid arrow.
  local SOLID_LEFT_ARROW = utf8.char(0xe0b2)

  -- Grab the current window's configuration, and from it the
  -- palette (this is the combination of your chosen colour scheme
  -- including any overrides).
  local color_scheme = window:effective_config().resolved_palette
  local bg = color_scheme.background
  local fg = color_scheme.foreground

  window:set_right_status(wezterm.format {
    -- First, we draw the arrow...
    { Background = { Color = 'none' } },
    { Foreground = { Color = bg } },
    { Text = SOLID_LEFT_ARROW },
    -- Then we draw our text
    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    { Text = ' ' .. wezterm.hostname() .. ' ' },
  })
end)

-- window
config.window_decorations = 'TITLE | RESIZE'
config.macos_window_background_blur = 30
config.window_background_opacity = 0.80
config.window_decorations = 'RESIZE'
config.inactive_pane_hsb = {
  saturation = 0.4, -- Adjust the saturation (0.0 to 1.0)
  brightness = 0.5, -- Adjust the brightness (0.0 to 1.0)
}

-- keys
config.keys = {
  -- Unmap Option+Enter
  { key = 'Enter', mods = 'OPT', action = act.DisableDefaultAssignment },

  -- Sends ESC + b and ESC + f sequence, which is used
  -- for telling your shell to jump back/forward.
  {
    -- When the left arrow is pressed
    key = 'LeftArrow',
    -- With the "Option" key modifier held down
    mods = 'OPT',
    -- Perform this action, in this case - sending ESC + B
    -- to the terminal
    action = act.SendString '\x1bb',
  },
  {
    key = 'RightArrow',
    mods = 'OPT',
    action = act.SendString '\x1bf',
  },

  -- Move to the left/right tab
  { key = 'LeftArrow', mods = 'CMD', action = act.ActivateTabRelative(-1) },
  { key = 'RightArrow', mods = 'CMD', action = act.ActivateTabRelative(1) },

  -- split pane
  { key = 'd', mods = 'CMD', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'd', mods = 'SHIFT|CMD', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- command palette
  { key = 'P', mods = 'CTRL|SHIFT', action = act.ActivateCommandPalette },

  -- activate copy mode
  { key = 'C', mods = 'CMD|SHIFT', action = act.ActivateCopyMode },

  -- enter full screen with cmd+enter
  { key = 'Enter', mods = 'CMD', action = act.ToggleFullScreen },

  -- rotate panes
  -- {
  --   key = 'LeftArrow',
  --   mods = 'OPT',
  --   action = act.Multiple(act.RotatePanes 'CounterClockwise', act.ActivatePaneDirection 'Left'),
  -- },
  -- {
  --   key = 'RightArrow',
  --   mods = 'OPT',
  --   action = act.Multiple { act.RotatePanes 'Clockwise', act.ActivatePaneDirection 'Right' },
  -- },

  -- Open the configuration file with Cmd+,
  {
    key = ',',
    mods = 'SUPER',
    action = act.SpawnCommandInNewTab {
      cwd = wezterm.home_dir,
      args = { HOME .. '/.asdf/shims/nvim', wezterm.config_file },
    },
  },
}

for _, direction in ipairs { 'Left', 'Right', 'Up', 'Down' } do
  -- move between panes
  table.insert(config.keys, { key = direction .. 'Arrow', mods = 'CMD|OPT', action = act.ActivatePaneDirection(direction) })
  -- resize panes
  table.insert(config.keys, { key = direction .. 'Arrow', mods = 'CTRL|CMD', action = act.AdjustPaneSize { direction, 3 } })
end

return config
