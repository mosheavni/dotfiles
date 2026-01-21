local M = {}

local utils = require 'user.search-replace-utils'

-- Configuration
local chars = { '/', '?', '#', ':', '@' }
local magic_list = { '\\v', '\\m', '\\M', '\\V', '' }
local available_flags = { 'g', 'c', 'i' }

-- State
local sar_state = {
  active = false,
  cword = '',
  sep = '/',
  magic = '\\V',
}

-- Helper functions
local function should_sar()
  if vim.fn.getcmdtype() ~= ':' then
    return false
  end
  -- Active mode (triggered by <leader>r) or detected substitute command
  if sar_state.active then
    return true
  end
  -- Check if current cmdline looks like a substitute command
  return utils.is_substitute_cmd(vim.fn.getcmdline())
end

-- Get the current separator (from state if active, or parse from cmdline)
local function get_current_sep()
  if sar_state.active then
    return sar_state.sep
  end
  local parsed = utils.parse_substitute_cmd(vim.fn.getcmdline())
  return parsed and parsed.sep or '/'
end

-- Public function to check if search-replace mode is active
function M.is_active()
  return sar_state.active
end

-- Helper to set command and cursor position (called from C-\ e expression)
function M.set_cmd_and_pos()
  vim.fn.setcmdpos(sar_state.cursor_pos)

  -- Trigger dashboard refresh by invalidating cache and simulating a keystroke
  local ok, dashboard = pcall(require, 'user.search-replace-dashboard')
  if ok and dashboard and dashboard.invalidate_cache then
    utils.trigger_cmdline_refresh(dashboard.invalidate_cache)
  end

  return sar_state.new_cmd
end

local function find_unique_char(char_list, str)
  for _, char in ipairs(char_list) do
    if not str:find(vim.pesc(char), 1, true) then
      return char
    end
  end
  return ''
end

-- Main populate function
function M.populate_searchline(mode)
  -- Get word under cursor or visual selection
  if mode == 'n' then
    sar_state.cword = vim.fn.expand '<cword>'
  else
    sar_state.cword = require('user.utils').get_visual_selection()
  end

  -- Find unique separator
  sar_state.sep = find_unique_char(chars, sar_state.cword)
  sar_state.magic = '\\V'

  -- Build command
  local flags = 'gc'
  local cmd = '.,$s' .. sar_state.sep .. sar_state.magic .. sar_state.cword .. sar_state.sep .. sar_state.cword .. sar_state.sep .. flags

  -- Activate search-replace mode (hints will be shown by CmdlineEnter autocmd)
  sar_state.active = true

  -- Return command and cursor movement count (to position cursor at end of replace term)
  local chars_to_move_left = #sar_state.sep + #flags
  return cmd, chars_to_move_left
end

-- Toggle flag (g, c, i)
function M.toggle_char(char)
  local cmd = vim.fn.getcmdline()
  if not should_sar() then
    return ''
  end

  local sep = get_current_sep()
  local parts = utils.normalize_parts(vim.split(cmd, sep, { plain = true }))
  local flags = parts[4]

  -- Toggle the flag
  if flags:find(char) then
    flags = flags:gsub(char, '')
  else
    -- Add flag in correct order
    local new_flags = ''
    for _, flag in ipairs(available_flags) do
      if flags:find(flag) or char == flag then
        new_flags = new_flags .. flag
      end
    end
    flags = new_flags
  end

  parts[4] = flags
  local new_cmd = table.concat(parts, sep)

  -- Store command and cursor position for helper function
  sar_state.new_cmd = new_cmd
  sar_state.cursor_pos = #new_cmd - #sep - #parts[4] + 1

  -- Use <C-\>e to evaluate expression that sets both command and cursor
  return vim.keycode '<C-\\>e' .. 'luaeval(\'require("user.search-replace").set_cmd_and_pos()\')' .. vim.keycode '<CR>'
end

-- Toggle replace term (clear/restore original word)
function M.toggle_replace_term()
  local cmd = vim.fn.getcmdline()
  if not should_sar() then
    return ''
  end

  local sep = get_current_sep()
  local parts = utils.normalize_parts(vim.split(cmd, sep, { plain = true }))
  -- Use stored cword if in active mode, otherwise use search term or empty
  local current_replace = parts[3]
  local search_term = parts[2]
  local replace_term = current_replace == '' and (sar_state.active and sar_state.cword or search_term) or ''
  parts[3] = replace_term

  local new_cmd = table.concat(parts, sep)

  -- Store command and cursor position for helper function
  sar_state.new_cmd = new_cmd
  sar_state.cursor_pos = #new_cmd - #sep - #parts[4] + 1

  -- Use <C-\>e to evaluate expression that sets both command and cursor
  return vim.keycode '<C-\\>e' .. 'luaeval(\'require("user.search-replace").set_cmd_and_pos()\')' .. vim.keycode '<CR>'
end

