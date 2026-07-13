---@type Wezterm
local wezterm = require 'wezterm'
local act = wezterm.action

local config = wezterm.config_builder()
local HOME = os.getenv 'HOME'

config.color_scheme = 'Rosé Pine Moon (Gogh)'

-- performance
config.max_fps = 120
config.animation_fps = 120
config.front_end = 'WebGpu'
config.webgpu_power_preference = 'HighPerformance'
config.scrollback_lines = 10000

-- font
-- ligatures: != === ---- ~~ ~> ~~> => ==> -> --> <-- <- <== <~ <~~ << >> <= >=
config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }
config.font = wezterm.font_with_fallback { { family = 'CaskaydiaCove Nerd Font' } }
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
  font = wezterm.font { family = 'Roboto', weight = 'Bold' },
  font_size = 14.0,
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
    inactive_tab_hover = {
      bg_color = '#3B3B3A',
      fg_color = '#C0C0C0',
    },
  },
}

-- window
config.window_decorations = 'RESIZE'
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
local wallpaper_path = HOME .. '/Pictures/wallpaperflare1.jpg'
local wallpaper_file = io.open(wallpaper_path, 'r')
if wallpaper_file then
  wallpaper_file:close()
  config.background = {
    {
      source = {
        File = wallpaper_path,
      },
      repeat_y = 'NoRepeat',
      hsb = {
        brightness = 0.18,
        hue = 1.0,
        saturation = 1.0,
      },
      height = 'Cover',
      width = 'Cover',
      opacity = 1.0,
    },
  }
  config.macos_window_background_blur = 50
end

-- mouse
config.mouse_bindings = {
  {
    event = { Down = { streak = 3, button = 'Left' } },
    action = act.SelectTextAtMouseCursor 'SemanticZone',
    mods = 'NONE',
  },
}

