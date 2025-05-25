local M = {
  raw_lines = {},
  headers = {},
  lines = {},
  delimiter = '\t',
  pattern_delimiter = nil,
  current_filter = nil,
  sort_column = nil,
  sort_direction = 1, -- 1 for ascending, -1 for descending
  col_widths = {}, -- Add this line to store column widths
  ns_headers = vim.api.nvim_create_namespace 'tabular_headers',
  ns_sort = vim.api.nvim_create_namespace 'tabular_sort',
}

function M.parse_buffer()
  vim.ui.input({
    prompt = 'Enter delimiter: ',
    default = M.delimiter,
  }, function(input)
    if not input then
      return
    end

    M.delimiter = input
    -- For two spaces, we need a special pattern
    if M.delimiter == '  ' then
      M.pattern_delimiter = '  +'
    else
      -- Escape special pattern characters in delimiter
      M.pattern_delimiter = M.delimiter:gsub('[%(%)%.%%%+%-%*%?%[%]%^%$]', '%%%1')
    end

    local bufnr = vim.api.nvim_get_current_buf()
    M.raw_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    -- Parse headers
    M.headers = {}
    local header_line = M.raw_lines[1]
    local header_words = vim.split(header_line, M.pattern_delimiter)
    for _, word in ipairs(header_words) do
      table.insert(M.headers, vim.trim(word))
    end

    -- Parse data lines
    M.lines = {}
    for i = 2, #M.raw_lines do
      local line = M.raw_lines[i]
      local row = {}
      local words = vim.split(line, M.pattern_delimiter)
      for _, word in ipairs(words) do
        table.insert(row, vim.trim(word))
      end
      table.insert(M.lines, row)
    end

    M.display_table()
  end)
end

function M.sort_by_column(col_index)
  -- Store current cursor position
  local cursor = vim.api.nvim_win_get_cursor(0)

  if M.sort_column == col_index then
    M.sort_direction = M.sort_direction * -1
  else
    M.sort_column = col_index
    M.sort_direction = 1
  end

  table.sort(M.lines, function(a, b)
    -- Handle nil values by treating them as empty strings for comparison
    local val_a = a[col_index] or ''
    local val_b = b[col_index] or ''

    -- Try to convert to numbers if possible
    local num_a = tonumber(val_a)
    local num_b = tonumber(val_b)

    -- If both values are numbers, compare numerically
    if num_a and num_b then
      if M.sort_direction == 1 then
        return num_a < num_b
      else
        return num_a > num_b
      end
    end

    -- Otherwise compare as strings
    if M.sort_direction == 1 then
      return val_a < val_b
    else
      return val_a > val_b
    end
  end)

  M.display_table()

  -- Restore cursor position
  vim.api.nvim_win_set_cursor(0, cursor)
end

function M.filter_table()
  local input_params = { prompt = 'Filter: ' }
  if M.current_filter then
    input_params.default = M.current_filter
  end
  vim.ui.input(input_params, function(input)
    if input then
      M.current_filter = string.lower(input)
      M.display_table()
    end
  end)
end

function M.display_table()
  -- Calculate column widths
  M.col_widths = {}
  for i, header in ipairs(M.headers) do
    M.col_widths[i] = #header
    for _, row in ipairs(M.lines) do
      M.col_widths[i] = math.max(M.col_widths[i], #(row[i] or ''))
    end
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local is_new_display = vim.bo[bufnr].filetype ~= 'tabular'

  if is_new_display then
    -- Create new buffer for display and open in new tab
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.cmd 'tabnew'
    vim.api.nvim_set_current_buf(bufnr)
    vim.api.nvim_set_option_value('filetype', 'tabular', { buf = bufnr })
  end

  vim.api.nvim_set_option_value('modifiable', true, { buf = bufnr })

  -- Format and insert headers
  local formatted_headers = {}
  for i, header in ipairs(M.headers) do
    -- Pad the header with spaces to match column width
    local padded_header = header .. string.rep(' ', M.col_widths[i] - #header)
    table.insert(formatted_headers, padded_header)
  end
  local header_line = table.concat(formatted_headers, '    ')

  -- Create separator line with proper spacing
  local separator_parts = {}
  for _, width in ipairs(M.col_widths) do
    table.insert(separator_parts, string.rep('-', width))
  end
  local separator_line = table.concat(separator_parts, '----')
  local display_lines = { header_line, separator_line }

  -- Format and insert data lines
  for _, row in ipairs(M.lines) do
    local should_display = true
    if M.current_filter then
      should_display = false
      for _, cell in ipairs(row) do
        if string.find(string.lower(cell), M.current_filter) then
          should_display = true
          break
        end
      end
    end

    if should_display then
      local formatted_row = {}
      for i, cell in ipairs(row) do
        local value = cell or ''
        local padded_cell = value .. string.rep(' ', M.col_widths[i] - #value)
        table.insert(formatted_row, padded_cell)
      end
      table.insert(display_lines, table.concat(formatted_row, '    '))
    end
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, display_lines)
  -- Add header highlighting and sort indicator
  local pos = 0
  for i, width in ipairs(M.col_widths) do
    -- Add header highlighting
    vim.api.nvim_buf_set_extmark(bufnr, M.ns_headers, 0, pos, {
      end_col = pos + width,
      hl_group = 'Statement',
    })

    -- Add sort indicator if this is the sorted column
    if M.sort_column == i then
      local sort_indicator = M.sort_direction == 1 and '▲' or '▼'
      local header_length = #M.headers[i]
      vim.api.nvim_buf_set_extmark(bufnr, M.ns_sort, 0, pos + header_length, {
        virt_text = { { ' ' .. sort_indicator, 'Special' } },
        virt_text_pos = 'overlay',
        hl_mode = 'combine',
      })
    end

    pos = pos + width + 4 -- Change from +2 to +4 for the four-space separator
  end

  -- Set buffer options
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = bufnr })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = bufnr })

  -- Switch to the new buffer
  vim.api.nvim_set_current_buf(bufnr)

  -- set no wrap
  local winnr = vim.api.nvim_get_current_win()
  vim.api.nvim_set_option_value('wrap', false, { win = winnr })

  -- Set up keymaps
  local opts = { noremap = true, silent = true }
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gs', [[<cmd>lua require('user.tabular').sort_by_current_column()<CR>]], opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-f>', [[<cmd>lua require('user.tabular').filter_table()<CR>]], opts)

  -- Add numeric keymaps for column sorting
  for i = 1, #M.headers do
    vim.api.nvim_buf_set_keymap(bufnr, 'n', tostring(i), string.format([[<cmd>lua require('user.tabular').sort_by_column(%d)<CR>]], i), opts)
  end
end

function M.sort_by_current_column()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local col = cursor[2]

  -- Find which column the cursor is in based on column widths and spacing
  local current_pos = 0
  local current_column = 1
  for i, width in ipairs(M.col_widths) do
    local next_pos = current_pos + width
    if i < #M.col_widths then
      next_pos = next_pos + 2 -- Add space for the two-space separator
    end

    if col >= current_pos and col < next_pos then
      current_column = i
      break
    end

    current_pos = next_pos
  end

  M.sort_by_column(current_column)
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
end

return M
