local M = {}

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
  return vim.fn.getcmdtype() == ':' and sar_state.active
end

-- Public function to check if search-replace mode is active
function M.is_active()
  return sar_state.active
end

-- Helper to set command and cursor position (called from C-\ e expression)
function M.set_cmd_and_pos()
  vim.fn.setcmdpos(sar_state.cursor_pos)

  -- Trigger dashboard refresh by invalidating cache and simulating a keystroke
  -- This happens after the cmdline is updated, triggering CmdlineChanged with fresh data
  vim.defer_fn(function()
    local ok, dashboard = pcall(require, 'user.search-replace-dashboard')
    if ok and dashboard and dashboard.invalidate_cache then
      dashboard.invalidate_cache()
      -- Simulate typing space+backspace to trigger CmdlineChanged without modifying the command
      vim.fn.feedkeys(' ' .. vim.keycode '<BS>', 'in')
    end
  end, 50)

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

  local sep = sar_state.sep
  local parts = vim.split(cmd, sep, { plain = true })
  local flags = parts[#parts]

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

  parts[#parts] = flags
  local new_cmd = table.concat(parts, sep)

  -- Store command and cursor position for helper function
  sar_state.new_cmd = new_cmd
  sar_state.cursor_pos = #new_cmd - #sep - #parts[#parts] + 1

  -- Use <C-\>e to evaluate expression that sets both command and cursor
  return vim.keycode '<C-\\>e' .. 'luaeval(\'require("user.search-replace").set_cmd_and_pos()\')' .. vim.keycode '<CR>'
end

-- Toggle replace term (clear/restore original word)
function M.toggle_replace_term()
  local cmd = vim.fn.getcmdline()
  if not should_sar() then
    return ''
  end

  local sep = sar_state.sep
  local parts = vim.split(cmd, sep, { plain = true })
  local replace_term = parts[#parts - 1] == '' and sar_state.cword or ''
  parts[#parts - 1] = replace_term

  local new_cmd = table.concat(parts, sep)

  -- Store command and cursor position for helper function
  sar_state.new_cmd = new_cmd
  sar_state.cursor_pos = #new_cmd - #sep - #parts[#parts] + 1

  -- Use <C-\>e to evaluate expression that sets both command and cursor
  return vim.keycode '<C-\\>e' .. 'luaeval(\'require("user.search-replace").set_cmd_and_pos()\')' .. vim.keycode '<CR>'
end

-- Toggle range (all file)
function M.toggle_all_file()
  local cmd = vim.fn.getcmdline()
  if not should_sar() then
    return ''
  end

  local sep = sar_state.sep
  local parts = vim.split(cmd, sep, { plain = true })
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
  sar_state.cursor_pos = #new_cmd - #sep - #parts[#parts] + 1

  -- Use <C-\>e to evaluate expression that sets both command and cursor
  return vim.keycode '<C-\\>e' .. 'luaeval(\'require("user.search-replace").set_cmd_and_pos()\')' .. vim.keycode '<CR>'
end

-- Toggle separator
function M.toggle_separator()
  local cmd = vim.fn.getcmdline()
  if not should_sar() then
    return ''
  end

  local old_sep = sar_state.sep
  local parts = vim.split(cmd, old_sep, { plain = true })

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
  sar_state.cursor_pos = #new_cmd - #sar_state.sep - #parts[#parts] + 1

  -- Use <C-\>e to evaluate expression that sets both command and cursor
  return vim.keycode '<C-\\>e' .. 'luaeval(\'require("user.search-replace").set_cmd_and_pos()\')' .. vim.keycode '<CR>'
end

-- Toggle magic mode
function M.toggle_magic()
  local cmd = vim.fn.getcmdline()
  if not should_sar() then
    return ''
  end

  local sep = sar_state.sep
  local parts = vim.split(cmd, sep, { plain = true })

  -- Find next magic mode
  local idx = 0
  for i, m in ipairs(magic_list) do
    if m == sar_state.magic then
      idx = i
      break
    end
  end
  sar_state.magic = magic_list[(idx % #magic_list) + 1]

  -- Update the search pattern with new magic
  parts[2] = sar_state.magic .. sar_state.cword

  local new_cmd = table.concat(parts, sep)

  -- Store command and cursor position for helper function
  sar_state.new_cmd = new_cmd
  sar_state.cursor_pos = #new_cmd - #sep - #parts[#parts] + 1

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