-- Toggle range (all file)
function M.toggle_all_file()
  local cmd = vim.fn.getcmdline()
  if not should_sar() then
    return ''
  end

  local sep = get_current_sep()
  local parts = utils.normalize_parts(vim.split(cmd, sep, { plain = true }))
  local range = parts[1]

  -- Cycle through ranges: %s -> .,$s -> 0,.s -> %s
  if range == '%s' then
    range = '.,$s'
  elseif range == '.,$s' then
    range = '0,.s'
  else
    range = '%s'
  end

  parts[1] = range
  local new_cmd = table.concat(parts, sep)

  -- Store command and cursor position for helper function
  sar_state.new_cmd = new_cmd
  sar_state.cursor_pos = #new_cmd - #sep - #parts[4] + 1

  -- Use <C-\>e to evaluate expression that sets both command and cursor
  return vim.keycode '<C-\\>e' .. 'luaeval(\'require("user.search-replace").set_cmd_and_pos()\')' .. vim.keycode '<CR>'
end

-- Toggle separator
function M.toggle_separator()
  local cmd = vim.fn.getcmdline()
  if not should_sar() then
    return ''
  end

  local old_sep = get_current_sep()
  local parts = utils.normalize_parts(vim.split(cmd, old_sep, { plain = true }))

  -- Find next separator
  local idx = 0
  for i, c in ipairs(chars) do
    if c == old_sep then
      idx = i
      break
    end
  end
  sar_state.sep = chars[(idx % #chars) + 1]

  local new_cmd = table.concat(parts, sar_state.sep)

  -- Store command and cursor position for helper function
  sar_state.new_cmd = new_cmd
  sar_state.cursor_pos = #new_cmd - #sar_state.sep - #parts[4] + 1

  -- Use <C-\>e to evaluate expression that sets both command and cursor
  return vim.keycode '<C-\\>e' .. 'luaeval(\'require("user.search-replace").set_cmd_and_pos()\')' .. vim.keycode '<CR>'
end

-- Toggle magic mode
function M.toggle_magic()
  local cmd = vim.fn.getcmdline()
  if not should_sar() then
    return ''
  end

  local sep = get_current_sep()
  local parts = utils.normalize_parts(vim.split(cmd, sep, { plain = true }))

  -- Get current magic mode from the search pattern
  local search_pattern = parts[2]
  local current_magic = search_pattern:match '^(\\[vmMV])' or ''

  -- Find next magic mode
  local idx = 0
  for i, m in ipairs(magic_list) do
    if m == current_magic then
      idx = i
      break
    end
  end
  local new_magic = magic_list[(idx % #magic_list) + 1]

  -- Strip old magic and add new magic to search pattern
  local search_without_magic = search_pattern:gsub('^\\[vmMV]', '')
  parts[2] = new_magic .. search_without_magic

  local new_cmd = table.concat(parts, sep)

  -- Store command and cursor position for helper function
  sar_state.new_cmd = new_cmd
  sar_state.cursor_pos = #new_cmd - #sep - #parts[4] + 1

  -- Use <C-\>e to evaluate expression that sets both command and cursor
  return vim.keycode '<C-\\>e' .. 'luaeval(\'require("user.search-replace").set_cmd_and_pos()\')' .. vim.keycode '<CR>'
end

-- Setup function
function M.setup()
  -- Normal mode mapping
  vim.keymap.set('n', '<leader>r', function()
    local cmd, move_left = M.populate_searchline 'n'
    local cursor_keys = string.rep(vim.keycode '<Left>', move_left)
    vim.fn.feedkeys(':' .. cmd .. cursor_keys, 'n')
  end, { desc = 'Search and replace word under cursor' })

  -- Visual mode mapping
  vim.keymap.set('v', '<leader>r', function()
    local cmd, move_left = M.populate_searchline 'v'
    local cursor_keys = string.rep(vim.keycode '<Left>', move_left)
    vim.fn.feedkeys(':' .. vim.keycode '<C-u>' .. cmd .. cursor_keys, 'n')
  end, { desc = 'Search and replace visual selection' })

  -- Command-line mode mappings
  vim.keymap.set('c', '<M-g>', function()
    return M.toggle_char 'g'
  end, { expr = true, desc = "Toggle 'g' flag" })

  vim.keymap.set('c', '<M-c>', function()
    return M.toggle_char 'c'
  end, { expr = true, desc = "Toggle 'c' flag" })

  vim.keymap.set('c', '<M-i>', function()
    return M.toggle_char 'i'
  end, { expr = true, desc = "Toggle 'i' flag" })

  vim.keymap.set('c', '<M-d>', M.toggle_replace_term, { expr = true, desc = 'Toggle replace term' })
  vim.keymap.set('c', '<M-5>', M.toggle_all_file, { expr = true, desc = 'Toggle range' })
  vim.keymap.set('c', '<M-/>', M.toggle_separator, { expr = true, desc = 'Toggle separator' })
  vim.keymap.set('c', '<M-m>', M.toggle_magic, { expr = true, desc = 'Toggle magic mode' })

  -- Autocommand to deactivate search-replace mode when leaving cmdline
  vim.api.nvim_create_autocmd('CmdlineLeave', {
    pattern = ':',
    callback = function()
      sar_state.active = false
    end,
  })
end

return M
