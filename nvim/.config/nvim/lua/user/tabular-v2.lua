local M = {
  spacing = 4, -- Number of spaces between columns
  default_delimiter = '\t', -- Default delimiter fallback
  default_interval = 5, -- Default refresh interval in seconds
  bufname_suffix = 'Tabular', -- Suffix for buffer names
}

---@class TabStateV2
---@field bufnr integer|nil The ID of the buffer associated with the tab state.
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

--- Gets or creates a tab state for a given command
--- @param command string: The command to get or create the tab state for
--- @param opts? table: Optional parameters for the tab state
--- @return TabStateV2|nil: The tab state for the command
function M.get_or_create_tab_state(command, opts)
  if not command or command == '' then
    print 'Invalid command'
    return nil
  end

  -- Check if the tab state already exists
  if M.tabs_state[command] then
    if opts then
      -- If opts are provided, extend the existing tab state with new options
      M.tabs_state[command] = vim.tbl_deep_extend('force', M.tabs_state[command], opts)
    end
    return M.tabs_state[command]
  end

  -- Create a new tab state if it doesn't exist
  M.tabs_state[command] = vim.tbl_deep_extend('force', {}, M.default_tab_state, opts or {})
  return M.tabs_state[command]
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

--- Creates or gets existing buffer for tabular display
--- @param title string: The buffer title
--- @return integer: The buffer number
function M.buffer(title)
  local bufname = title .. ' - ' .. M.bufname_suffix
  local buf = M.get_buffer_by_name(bufname)

  if not buf then
    -- Create new buffer for display and open in new tab
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, bufname)
    -- create a new tab and set the created buffer in it
    vim.cmd 'tabnew'
    vim.api.nvim_set_current_buf(buf)
  end

  return buf
end

---@param buf_lines string[] The lines from the buffer to be parsed.
---@param delimiter string The delimiter used to split the lines into columns.
---@return table A table containing parsed headers, lines, and column widths.
function M.raw_parse(buf_lines, delimiter)
  local pattern_delimiter
  local tab = vim.keycode '\t'
  if delimiter == '  ' then
    pattern_delimiter = '  +'
  elseif delimiter == tab then
    -- check if buf_lines has tab characters
    if buf_lines[1]:find(tab) then
      pattern_delimiter = tab
    else
      -- If no tabs, use spaces as fallback
      pattern_delimiter = '  +'
    end
  else
    -- Escape special pattern characters in delimiter
    pattern_delimiter = delimiter:gsub('[%(%)%.%%%+%-%*%?%[%]%^%$]', '%%%1')
  end

  -- clear empty lines
  for i = #buf_lines, 1, -1 do
    if vim.trim(buf_lines[i]) == '' then
      table.remove(buf_lines, i)
    end
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

function M.set_buf_win_options(bufnr)
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
  vim.keymap.set('n', 'gs', function()
    M.sort_by_current_column()
  end, k_opts)
  vim.keymap.set('n', '<C-f>', function()
    M.filter_table()
  end, k_opts)
  vim.keymap.set('n', 'ge', function()
    local tab_state = M.find_tab_state_by_bufnr(bufnr)
    if not tab_state then
      print 'No tabular state found for current buffer.'
      return
    end
    M.parse_command(tab_state.command)
  end, k_opts)
  vim.keymap.set('n', '?', function()
    M.show_help()
  end, k_opts)
end

function M.set_lines_and_highlight(opts)
  -- Validate bufnr and ns_filter before proceeding
  if not opts.bufnr or not vim.api.nvim_buf_is_valid(opts.bufnr) then
    print('Error: Invalid buffer number: ' .. tostring(opts.bufnr))
    return
  end

  vim.api.nvim_buf_set_lines(opts.bufnr, 0, -1, false, opts.display_lines)

  -- Clear any existing filter and sort indicators
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

