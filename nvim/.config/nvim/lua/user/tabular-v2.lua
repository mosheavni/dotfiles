local M = {
  spacing = 4, -- Number of spaces between columns
  default_delimiter = '\t', -- Default delimiter fallback
}

---@class TabStateV2
---@field bufnr integer|nil The ID of the buffer associated with the tab state.
---@field tab_id integer|nil The ID of the tab associated with the tab state.
---@field winnr integer|nil The ID of the window associated with the tab state.
---@field delimiter string The delimiter used for parsing data in this tab state.
---@field interval integer The interval (in seconds) for refreshing the data.
---@field command string The command associated with this tab state.
---@field sort_column integer|nil The column index used for sorting.
---@field sort_direction integer The sorting direction: 1 for ascending, -1 for descending.
---@field col_widths integer[] The widths of the columns in the table.
---@field headers string[] The headers of the table.
---@field raw_lines string[] The raw lines of data from the buffer.
---@field lines string[][] The data lines in the table.
---@field ns_headers integer|nil The namespace ID for headers.
---@field ns_sort integer|nil The namespace ID for sorting.
---@field ns_filter integer|nil The namespace ID for filtering.
---@field timer uv.uv_timer_t|nil The timer for periodic updates.
---@field current_filter string|nil The current filter applied to the table.

---@type table<string, TabStateV2> -- Correct and precise annotation reflecting key-value structure
M.tabs_state = {}

---@type TabStateV2
M.default_tab_state = {
  bufnr = nil,
  tab_id = nil,
  winnr = nil,
  delimiter = M.default_delimiter,
  interval = 5, -- Default refresh interval in seconds
  command = '',
  sort_column = nil,
  sort_direction = 1, -- Default to ascending sort
  col_widths = {}, -- Will be calculated dynamically
  headers = {}, -- Will be populated with headers
  raw_lines = {}, -- Will be populated with raw lines from the buffer
  lines = {}, -- Will be populated with data lines
  ns_headers = nil,
  ns_sort = nil,
  ns_filter = nil,
  timer = nil, -- Timer for periodic updates
}

function M.new_buffer(title)
  -- Create new buffer for display and open in new tab
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, title .. ' - Tabular')
  -- create a new tab and set buffer options
  vim.cmd 'tabnew'

  return bufnr
end

--- Gets buffer number by name
--- @param bufname string: The name of the buffer
--- @return integer|nil: The buffer number
function M.get_buffer_by_name(bufname)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    local filename = vim.fs.basename(name)
    if filename == bufname then
      return buf
    end
  end
  return nil
end

--- Creates or updates a buffer.
--- @param title string: The buffer title
function M.buffer(title)
  local buf = M.get_buffer_by_name(title .. ' - Tabular')

  if not buf then
    buf = M.new_buffer(title)
    vim.schedule(function() end)
  end

  return buf
end

---@param buf_lines string[] The lines from the buffer to be parsed.
---@param delimiter string The delimiter used to split the lines into columns.
---@return table A table containing parsed headers, lines, and column widths.
M.raw_parse = function(buf_lines, delimiter)
  local pattern_delimiter
  if delimiter == '  ' then
    pattern_delimiter = '  +'
  else
    -- Escape special pattern characters in delimiter
    pattern_delimiter = delimiter:gsub('[%(%)%.%%%+%-%*%?%[%]%^%$]', '%%%1')
  end

  -- Parse headers
  local headers = {}
  local header_line = buf_lines[1]
  local header_words = vim.split(header_line, pattern_delimiter)
  for _, word in ipairs(header_words) do
    word = vim.trim(word)
    if word ~= '' then
      table.insert(headers, word)
    end
  end

  -- Parse data lines
  local lines = {}
  for i = 2, #buf_lines do
    local line = buf_lines[i]
    local row = {}
    local words = vim.split(line, pattern_delimiter)
    for _, word in ipairs(words) do
      word = vim.trim(word)
      if word ~= '' then
        table.insert(row, word)
      end
    end
    table.insert(lines, row)
  end

  -- Calculate column widths
  local col_widths = {}
  for i, header in ipairs(headers) do
    col_widths[i] = #header
    for _, row in ipairs(lines) do
      col_widths[i] = math.max(col_widths[i], #(row[i] or ''))
    end
  end

  return {
    headers = headers,
    lines = lines,
    col_widths = col_widths,
  }
end

M.set_buf_opts = function(bufnr)
  vim.api.nvim_set_current_buf(bufnr)
  vim.api.nvim_set_option_value('filetype', 'tabular', { buf = bufnr })
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = bufnr })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = bufnr })
  vim.api.nvim_set_option_value('modifiable', true, { buf = bufnr })
  vim.api.nvim_set_option_value('modified', false, { buf = bufnr })

  -- Set no wrap
  local winnr = vim.api.nvim_get_current_win()
  vim.api.nvim_set_option_value('wrap', false, { win = winnr })