-- keys
config.keys = { -- Unmap Option+Enter
  { key = 'Enter', mods = 'OPT', action = act.DisableDefaultAssignment },
  -- selene: allow(bad_string_escape)
  { key = 'Enter', mods = 'SHIFT', action = wezterm.action { SendString = '\x1b\r' } },

  -- split pane
  { key = 'd', mods = 'CMD', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'd', mods = 'SHIFT|CMD', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- command palette
  { key = 'P', mods = 'CTRL|SHIFT', action = act.ActivateCommandPalette },

  -- activate copy mode
  { key = 'C', mods = 'CMD|SHIFT', action = act.ActivateCopyMode },

  -- copy the last command's output straight to the clipboard (no selection needed)
  {
    key = 'O',
    mods = 'CMD|SHIFT',
    action = wezterm.action_callback(function(window, pane)
      local zones = pane:get_semantic_zones 'Output'
      if #zones == 0 then
        return
      end
      local text = pane:get_text_from_semantic_zone(zones[#zones])
      window:copy_to_clipboard(text, 'Clipboard')
    end),
  },

  -- enter full screen with cmd+enter
  { key = 'Enter', mods = 'CMD', action = act.ToggleFullScreen },

  -- kill pane
  { key = 'w', mods = 'CMD', action = act.CloseCurrentPane { confirm = true } },

  -- increase/decrease font size by cmd+/-/=
  { key = '+', mods = 'CMD', action = act.IncreaseFontSize },

  -- clear terminal with cmd+shift+l (same as ctrl+l)
  { key = 'l', mods = 'CMD|SHIFT', action = act.SendKey { key = 'l', mods = 'CTRL' } },

  -- scroll to last command with shift+up/down
  { key = 'UpArrow', mods = 'SHIFT', action = act.ScrollToPrompt(-1) },
  { key = 'DownArrow', mods = 'SHIFT', action = act.ScrollToPrompt(1) },
}

-- copy mode: extend the defaults with vim/tmux-style search and a copy that
-- keeps you in copy mode (so you don't lose your scroll position)
local copy_mode = wezterm.gui.default_key_tables().copy_mode
for _, extra in ipairs {
  -- '/' starts an incremental search, like vim/tmux
  { key = '/', mods = 'NONE', action = act.Search 'CurrentSelectionOrEmptyString' },
  -- jump between matches after closing the search bar with Esc
  { key = 'n', mods = 'NONE', action = act.CopyMode 'NextMatch' },
  { key = 'N', mods = 'NONE', action = act.CopyMode 'PriorMatch' },
  -- Shift+Y copies but STAYS in copy mode, keeping the cursor where it is
  -- (plain 'y' still copies and exits, like before)
  { key = 'Y', mods = 'NONE', action = act.CopyTo 'ClipboardAndPrimarySelection' },
} do
  table.insert(copy_mode, extra)
end

-- search mode: make Enter accept the pattern and drop back into copy mode at the
-- current match (default Enter just jumps to the prior match and keeps you stuck
-- in the search bar). n/N then navigate matches; Esc bails out.
-- NOTE: in the raw table Enter is stored as 'mapped:\r' (show-keys renders it as
-- 'Enter'), so match both spellings.
local search_mode = wezterm.gui.default_key_tables().search_mode
for _, entry in ipairs(search_mode) do
  local is_enter = entry.key == 'Enter' or entry.key == 'mapped:\r'
  if is_enter and (entry.mods == 'NONE' or entry.mods == nil) then
    entry.action = act.CopyMode 'AcceptPattern'
  end
end

config.key_tables = { copy_mode = copy_mode, search_mode = search_mode }

-- QuickSelect: the closest thing wezterm has to vim-easymotion. It labels every
-- on-screen match of the patterns below with a home-row key; typing the label
-- copies the match (add SHIFT/`quick_select_args` to open it instead). These
-- patterns are added on top of the built-in URL/path/email matchers.
-- config.quick_select_alphabet = 'asdfghjklqwertyuiopzxcvbnm'
-- NOTE: wezterm compiles every entry into one big alternation regex that relies
-- on its own capture groups to tell which pattern matched. Any *capturing* group
-- in a pattern shifts those indices and silently breaks matching for the
-- patterns that follow it, so all groups here MUST be non-capturing `(?:...)`.
config.quick_select_patterns = {
  -- IPv4 addresses (optionally with a port)
  '\\b\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}(?::\\d+)?\\b',
  -- git hashes (short or full)
  '\\b[0-9a-f]{7,40}\\b',
  -- UUIDs
  '\\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\\b',
  -- hex colors
  '#[0-9a-fA-F]{6,8}\\b',
  -- k8s pod/replicaset-style names: 3+ hyphen-separated lowercase segments
  -- (e.g. dashboard-gateway-59b4c4985b-mmwhh)
  '\\b[a-z0-9]+(?:-[a-z0-9]+){2,}\\b',
  -- absolute/relative/home file paths
  '[.~]?/[^\\s"\'`|:]+',
  -- single/double quoted strings (match includes the quotes)
  '"(?:[^"]+)"',
  "'(?:[^']+)'",
  -- long numbers (ports, PIDs, timestamps)
  '\\b\\d{4,}\\b',
}
-- easymotion-style label styling
config.colors.quick_select_label_bg = { Color = '#eb6f92' }
config.colors.quick_select_label_fg = { Color = '#191724' }
config.colors.quick_select_match_bg = { Color = '#2a2837' }
config.colors.quick_select_match_fg = { Color = '#e0def4' }

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

-- Move a freshly spawned tab right next to the tab that requested it.
-- Triggered by nvim's :RunInTab, which emits an OSC SetUserVar from the new
-- pane carrying the source (nvim) pane id. wezterm's CLI cannot reorder tabs,
-- so the reordering has to happen here via the GUI MoveTab action.
wezterm.on('user-var-changed', function(window, pane, name, value)
  if name ~= 'runintab_after' then
    return
  end
  local src_pane = tonumber(value)
  if not src_pane then
    return
  end

  local new_tab_id = pane:tab():tab_id()
  local src_index, new_index
  for _, item in ipairs(window:mux_window():tabs_with_info()) do
    if item.tab:tab_id() == new_tab_id then
      new_index = item.index
    end
    for _, p in ipairs(item.tab:panes()) do
      if p:pane_id() == src_pane then
        src_index = item.index
      end
    end
  end
  if not src_index or not new_index then
    return
  end

  local target = src_index + 1
  if new_index == target then
    return
  end
  window:perform_action(act.ActivateTab(new_index), pane)
  window:perform_action(act.MoveTab(target), pane)
end)

local smart_splits = wezterm.plugin.require 'https://github.com/mrjones2014/smart-splits.nvim'
smart_splits.apply_to_config(config, {
  direction_keys = { 'h', 'j', 'k', 'l' },
  modifiers = {
    move = 'CTRL',
    resize = 'META',
  },
  log_level = 'info',
})

return config