function M.display_table(tabular_command, delimiter)
  if not tabular_command then
    print 'Error: tabular_command is nil'
    return
  end

  -- Maintain state for the opened tabular commands
  local tab_state = M.get_or_create_tab_state(tabular_command, { delimiter = delimiter or M.default_delimiter })

  if not tab_state then
    print 'Error: Failed to create or get tab state'
    return
  end

  tab_state.bufnr = M.buffer(tabular_command)

  M.set_buf_win_options(tab_state.bufnr)
  -- Add numeric keymaps for column sorting
  local k_opts = { noremap = true, silent = true }
  for i = 1, #tab_state.headers do
    vim.api.nvim_buf_set_keymap(tab_state.bufnr, 'n', tostring(i), string.format([[<cmd>lua require('user.tabular-v2').sort_by_column(%d)<CR>]], i), k_opts)
  end

  -- create namespaces for highlighting if they don't exist
  tab_state.ns_headers = tab_state.ns_headers or vim.api.nvim_create_namespace('TabularHeaders' .. tab_state.bufnr)
  tab_state.ns_sort = tab_state.ns_sort or vim.api.nvim_create_namespace('TabularSort' .. tab_state.bufnr)
  tab_state.ns_filter = tab_state.ns_filter or vim.api.nvim_create_namespace('TabularFilter' .. tab_state.bufnr)

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
        if string.find(string.lower(cell), tab_state.current_filter, 1, true) then
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
    ns_headers = tab_state.ns_headers,
    ns_sort = tab_state.ns_sort,
    ns_filter = tab_state.ns_filter,
  }
end

function M.sort_by_column(col_index, direction)
  local current_bufnr = vim.api.nvim_get_current_buf()
  local tab_state = M.find_tab_state_by_bufnr(current_bufnr)

  if not tab_state then
    return
  end

  if direction then
    tab_state.sort_column = col_index
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

    -- Helper function to determine if a string should be sorted numerically
    local function should_sort_numerically(str)
      local digits = str:gsub('%D', '')

      -- If no digits, definitely not numeric
      if #digits == 0 then
        return false
      end

      -- If mostly digits (>= 50% of string), likely numeric
      if #digits >= #str * 0.5 then
        return true
      end

      -- Check for common numeric patterns: number followed by unit/suffix
      -- Examples: "1000 GiB", "5.2xlarge", "100MB", "3.5TB"
      if str:match '^%d+%.?%d*%s*%a*$' then
        return true
      end

      -- If digits are at the beginning and represent a significant portion, likely numeric
      if str:match '^%d+' and #digits >= #str * 0.3 then
        return true
      end

      return false
    end

    -- Check if both strings should be sorted numerically
    local a_numeric = should_sort_numerically(val_a)
    local b_numeric = should_sort_numerically(val_b)

    if a_numeric and b_numeric then
      local str_num_a = val_a:match '(%d+%.?%d*)' or val_a:match '(%d+)'
      local str_num_b = val_b:match '(%d+%.?%d*)' or val_b:match '(%d+)'

      if str_num_a and str_num_b then
        str_num_a = tonumber(str_num_a)
        str_num_b = tonumber(str_num_b)
        if tab_state.sort_direction == 1 then
          return str_num_a < str_num_b
        else
          return str_num_a > str_num_b
        end
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

function M.filter_table()
  local current_bufnr = vim.api.nvim_get_current_buf()
  local tab_state = M.find_tab_state_by_bufnr(current_bufnr)

  if not tab_state then
    print('No data associated with current buffer. Current buffer ID:', current_bufnr)
    return
  end
  local input_params = { prompt = 'Filter❯ ' }
  if tab_state.current_filter then
    input_params.default = tab_state.current_filter
  end
  vim.ui.input(input_params, function(input)
    if input then
      tab_state.current_filter = string.lower(input)
      M.display_table(tab_state.command)
    end
  end)
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

--- Show help with available keymaps
function M.show_help()
  local help_lines = {
    'Tabular Keymaps Help',
    '=====================',
    '',
    'Navigation & Sorting:',
    '  gs         - Toggle sort direction (ascending/descending)',
    '  1-9        - Sort by column number',
    "  <cursor>   - Position cursor on column and press 'gs' to sort",
    '',
    'Filtering & Editing:',
    '  <C-f>      - Filter rows (case insensitive)',
    '  ge         - Edit command (change command, interval, delimiter)',
    '',
    'Help:',
    '  ?          - Show this help',
    '',
    'Sort Indicators:',
    '  ▲          - Column sorted ascending',
    '  ▼          - Column sorted descending',
    '  🔍         - Active filter indicator',
    '',
    'Tips:',
    '  • Sorting preserves across data refreshes',
    '  • Filters are case insensitive and search all columns',
    '  • Use numeric keys 1-9 for quick column sorting',
    "  • Position cursor on any column and press 'gs' to sort",
    '',
    'Press any key to close help...',
  }

  -- Create a floating window for help
  local buf = vim.api.nvim_create_buf(false, true)
  local width = 70
  local height = #help_lines + 2

  -- Calculate center position
  local ui = vim.api.nvim_list_uis()[1]
  local win_width = ui.width
  local win_height = ui.height
  local col = math.floor((win_width - width) / 2)
  local row = math.floor((win_height - height) / 2)

  -- Create the floating window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = col,
    row = row,
    style = 'minimal',
    border = 'rounded',
    title = ' Tabular Help ',
    title_pos = 'center',
  })

  -- Set buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, help_lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })

  -- Add some highlighting
  local ns = vim.api.nvim_create_namespace 'TabularHelp'
  vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
    end_col = #help_lines[1],
    hl_group = 'Title',
  })
  vim.api.nvim_buf_set_extmark(buf, ns, 1, 0, {
    end_col = #help_lines[2],
    hl_group = 'Title',
  })

  -- Highlight section headers
  for i, line in ipairs(help_lines) do
    if line:match ':$' then
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
        end_col = #line,
        hl_group = 'Special',
      })
    elseif line:match '^  [%w<>%-]+' then
      -- Highlight keymaps
      local keymap = line:match '^  ([%w<>%-]+)'
      if keymap then
        vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 2, {
          end_col = 2 + #keymap,
          hl_group = 'Keyword',
        })
      end
    end
  end

  -- Close on any key press
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, nowait = true })

  -- Close on any other key
  vim.keymap.set('n', '<CR>', function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, nowait = true })

  -- Set up autocommand to close on focus lost
  vim.api.nvim_create_autocmd('BufLeave', {
    buffer = buf,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end,
    once = true,
  })