end

M.set_buf_win_options = function(bufnr)
  vim.api.nvim_set_current_buf(bufnr)
  vim.api.nvim_set_option_value('filetype', 'tabular', { buf = bufnr })
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = bufnr })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = bufnr })
  vim.api.nvim_set_option_value('modifiable', true, { buf = bufnr })
  vim.api.nvim_set_option_value('modified', false, { buf = bufnr })

  -- set no wrap
  local winnr = vim.api.nvim_get_current_win()
  vim.api.nvim_set_option_value('wrap', false, { win = winnr })

  -- Set up keymaps
  local k_opts = { noremap = true, silent = true, buffer = bufnr }
  -- vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gs', [[<cmd>lua require('user.tabular').sort_by_current_column()<CR>]], k_opts)
  -- vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-f>', [[<cmd>lua require('user.tabular').filter_table()<CR>]], k_opts)
  vim.keymap.set('n', 'gs', function()
    M.sort_by_current_column()
  end, k_opts)
end

M.set_lines_and_highlight = function(opts)
  -- Validate bufnr and ns_filter before proceeding
  if not opts.bufnr or not vim.api.nvim_buf_is_valid(opts.bufnr) then
    print 'Error: Invalid buffer number'
    return
  end

  vim.api.nvim_buf_set_lines(opts.bufnr, 0, -1, false, opts.display_lines)

  -- Clear any existing filter indicators
  vim.api.nvim_buf_clear_namespace(opts.bufnr, opts.ns_filter, 0, -1)

  -- Add filter indicator if there's an active filter
  if opts.current_filter and opts.current_filter ~= '' then
    vim.api.nvim_buf_set_extmark(opts.bufnr, opts.ns_filter, 1, 0, {
      virt_text = { { '🔍 Filter: ' .. opts.current_filter .. ' ', 'Comment' } },
      virt_text_pos = 'overlay',
    })
  end

  -- Add header highlighting and sort indicator
  local pos = 0
  for i, width in ipairs(opts.col_widths) do
    -- Add header highlighting
    vim.api.nvim_buf_set_extmark(opts.bufnr, opts.ns_headers, 0, pos, {
      end_col = pos + width,
      hl_group = 'Statement',
    })

    -- Add sort indicator if this is the sorted column
    if opts.sort_column == i then
      local sort_indicator = opts.sort_direction == 1 and '▲' or '▼'
      local header_length = #opts.headers[i]
      vim.api.nvim_buf_set_extmark(opts.bufnr, opts.ns_sort, 0, pos + header_length, {
        virt_text = { { ' ' .. sort_indicator, 'Special' } },
        virt_text_pos = 'overlay',
        hl_mode = 'combine',
      })
    end

    pos = pos + width + M.spacing
  end
end

