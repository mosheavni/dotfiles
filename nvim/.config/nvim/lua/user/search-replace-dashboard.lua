---@diagnostic disable: undefined-field

---@class SearchReplaceDashboard
local M = {}

local Float = require 'user.float'

-- Internal state
local dashboard_state = {
  float = nil, -- Float instance
  ns_id = nil, -- Namespace for highlights
  last_parsed = nil, -- Cache of last parsed command
}

-- Refresh state to prevent infinite loops
local refresh_state = {
  last_fake_keystroke_time = 0,
}

-- Configuration
local config = {
  -- Visual symbols
  symbols = {
    active = '●', -- Active flag indicator
    inactive = '○', -- Inactive flag indicator
  },
  -- Highlight groups
  highlights = {
    title = 'Title',
    key = 'Special',
    arrow = 'Comment',
    active_desc = 'String',
    inactive_desc = 'Comment',
    active_indicator = 'DiagnosticOk',
    inactive_indicator = 'Comment',
    status_label = 'Comment',
    status_value = 'Constant',
  },
}

---@class ParsedCommand
---@field range string The range part (e.g., ".,$s", "%s")
---@field separator string The separator character
---@field magic string The magic mode (e.g., "\\V", "\\v")
---@field search string The search term
---@field replace string The replace term
---@field flags table<string, boolean> Flags as {g=true, c=true, i=false}
---@field raw string The original command

---Split string by separator, respecting escapes
---@param str string The string to split
---@param sep string The separator character
---@return string[] parts The split parts
local function split_by_unescaped_separator(str, sep)
  local parts = {}
  local current = ''
  local i = 1

  while i <= #str do
    local char = str:sub(i, i)

    if char == '\\' and i < #str then
      -- Escaped character - include both backslash and next char
      current = current .. char .. str:sub(i + 1, i + 1)
      i = i + 2
    elseif char == sep then
      -- Unescaped separator - split here
      table.insert(parts, current)
      current = ''
      i = i + 1
    else
      current = current .. char
      i = i + 1
    end
  end

  -- Add remaining content
  table.insert(parts, current)

  return parts
end