end

--- Function to parse the current buffer and display the table
function M.parse_command(existing_command)
  local tab_state = existing_command and M.get_or_create_tab_state(existing_command) or nil
  local inputs = {
    command = { prompt = 'Enter command to run❯ ', default = existing_command or '' },
    interval = { prompt = 'Enter interval (in seconds)❯ ', default = tostring(tab_state and tab_state.interval or M.default_interval) },
    delimiter = { prompt = 'Enter delimiter❯ ', default = tostring(tab_state and tab_state.delimiter or M.default_delimiter) },
  }
  vim.ui.input(inputs.command, function(full_command)
    if not full_command or full_command == '' then
      print 'Invalid command'
      return
    end
    local command = vim.fs.basename(full_command)
    print('Command set: ' .. command)

    vim.ui.input(inputs.interval, function(interval)
      interval = tonumber(interval)
      if not interval or interval <= 0 then
        print 'Invalid interval'
        return
      end

      vim.ui.input(inputs.delimiter, function(delimiter)
        if not delimiter or delimiter == '' or delimiter == nil then
          print 'Invalid delimiter'
          return
        end

        if existing_command and tab_state then
          if tab_state.timer and not tab_state.timer:is_closing() and tab_state.bufnr then
            tab_state.timer:stop()
            tab_state.timer:close()
            tab_state.timer = nil
          end
          if existing_command ~= command then
            M.tabs_state[command] = vim.deepcopy(tab_state)
            if tab_state.bufnr then
              vim.api.nvim_buf_set_name(tab_state.bufnr, command .. ' - ' .. M.bufname_suffix)
            end
          end
        end
        tab_state = M.get_or_create_tab_state(command, { command = command })

        if not tab_state then
          print 'Failed to create tab state'
          return
        end

        tab_state.delimiter = tostring(delimiter)
        tab_state.interval = interval

        -- Start the loop
        tab_state.timer = vim.uv.new_timer()
        if not tab_state.timer then
          print 'Failed to create timer'
          return
        end
        tab_state.timer:start(0, tab_state.interval * 1000, function()
          local cmd_args = vim.split(full_command, ' ', { trimempty = true })
          vim.system(cmd_args, { text = true }, function(result)
            local output = result.stdout
            if not output or output == '' then
              print('No output from command: ' .. command)
              if result.stderr and result.stderr ~= '' then
                print('Error: ' .. result.stderr)
              end
              return
            end
            tab_state.raw_lines = vim.split(output, '\n')
            vim.schedule(function()
              local raw_parse_res = M.raw_parse(tab_state.raw_lines, tab_state.delimiter)
              tab_state.headers = raw_parse_res.headers
              tab_state.lines = raw_parse_res.lines
              tab_state.col_widths = raw_parse_res.col_widths
              if tab_state.sort_column then
                M.sort_by_column(tab_state.sort_column, tab_state.sort_direction)
              else
                -- Create or update the buffer
                M.display_table(tab_state.command)
              end
              -- Update winbar with last refresh timestamp only if the buffer is the current one
              local last_refresh = os.date '%Y-%m-%d %H:%M:%S'
              local current_bufnr = vim.api.nvim_get_current_buf()
              if tab_state.bufnr == current_bufnr then
                vim.opt_local.winbar = string.format('Tabular: %s (%ss) | Last refresh: %s', command, interval, last_refresh)
              end
            end)
          end)
        end)
      end)
    end)
  end)
