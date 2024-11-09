local wez = require 'wezterm'
local act = wez.action
local config = wez.config_builder()
local HOME = os.getenv 'HOME'

local color = 'Batman'
config.color_scheme = color

-- font
config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }
config.font = wez.font_with_fallback {
  { family = 'Cascadia Code NF' },
}
config.font_size = 15
config.custom_block_glyphs = false
config.window_frame = {
  font_size = 13,
}

-- window
config.window_decorations = 'TITLE | RESIZE'
config.macos_window_background_blur = 30
config.window_background_opacity = 0.80
config.window_decorations = 'RESIZE'
config.inactive_pane_hsb = {
  saturation = 0.4, -- Adjust the saturation (0.0 to 1.0)
  brightness = 0.5, -- Adjust the brightness (0.0 to 1.0)
}
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}
-- wallpaper
-- The art is a bit too bright and colorful to be useful as a backdrop
-- for text, so we're going to dim it down to 10% of its normal brightness
local dimmer = { brightness = 0.1 }

config.enable_scroll_bar = true
config.min_scroll_bar_height = '2cell'
config.colors = {
  scrollbar_thumb = 'white',
}
config.background = {
  -- This is the deepest/back-most layer. It will be rendered first
  {
    source = {
      File = '/Alien_Ship_bg_vert_images/Backgrounds/spaceship_bg_1.png',
    },
    -- The texture tiles vertically but not horizontally.
    -- When we repeat it, mirror it so that it appears "more seamless".
    -- An alternative to this is to set `width = "100%"` and have
    -- it stretch across the display
    repeat_x = 'Mirror',
    hsb = dimmer,
    -- When the viewport scrolls, move this layer 10% of the number of
    -- pixels moved by the main viewport. This makes it appear to be
    -- further behind the text.
    attachment = { Parallax = 0.1 },
  },
  -- Subsequent layers are rendered over the top of each other
  {
    source = {
      File = '/Alien_Ship_bg_vert_images/Overlays/overlay_1_spines.png',
    },
    width = '100%',
    repeat_x = 'NoRepeat',

    -- position the spins starting at the bottom, and repeating every
    -- two screens.
    vertical_align = 'Bottom',
    repeat_y_size = '200%',
    hsb = dimmer,

    -- The parallax factor is higher than the background layer, so this
    -- one will appear to be closer when we scroll
    attachment = { Parallax = 0.2 },
  },
  {
    source = {
      File = '/Alien_Ship_bg_vert_images/Overlays/overlay_2_alienball.png',
    },
    width = '100%',
    repeat_x = 'NoRepeat',

    -- start at 10% of the screen and repeat every 2 screens
    vertical_offset = '10%',
    repeat_y_size = '200%',
    hsb = dimmer,
    attachment = { Parallax = 0.3 },
  },
  {
    source = {
      File = '/Alien_Ship_bg_vert_images/Overlays/overlay_3_lobster.png',
    },
    width = '100%',
    repeat_x = 'NoRepeat',

    vertical_offset = '30%',
    repeat_y_size = '200%',
    hsb = dimmer,
    attachment = { Parallax = 0.4 },
  },
  {
    source = {
      File = '/Alien_Ship_bg_vert_images/Overlays/overlay_4_spiderlegs.png',
    },
    width = '100%',
    repeat_x = 'NoRepeat',

    vertical_offset = '50%',
    repeat_y_size = '150%',
    hsb = dimmer,
    attachment = { Parallax = 0.5 },
  },
}

-- keys
config.keys = {
  -- Unmap Option+Enter
  { key = 'Enter', mods = 'OPT', action = act.DisableDefaultAssignment },

  -- Sends ESC + b and ESC + f sequence, which is used
  -- for telling your shell to jump back/forward.
  {
    key = 'LeftArrow',
    mods = 'OPT',
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
  { key = 'LeftArrow', mods = 'CTRL|SHIFT', action = act.Multiple { act.RotatePanes 'CounterClockwise', act.ActivatePaneDirection 'Left' } },
  { key = 'RightArrow', mods = 'CTRL|SHIFT', action = act.Multiple { act.RotatePanes 'Clockwise', act.ActivatePaneDirection 'Right' } },

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
end

-------------
-- Plugins --
-------------
local tabline = wez.plugin.require 'https://github.com/michaelbrusegard/tabline.wez'
tabline.setup {
  options = {
    icons_enabled = true,
    theme = color,
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