---Parse a substitute command into components
---@param cmdline string The command line content
---@return ParsedCommand|nil parsed The parsed components, or nil if not a valid substitute
local function parse_substitute_command(cmdline)
  -- Quick validation: must be a substitute command
  if not cmdline:match '^[%%.,0-9$]*s' then
    return nil
  end

  local parsed = {
    range = '',
    separator = '',
    magic = '',
    search = '',
    replace = '',
    flags = { g = false, c = false, i = false },
    raw = cmdline,
  }

  -- Step 1: Extract range (everything before 's')
  local range_pattern = '^([%%.,0-9$]*)s'
  local range_match = cmdline:match(range_pattern)
  if range_match then
    parsed.range = range_match .. 's'
  else
    parsed.range = 's' -- No range specified
  end

  -- Step 2: Determine separator (first character after 's')
  local after_s = cmdline:sub(#parsed.range + 1)

  -- Next character is separator
  if #after_s > 0 then
    parsed.separator = after_s:sub(1, 1)
  else
    return parsed -- Incomplete command
  end

  -- Step 3: Split by separator (accounting for escaping)
  local parts = split_by_unescaped_separator(after_s:sub(2), parsed.separator)

  if #parts >= 1 then
    parsed.search = parts[1] or ''
    -- Extract magic mode from search pattern (it's at the beginning)
    local magic_match = parsed.search:match '^(\\[vmMV])'
    if magic_match then
      parsed.magic = magic_match
    end
  end
  if #parts >= 2 then
    parsed.replace = parts[2] or ''
  end
  if #parts >= 3 then
    local flags_str = parts[3] or ''
    parsed.flags.g = flags_str:find 'g' ~= nil
    parsed.flags.c = flags_str:find 'c' ~= nil
    parsed.flags.i = flags_str:find 'i' ~= nil
  end

  return parsed
end

---Get description for a range
---@param range string The range part (e.g., "%s", ".,$s")
---@return string description The range description
local function get_range_description(range)
  if range == '%s' then
    return 'Entire file'
  elseif range == '.,$s' then
    return 'Current line to end of file'
  elseif range == '0,.s' then
    return 'Start of file to current line'
  elseif range == 's' then
    return 'Current line only'
  else
    return 'Custom range'
  end
end

---Format the range display lines
---@param parsed ParsedCommand The parsed command
---@return string[] lines The formatted range lines
local function format_range_lines(parsed)
  local range_value = parsed.range ~= '' and parsed.range or 's'
  local range_desc = get_range_description(range_value)
  return {
    '  Range: ' .. range_value,
    '    → ' .. range_desc,
  }
end

---Get description for a magic mode
---@param magic string The magic mode (e.g., "\\v", "\\V")
---@return string description The magic mode description
local function get_magic_description(magic)
  if magic == '\\v' then
    return 'Very magic: Extended regex syntax'
  elseif magic == '\\m' then
    return 'Magic: Standard regex syntax (default)'
  elseif magic == '\\M' then
    return 'Nomagic: Minimal regex syntax'
  elseif magic == '\\V' then
    return 'Very nomagic: Literal search'
  else
    return 'Default magic mode'
  end
end

---Format the magic display lines
---@param parsed ParsedCommand The parsed command
---@return string[] lines The formatted magic lines
local function format_magic_lines(parsed)
  local magic_value = parsed.magic ~= '' and parsed.magic or 'none'
  local magic_desc = get_magic_description(parsed.magic)
  return {
    '  Magic: ' .. magic_value,
    '    → ' .. magic_desc,
  }
end

---Format the status line showing current state (separator and flags)
---@param parsed ParsedCommand The parsed command
---@return string status_line The formatted status line
local function format_status_line(parsed)
  local parts = {}

  -- Separator
  table.insert(parts, 'Sep: ' .. (parsed.separator ~= '' and parsed.separator or '/'))

  -- Flags
  local flags_str = ''
  if parsed.flags.g then
    flags_str = flags_str .. 'g'
  end
  if parsed.flags.c then
    flags_str = flags_str .. 'c'
  end
  if parsed.flags.i then
    flags_str = flags_str .. 'i'
  end
  table.insert(parts, 'Flags: ' .. (flags_str ~= '' and flags_str or 'none'))

  return '  ' .. table.concat(parts, '  ')
end

---Format the search/replace display lines
---@param parsed ParsedCommand The parsed command
---@return string[] lines The formatted search/replace lines
local function format_search_replace_lines(parsed)
  -- Strip magic prefix from search term for display
  local search_display = parsed.search
  if parsed.magic ~= '' then
    search_display = search_display:gsub('^' .. vim.pesc(parsed.magic), '')
  end

  return {
    '  Search:  ' .. search_display,
    '  Replace: ' .. parsed.replace,
  }
end

---@class KeymapInfo
---@field key string The keymap (e.g., "<M-g>")
---@field flag string? The flag it toggles (e.g., "g")
---@field desc string Description

---Get keymap information with state checking
---@return KeymapInfo[] keymaps The keymap information
local function get_keymaps_info()
  return {
    { key = '<M-g>', flag = 'g', desc = "Toggle 'g' flag (global)" },
    { key = '<M-c>', flag = 'c', desc = "Toggle 'c' flag (confirm)" },
    { key = '<M-i>', flag = 'i', desc = "Toggle 'i' flag (case-insensitive)" },
    { key = '<M-d>', flag = nil, desc = 'Toggle replace term' },
    { key = '<M-5>', flag = nil, desc = 'Cycle range' },
    { key = '<M-/>', flag = nil, desc = 'Cycle separator' },
    { key = '<M-m>', flag = nil, desc = 'Cycle magic mode' },
  }
end

---Format the keymap lines with state indicators
---@param parsed ParsedCommand The parsed command
---@return string[] keymap_lines The formatted keymap lines
local function format_keymap_lines(parsed)
  local lines = {}
  local keymaps = get_keymaps_info()

  for _, km in ipairs(keymaps) do
    local indicator = '  '
    if km.flag then
      -- Check if this flag is active
      if parsed.flags[km.flag] then
        indicator = config.symbols.active .. ' '
      else
        indicator = config.symbols.inactive .. ' '
      end
    end

    local line = '  ' .. indicator .. km.key .. '  →  ' .. km.desc
    table.insert(lines, line)
  end

  return lines
end

---Apply highlights to the dashboard buffer
---@param buf_id number The buffer ID
---@param lines string[] The buffer lines
---@param parsed ParsedCommand The parsed command
local function apply_highlights(buf_id, lines, parsed)
  if not dashboard_state.ns_id then
    dashboard_state.ns_id = vim.api.nvim_create_namespace 'SearchReplaceDashboard'
  end

  -- Clear existing highlights
  vim.api.nvim_buf_clear_namespace(buf_id, dashboard_state.ns_id, 0, -1)

  -- Line 0: Title
  local title_line = lines[1] -- First line in the lines array is line 0 in the buffer
  vim.api.nvim_buf_set_extmark(buf_id, dashboard_state.ns_id, 0, 0, {
    end_col = #title_line,
    hl_group = config.highlights.title,
  })

  -- Line 1: Empty (separator)

  -- Lines 2-3: Range display
  local range_line = lines[3] -- Buffer line 2 is array index 3
  local range_label = 'Range:'
  local range_label_pos = range_line:find(range_label, 1, true)
  if range_label_pos then
    -- Highlight "Range:" label
    vim.api.nvim_buf_set_extmark(buf_id, dashboard_state.ns_id, 2, range_label_pos - 1, {
      end_col = range_label_pos + #range_label - 1,
      hl_group = config.highlights.status_label,
    })
    -- Highlight the range value
    local value_start = range_label_pos + #range_label
    vim.api.nvim_buf_set_extmark(buf_id, dashboard_state.ns_id, 2, value_start, {
      end_col = #range_line,
      hl_group = config.highlights.status_value,
    })
  end

  -- Highlight range description (line 3) with arrow and description
  local range_desc_line = lines[4] -- Buffer line 3 is array index 4
  local arrow_pos = range_desc_line:find('→', 1, true)
  if arrow_pos then
    -- Highlight arrow
    vim.api.nvim_buf_set_extmark(buf_id, dashboard_state.ns_id, 3, arrow_pos - 1, {
      end_col = arrow_pos + 2, -- UTF-8 character takes 3 bytes
      hl_group = config.highlights.arrow,
    })
    -- Highlight description text
    vim.api.nvim_buf_set_extmark(buf_id, dashboard_state.ns_id, 3, arrow_pos + 2, {
      end_col = #range_desc_line,
      hl_group = config.highlights.inactive_desc,
    })
  end

  -- Line 4: Empty (separator)

  -- Lines 5-6: Magic display
  local magic_line = lines[6] -- Buffer line 5 is array index 6
  local magic_label = 'Magic:'
  local magic_label_pos = magic_line:find(magic_label, 1, true)
  if magic_label_pos then
    -- Highlight "Magic:" label
    vim.api.nvim_buf_set_extmark(buf_id, dashboard_state.ns_id, 5, magic_label_pos - 1, {
      end_col = magic_label_pos + #magic_label - 1,
      hl_group = config.highlights.status_label,
    })
    -- Highlight the magic value
    local value_start = magic_label_pos + #magic_label
    vim.api.nvim_buf_set_extmark(buf_id, dashboard_state.ns_id, 5, value_start, {
      end_col = #magic_line,
      hl_group = config.highlights.status_value,
    })
  end

  -- Highlight magic description (line 6) with arrow and description
  local magic_desc_line = lines[7] -- Buffer line 6 is array index 7
  local magic_arrow_pos = magic_desc_line:find('→', 1, true)
  if magic_arrow_pos then
    -- Highlight arrow
    vim.api.nvim_buf_set_extmark(buf_id, dashboard_state.ns_id, 6, magic_arrow_pos - 1, {
      end_col = magic_arrow_pos + 2, -- UTF-8 character takes 3 bytes
      hl_group = config.highlights.arrow,
    })
    -- Highlight description text
    vim.api.nvim_buf_set_extmark(buf_id, dashboard_state.ns_id, 6, magic_arrow_pos + 2, {
      end_col = #magic_desc_line,
      hl_group = config.highlights.inactive_desc,
    })
  end

  -- Line 7: Empty (separator)

  -- Line 8: Status line
  local status_line = lines[9] -- Buffer line 8 is array index 9
  local col = 0

  -- Highlight each part of the status line
  for label, hl in pairs {
    ['Sep:'] = config.highlights.status_label,
    ['Flags:'] = config.highlights.status_label,
  } do
    local start_pos = status_line:find(label, col, true)
    if start_pos then
      vim.api.nvim_buf_set_extmark(buf_id, dashboard_state.ns_id, 8, start_pos - 1, {
        end_col = start_pos + #label - 1,
        hl_group = hl,
      })

      -- Highlight the value after the label
      local value_start = start_pos + #label -- 1-based string index
      local next_label_pos = status_line:find('%s%s[A-Z]', value_start)
      local value_end = next_label_pos or #status_line + 1 -- 1-based exclusive end
      -- Convert from 1-based string indices to 0-based buffer column indices
      vim.api.nvim_buf_set_extmark(buf_id, dashboard_state.ns_id, 8, value_start - 1, {
        end_col = value_end - 1,
        hl_group = config.highlights.status_value,
      })

      col = value_end
    end
  end

  -- Line 9: Empty (separator)

  -- Lines 10-11: Search and Replace display
  local search_line = lines[11] -- Buffer line 10 is array index 11
  local search_label = 'Search:'
  local search_label_pos = search_line:find(search_label, 1, true)
  if search_label_pos then
    -- Highlight "Search:" label
    vim.api.nvim_buf_set_extmark(buf_id, dashboard_state.ns_id, 10, search_label_pos - 1, {
      end_col = search_label_pos + #search_label - 1,
      hl_group = config.highlights.status_label,
    })
    -- Highlight the search value (everything after the label)
    local value_start = search_label_pos + #search_label
    vim.api.nvim_buf_set_extmark(buf_id, dashboard_state.ns_id, 10, value_start, {
      end_col = #search_line,
      hl_group = config.highlights.status_value,
    })
  end

  local replace_line = lines[12] -- Buffer line 11 is array index 12
  local replace_label = 'Replace:'
  local replace_label_pos = replace_line:find(replace_label, 1, true)
  if replace_label_pos then
    -- Highlight "Replace:" label
    vim.api.nvim_buf_set_extmark(buf_id, dashboard_state.ns_id, 11, replace_label_pos - 1, {
      end_col = replace_label_pos + #replace_label - 1,
      hl_group = config.highlights.status_label,
    })
    -- Highlight the replace value (everything after the label)
    local value_start = replace_label_pos + #replace_label
    vim.api.nvim_buf_set_extmark(buf_id, dashboard_state.ns_id, 11, value_start, {
      end_col = #replace_line,
      hl_group = config.highlights.status_value,
    })
  end

  -- Line 12: Empty (separator)

  -- Lines 13+: Keymap lines
  local keymaps = get_keymaps_info()
  for i, km in ipairs(keymaps) do
    local line_idx = 13 + i - 1
    local line = lines[line_idx + 1]

    if not line then
      break
    end

    -- Highlight indicator symbol
    if km.flag then
      local is_active = parsed.flags[km.flag]
      local indicator_hl = is_active and config.highlights.active_indicator or config.highlights.inactive_indicator
      vim.api.nvim_buf_set_extmark(buf_id, dashboard_state.ns_id, line_idx, 2, {
        end_col = 3,
        hl_group = indicator_hl,
      })
    end

    -- Highlight keymap key
    local key_start = line:find(km.key, 1, true)
    if key_start then
      vim.api.nvim_buf_set_extmark(buf_id, dashboard_state.ns_id, line_idx, key_start - 1, {
        end_col = key_start + #km.key - 1,
        hl_group = config.highlights.key,
      })
    end

    -- Highlight arrow
    local arrow_start = line:find('→', 1, true)
    if arrow_start then
      vim.api.nvim_buf_set_extmark(buf_id, dashboard_state.ns_id, line_idx, arrow_start - 1, {
        end_col = arrow_start + 2,
        hl_group = config.highlights.arrow,
      })
    end

    -- Highlight description
    local desc_start = line:find(km.desc, 1, true)
    if desc_start then
      local desc_hl = (km.flag and parsed.flags[km.flag]) and config.highlights.active_desc or config.highlights.inactive_desc
      vim.api.nvim_buf_set_extmark(buf_id, dashboard_state.ns_id, line_idx, desc_start - 1, {
        end_col = #line,
        hl_group = desc_hl,
      })
    end
  end
end

---Compute window configuration for centered positioning
---@param buf_id number The buffer ID
---@return table config The window configuration
local function compute_config(buf_id)
  local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)

  -- Calculate window size
  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  local height = #lines

  -- Calculate centered position
  local ui = vim.api.nvim_list_uis()[1]
  if not ui then
    return {}
  end

  local screen_width = ui.width
  local screen_height = ui.height

  return {
    relative = 'editor',
    width = width + 2,
    height = height,
    col = math.floor((screen_width - width) / 2), -- Center horizontally
    row = math.floor((screen_height - height) / 2) - 5, -- Center vertically (slightly above center)
    style = 'minimal',
    border = 'rounded',
    focusable = false,
    zindex = 50,
  }
end

---Invalidate the dashboard cache to force next refresh
function M.invalidate_cache()
  dashboard_state.last_parsed = nil
end

---Refresh the dashboard with current cmdline state
---@param cmdline? string Optional cmdline to parse (if not provided, reads current)
function M.refresh_dashboard(cmdline)
  -- CRITICAL: Guard for fast events (mini.notify pattern)
  local in_fast = vim.in_fast_event()
  if in_fast then
    return vim.schedule(function()
      M.refresh_dashboard(cmdline)
    end)
  end

  -- Get current command line in safe context
  cmdline = cmdline or vim.fn.getcmdline()

  -- Parse the command
  local parsed = parse_substitute_command(cmdline)
  if not parsed then
    return -- Not a substitute command
  end

  -- Check if command changed (optimization)
  if dashboard_state.last_parsed and dashboard_state.last_parsed.raw == parsed.raw then
    return -- No change, skip refresh
  end

  dashboard_state.last_parsed = parsed

  -- Build content
  local lines = {}
  table.insert(lines, '  Search & Replace')
  table.insert(lines, '')

  -- Add range display
  local range_lines = format_range_lines(parsed)
  for _, line in ipairs(range_lines) do
    table.insert(lines, line)
  end
  table.insert(lines, '')

  -- Add magic display
  local magic_lines = format_magic_lines(parsed)
  for _, line in ipairs(magic_lines) do
    table.insert(lines, line)
  end
  table.insert(lines, '')

  table.insert(lines, format_status_line(parsed))
  table.insert(lines, '')

  -- Add search/replace display
  local search_replace_lines = format_search_replace_lines(parsed)
  for _, line in ipairs(search_replace_lines) do
    table.insert(lines, line)
  end
  table.insert(lines, '')

  local keymap_lines = format_keymap_lines(parsed)
  for _, line in ipairs(keymap_lines) do
    table.insert(lines, line)
  end

  -- Create or update float
  if not dashboard_state.float then
    dashboard_state.float = Float.new()
  end

  -- Refresh with synchronous highlights (mini.notify pattern)
  dashboard_state.float.refresh(
    function()
      return lines
    end,
    function(buf_id)
      return compute_config(buf_id)
    end,
    nil,
    function(buf_id, buf_lines)
      -- Apply highlights synchronously after buffer refresh
      apply_highlights(buf_id, buf_lines, parsed)
    end
  )
end

---Close the dashboard
function M.close_dashboard()
  if dashboard_state.float then
    dashboard_state.float.close()
  end
  dashboard_state.last_parsed = nil
end

---Setup autocmds for the dashboard
function M.setup()
  local augroup = vim.api.nvim_create_augroup('SearchReplaceDashboard', { clear = true })

  -- Show dashboard when search-replace mode is activated
  vim.api.nvim_create_autocmd('CmdlineEnter', {
    group = augroup,
    pattern = ':',
    callback = function()
      local sar = require 'user.search-replace'
      if sar.is_active() then
        -- Double schedule to ensure cmdline is fully populated
        vim.schedule(function()
          vim.schedule(function()
            -- Don't pass cmdline here - let it read fresh after delay
            M.refresh_dashboard()
          end)
        end)
      end
    end,
  })

  -- Update dashboard on every keystroke
  vim.api.nvim_create_autocmd('CmdlineChanged', {
    group = augroup,
    pattern = ':',
    callback = function()
      local sar = require 'user.search-replace'
      if sar.is_active() then
        local now = vim.loop.now()
        -- Check if we recently triggered a fake keystroke (to prevent infinite loop)
        if now - refresh_state.last_fake_keystroke_time < 100 then
          -- We're in a fake keystroke cycle, just refresh normally
          M.refresh_dashboard()
        else
          -- Trigger fake keystroke for proper refresh (same fix as toggles)
          refresh_state.last_fake_keystroke_time = now
          vim.defer_fn(function()
            M.invalidate_cache()
            vim.fn.feedkeys(' ' .. vim.keycode '<BS>', 'in')
          end, 50)
        end
      end
    end,
  })

  -- Close dashboard when leaving cmdline
  vim.api.nvim_create_autocmd('CmdlineLeave', {
    group = augroup,
    pattern = ':',
    callback = function()
      M.close_dashboard()
    end,
  })
end

return M
