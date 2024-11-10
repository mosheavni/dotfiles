local wez = require 'wezterm'
local act = wez.action
local config = wez.config_builder()
local HOME = os.getenv 'HOME'

local color = 'Catppuccin Mocha'
config.color_scheme = color

-- font
config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }
config.font = wez.font_with_fallback { { family = 'Cascadia Code', weight = 'DemiBold' } }
config.font_size = 15
config.freetype_load_target = 'Normal'
config.custom_block_glyphs = false
config.window_frame = {
  font_size = 13,
}

-- window
config.window_decorations = 'TITLE | RESIZE'
config.window_decorations = 'RESIZE'
config.inactive_pane_hsb = {
  saturation = 0.4,
  brightness = 0.5,
}
config.window_padding = {
  left = 59,
  right = 0,
  top = 0,
  bottom = 0,
}
config.enable_scroll_bar = true
config.min_scroll_bar_height = '2cell'
config.native_macos_fullscreen_mode = true
config.colors = {
  scrollbar_thumb = 'white',
}

-- background
config.background = {
  {
    source = {
      File = '/Users/mavni/Pictures/wallpaperflare1.jpg',
    },
    repeat_y = 'NoRepeat',
    hsb = {
      brightness = 0.16,
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
      action = act.SendString('\x1b' .. letter),
    })

    -- Move to the left/right tab
    local relative = direction == 'Left' and -1 or 1
    table.insert(config.keys, { key = direction .. 'Arrow', mods = 'CMD', action = act.ActivateTabRelative(relative) })

    -- rotate panes
    local rotate = direction == 'Left' and 'CounterClockwise' or 'Clockwise'
    table.insert(config.keys, { key = direction .. 'Arrow', mods = 'CTRL|SHIFT', action = act.RotatePanes(rotate) })
  end
end

for i = 1, 9 do
  table.insert(config.keys, { key = tostring(i), mods = 'CMD', action = act.ActivateTab(i - 1) })
end

-------------
-- Plugins --
-------------
local tabline = wez.plugin.require 'https://github.com/michaelbrusegard/tabline.wez'
tabline.setup {
  options = {
    icons_enabled = true,
    theme = color,
    -- color_overrides = {
    --   normal_mode = {
    --     a = { fg = '#181825', bg = '#89b4fa' },
    --     b = { fg = '#89b4fa', bg = '#313244' },
    --     c = { fg = '#cdd6f4', bg = '#181825' },
    --   },
    --   tab = {
    --     active = { fg = '#89b4fa', bg = '#313244' },
    --     inactive = { fg = '#cdd6f4', bg = '#181825' },
    --     inactive_hover = { fg = '#f5c2e7', bg = '#313244' },
    --   },
    -- },
  },
  sections = {
    tabline_a = { ' MOSH ' },
    tabline_b = { 'battery' },
    tabline_c = {},
    -- iri == biri
    tab_active = {
      'index',
      { 'parent', padding = 0 },
      '/',
      { 'cwd', padding = { left = 0, right = 1 } },
      { 'zoomed', padding = 0 },
    },
    tab_inactive = { 'index', { 'process', padding = { left = 0, right = 1 } } },
    tabline_x = { 'ram', 'cpu' },
    tabline_y = { 'datetime' },
    tabline_z = { 'hostname' },
  },
  extensions = {},
}
tabline.apply_to_config(config)

return config