function M.display_table(tabular_command)
  if not tabular_command then
    print 'Error: tabular_command is nil'
    return
  end

  -- Maintain state for the opened tabular commands
  if not M.tabs_state[tabular_command] then
    M.tabs_state[tabular_command] = vim.tbl_deep_extend('force', {}, M.default_tab_state, {
      command = tabular_command,
      delimiter = M.default_delimiter,
    })
  end
  local tab_state = M.tabs_state[tabular_command]

  tab_state.bufnr = M.buffer(tabular_command)

  M.set_buf_win_options(tab_state.bufnr)
  -- Add numeric keymaps for column sorting
  local k_opts = { noremap = true, silent = true }
  for i = 1, #tab_state.headers do
    vim.api.nvim_buf_set_keymap(tab_state.bufnr, 'n', tostring(i), string.format([[<cmd>lua require('user.tabular').sort_by_column(%d)<CR>]], i), k_opts)
  end

  -- create namespaces for highlighting
  local ns_headers = vim.api.nvim_create_namespace('TabularHeaders' .. tab_state.bufnr)
  local ns_sort = vim.api.nvim_create_namespace('TabularSort' .. tab_state.bufnr)
  local ns_filter = vim.api.nvim_create_namespace('TabularFilter' .. tab_state.bufnr)

  -- Format and insert headers
  local formatted_headers = {}
  for i, header in ipairs(tab_state.headers) do
    -- Pad the header with spaces to match column width
    local padded_header = header .. string.rep(' ', tab_state.col_widths[i] - #header)
    table.insert(formatted_headers, padded_header)
  end
  local header_line = table.concat(formatted_headers, string.rep(' ', M.spacing))

  -- Create separator line with proper spacing
  local separator_parts = {}
  for _, width in ipairs(tab_state.col_widths) do
    table.insert(separator_parts, string.rep('-', width))
  end
  local separator_line = table.concat(separator_parts, string.rep('-', M.spacing))
  local display_lines = { header_line, separator_line }

  -- Format and insert data lines
  for _, row in ipairs(tab_state.lines) do
    local should_display = true
    if tab_state.current_filter and tab_state.current_filter ~= '' then
      should_display = false
      for _, cell in ipairs(row) do
        if string.find(string.lower(cell), tab_state.current_filter) then
          should_display = true
          break
        end
      end
    end

    if should_display then
      local formatted_row = {}
      for i, cell in ipairs(row) do
        local value = cell or ''
        local padded_cell = value .. string.rep(' ', tab_state.col_widths[i] - #value)
        table.insert(formatted_row, padded_cell)
      end
      table.insert(display_lines, table.concat(formatted_row, string.rep(' ', M.spacing)))
    end
  end

  M.set_lines_and_highlight {
    bufnr = tab_state.bufnr,
    display_lines = display_lines,
    current_filter = tab_state.current_filter,
    col_widths = tab_state.col_widths,
    headers = tab_state.headers,
    sort_column = tab_state.sort_column,
    sort_direction = tab_state.sort_direction,
    ns_headers = ns_headers,
    ns_sort = ns_sort,
    ns_filter = ns_filter,
  }
end

function M.sort_by_column(col_index, direction)
  local current_bufnr = vim.api.nvim_get_current_buf()
  -- local tab_state = vim.tbl_find(M.tabs_state, function(state)
  --   return state.bufnr == current_bufnr
  -- end)
  local tab_state = M.find_tab_state_by_bufnr(current_bufnr)

  if not tab_state then
    print('No data associated with current buffer. Current buffer ID:', current_bufnr)
    return
  end

  if direction then
    tab_state.sort_direction = direction
  else
    if tab_state.sort_column == col_index then
      tab_state.sort_direction = tab_state.sort_direction * -1
    else
      tab_state.sort_column = col_index
      tab_state.sort_direction = 1
    end
  end

  table.sort(tab_state.lines, function(a, b)
    -- Handle nil values by treating them as empty strings for comparison
    local val_a = a[col_index] or ''
    local val_b = b[col_index] or ''

    -- check if there are two numbers separated by a comma, if so, remove it
    if val_a:find ',' then
      val_a = val_a:gsub('(%d+),(%d+)', '%1%2')
    end
    if val_b:find ',' then
      val_b = val_b:gsub('(%d+),(%d+)', '%1%2')
    end

    -- Try to convert to numbers if possible
    local num_a = tonumber(val_a)
    local num_b = tonumber(val_b)

    -- If both values are numbers, compare numerically
    if num_a and num_b then
      if tab_state.sort_direction == 1 then
        return num_a < num_b
      else
        return num_a > num_b
      end
    end

    -- check if there is a number in the string
    local str_num_a = val_a:match '(%d+)' or false
    local str_num_b = val_b:match '(%d+)' or false
    if str_num_a and str_num_b then
      str_num_a = tonumber(str_num_a)
      str_num_b = tonumber(str_num_b)
      if tab_state.sort_direction == 1 then
        return str_num_a < str_num_b
      else
        return str_num_a > str_num_b
      end
    end

    -- Otherwise compare as strings
    if tab_state.sort_direction == 1 then
      return val_a < val_b
    else
      return val_a > val_b
    end
  end)

  M.display_table(tab_state.command)
end

function M.find_tab_state_by_bufnr(bufnr)
  for _, state in pairs(M.tabs_state) do
    if state.bufnr == bufnr then
      return state
    end
  end
  return nil
end

function M.sort_by_current_column()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local col = cursor[2]

  -- Retrieve the tab state for the current buffer
  local current_bufnr = vim.api.nvim_get_current_buf()
  local tab_state = M.find_tab_state_by_bufnr(current_bufnr)

  if not tab_state or not tab_state.col_widths then
    print 'Error: col_widths not defined.'
    return
  end

  -- Find which column the cursor is in based on column widths and spacing
  local current_pos = 0
  local current_column = 1
  for i, width in ipairs(tab_state.col_widths) do
    local next_pos = current_pos + width
    if i < #tab_state.col_widths then
      next_pos = next_pos + M.spacing
    end

    if col >= current_pos and col < next_pos then
      current_column = i
      break
    end

    current_pos = next_pos
  end

  M.sort_by_column(current_column)
end

--- Function to parse the current buffer and display the table
function M.parse_command()
  vim.ui.input({ prompt = 'Enter command to run: ' }, function(command)
    if not command or command == '' then
      print 'Invalid command'
      return
    end

    local tabular_command = command
    print('Command set: ' .. tabular_command)

    vim.ui.input({ prompt = 'Enter interval (in seconds): ' }, function(interval)
      interval = tonumber(interval)
      if not interval or interval <= 0 then
        print 'Invalid interval'
        return
      end

      if not M.tabs_state[tabular_command] then
        M.tabs_state[tabular_command] = vim.tbl_deep_extend('force', {}, M.default_tab_state, { command = tabular_command })
      end
      local tab_state = M.tabs_state[tabular_command]
      tab_state.interval = interval
      print('Interval set: ' .. interval .. ' seconds')

      vim.ui.input({ prompt = 'Enter delimiter: ', default = M.default_delimiter }, function(delimiter)
        if not delimiter or delimiter == '' or delimiter == nil then
          print 'Invalid delimiter'
          return
        end

        tab_state.delimiter = tostring(delimiter)

        -- Start the loop
        tab_state.timer = vim.uv.new_timer()
        if not tab_state.timer then
          print 'Failed to create timer'
          return
        end
        tab_state.timer:start(0, tab_state.interval * 1000, function()
          local cmd_args = vim.split(tabular_command, ' ', { trimempty = true })
          vim.system(cmd_args, { text = true }, function(result)
            local output = result.stdout or ''
            tab_state.raw_lines = vim.split(output, '\n')
            local raw_parse_res = M.raw_parse(tab_state.raw_lines, tab_state.delimiter)
            tab_state.headers = raw_parse_res.headers
            tab_state.lines = raw_parse_res.lines
            tab_state.col_widths = raw_parse_res.col_widths
            vim.schedule(function()
              if tab_state.sort_column then
                M.sort_by_column(tab_state.sort_column, tab_state.sort_direction)
              else
                -- Create or update the buffer
                M.display_table(tabular_command)
              end
            end)
          end)
        end)
      end)
    end)
  end)
end

function M.setup(opts)
  opts = opts or {}
  if opts.delimiter then
    M.delimiter = opts.delimiter
  end

  -- Create user commands
  vim.api.nvim_create_user_command('TabularParse', function()
    M.parse_buffer()
  end, {})
  vim.api.nvim_create_user_command('TabularParseCmd', function()
    M.parse_command()
  end, {})
end

return M