end

--- Unload function to clean up resources when buffer is deleted
function M.unload(bufnr)
  if not bufnr then
    print 'no bufnr'
    return
  end

  -- Find the tab state associated with this buffer
  local tab_state = M.find_tab_state_by_bufnr(bufnr)
  if not tab_state then
    return
  end

  -- Stop and close the timer if it exists
  if tab_state.timer then
    if not tab_state.timer:is_closing() then
      tab_state.timer:stop()
      tab_state.timer:close()
    end
    tab_state.timer = nil
  end

  -- Clear namespaces if they exist
  if tab_state.ns_headers then
    vim.api.nvim_buf_clear_namespace(bufnr, tab_state.ns_headers, 0, -1)
  end
  if tab_state.ns_sort then
    vim.api.nvim_buf_clear_namespace(bufnr, tab_state.ns_sort, 0, -1)
  end
  if tab_state.ns_filter then
    vim.api.nvim_buf_clear_namespace(bufnr, tab_state.ns_filter, 0, -1)
  end

  -- Remove the tab state from our tracking table
  local command_to_remove = tab_state.command
  if command_to_remove then
    M.tabs_state[command_to_remove] = nil
  end

  print('Cleaned up tabular resources for buffer ' .. bufnr)
end

function M.ec2_instance_selector_parse(raw_lines)
  local first_line = raw_lines[1] or ''
  local second_line = raw_lines[2] or ''
  local header_dashes = vim.split(second_line, '%s+', { trimempty = true })
  local header_spaces = vim.split(second_line, '-+', { trimempty = true })
  local dashes_lengths = vim.tbl_map(function(str)
    return #str
  end, header_dashes)
  local spaces_lengths = vim.tbl_map(function(str)
    return #str
  end, header_spaces)

  local headers = {}
  local start_pos = 1
  for i, length in ipairs(dashes_lengths) do
    local header = first_line:sub(start_pos, start_pos + length - 1)
    table.insert(headers, vim.trim(header))
    start_pos = start_pos + length + spaces_lengths[i]
  end

  -- Parse data lines
  local lines = {}
  for i = 3, #raw_lines do
    local data_start_pos = 1
    local line = raw_lines[i]
    local row = {}
    for j, length in ipairs(dashes_lengths) do
      local word = line:sub(data_start_pos, data_start_pos + length - 1)
      table.insert(row, vim.trim(word))
      data_start_pos = data_start_pos + length + spaces_lengths[j]
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

function M.parse_buffer()
  local tabular_command = 'buffer'
  local bufnr = vim.api.nvim_get_current_buf()
  local buf_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local second_line = buf_lines[2] or ''
  -- Check if the second line contains dashes separated by spaces
  if second_line:match '[-=]+%s' then
    local parse_result = M.ec2_instance_selector_parse(buf_lines)
    M.get_or_create_tab_state(tabular_command, {
      command = tabular_command,
      raw_lines = buf_lines,
      headers = parse_result.headers,
      lines = parse_result.lines,
      col_widths = parse_result.col_widths,
    })
    M.display_table(tabular_command)
  else
    vim.ui.input({
      prompt = 'Enter delimiter❯ ',
      default = M.default_delimiter,
    }, function(input)
      if not input then
        return
      end

      local tab_state = M.get_or_create_tab_state(tabular_command, {
        command = tabular_command,
        raw_lines = buf_lines,
        delimiter = input,
      })

      if not tab_state then
        print 'Failed to create tab state'
        return
      end

      tab_state.raw_lines = buf_lines
      tab_state.delimiter = input

      local raw_parse_res = M.raw_parse(tab_state.raw_lines, tab_state.delimiter)
      tab_state.headers = raw_parse_res.headers
      tab_state.lines = raw_parse_res.lines
      tab_state.col_widths = raw_parse_res.col_widths
      M.display_table(tabular_command)
    end)
  end
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

  -- Set up autocmd to clean up resources when tabular buffers are deleted
  local tabular_group = vim.api.nvim_create_augroup('TabularCleanup', { clear = true })
  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
    group = tabular_group,
    callback = function(args)
      local bufnr = args.buf
      -- Check if this is a tabular buffer by checking filetype or buffer name
      local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })
      local bufname = vim.api.nvim_buf_get_name(bufnr)

      if filetype == 'tabular' or string.match(bufname, '.- ' .. M.bufname_suffix .. '$') then
        M.unload(bufnr)
      end
    end,
    desc = 'Clean up tabular resources when buffer is deleted',
  })
end

return M
