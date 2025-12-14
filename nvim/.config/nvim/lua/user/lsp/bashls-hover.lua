local M = {}

-- State to track open hover windows
local state = {
  lsp_winid = nil,
  lsp_bufnr = nil,
  tldr_winid = nil,
  tldr_bufnr = nil,
  current_view = 'lsp', -- 'lsp' or 'tldr'
  cword = nil,
  lsp_hover_result = nil,
  autocmd_ids = {}, -- Track autocmd IDs to clean them up
  toggling = false, -- Flag to prevent autocmd cleanup during toggle
  source_bufnr = nil, -- Buffer where hover was triggered
  source_pos = nil, -- Cursor position where hover was triggered
}

-- Clean up state when windows are closed
local function cleanup_state()
  -- Clear autocmds
  for _, id in ipairs(state.autocmd_ids) do
    pcall(vim.api.nvim_del_autocmd, id)
  end

  state.lsp_winid = nil
  state.lsp_bufnr = nil
  state.tldr_winid = nil
  state.tldr_bufnr = nil
  state.current_view = 'lsp'
  -- Don't clear state.cword - keep it for potential re-toggling
  -- It will be overwritten on the next hover anyway
  state.lsp_hover_result = nil
  state.autocmd_ids = {}
  state.toggling = false
  state.source_bufnr = nil
  state.source_pos = nil
end

-- Close all hover windows
local function close_hover_windows()
  if state.toggling then
    return -- Don't close during toggle
  end

  if state.lsp_winid and vim.api.nvim_win_is_valid(state.lsp_winid) then
    vim.api.nvim_win_close(state.lsp_winid, true)
  end
  if state.tldr_winid and vim.api.nvim_win_is_valid(state.tldr_winid) then
    vim.api.nvim_win_close(state.tldr_winid, true)
  end
  cleanup_state()
end

-- Get tldr content for a command
local function get_tldr_content(cmd)
  if not cmd or cmd == '' then
    return { 'Error: No command specified' }
  end

  local handle = io.popen('tldr ' .. vim.fn.shellescape(cmd) .. ' 2>&1')
  if not handle then
    return { 'Error: Failed to execute tldr command' }
  end

  local result = handle:read('*a')
  handle:close()

  if result:match('^Page not found') or result:match('not found') then
    return { 'No tldr page found for: ' .. cmd }
  end

  -- Split result into lines, preserving empty lines for formatting
  local lines = vim.split(result, '\n', { plain = true, trimempty = false })

  return #lines > 0 and lines or { 'No tldr documentation available' }
end

-- Create a floating window with content
local function create_float_window(lines, title, enter)
  -- Create buffer
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].filetype = 'markdown'

  -- Get editor dimensions
  local ui = vim.api.nvim_list_uis()[1]
  local win_width = ui.width
  local win_height = ui.height

  -- Calculate window size (larger than before)
  local width = math.min(120, math.floor(win_width * 0.8))
  local height = math.min(math.max(40, #lines + 2), math.floor(win_height * 0.8))

  -- Calculate position (center)
  local row = math.floor((win_height - height) / 2)
  local col = math.floor((win_width - width) / 2)

  -- Window options
  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = title,
    title_pos = 'center',
  }

  -- Create window (enter if requested)
  local winid = vim.api.nvim_open_win(bufnr, enter or false, opts)

  -- Set window options
  vim.wo[winid].wrap = true
  vim.wo[winid].linebreak = true

  return winid, bufnr
end

-- Set up autocmd to close windows when leaving
local function setup_close_autocmd(bufnr)
  local id = vim.api.nvim_create_autocmd({ 'BufLeave', 'WinLeave' }, {
    buffer = bufnr,
    callback = function()
      -- Small delay to allow toggling
      vim.defer_fn(function()
        if not state.toggling then
          close_hover_windows()
        end
      end, 50)
    end,
  })
  table.insert(state.autocmd_ids, id)
end

-- Set up autocmd to close windows when cursor moves in source buffer
local function setup_cursor_moved_autocmd()
  if not state.source_bufnr or not vim.api.nvim_buf_is_valid(state.source_bufnr) then
    return
  end

  local id = vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    buffer = state.source_bufnr,
    callback = function()
      -- Get current cursor position
      local current_pos = vim.api.nvim_win_get_cursor(0)

      -- Check if cursor moved away from hover position
      if not state.source_pos or current_pos[1] ~= state.source_pos[1] or current_pos[2] ~= state.source_pos[2] then
        -- Don't close if we're currently in one of the hover windows
        local current_win = vim.api.nvim_get_current_win()
        if current_win == state.lsp_winid or current_win == state.tldr_winid then
          return
        end

        close_hover_windows()
      end
    end,
  })
  table.insert(state.autocmd_ids, id)
end

-- Toggle between LSP hover and tldr
local function toggle_view()
  state.toggling = true

  if state.current_view == 'lsp' then
    -- Switch to tldr
    if state.lsp_winid and vim.api.nvim_win_is_valid(state.lsp_winid) then
      vim.api.nvim_win_close(state.lsp_winid, true)
      state.lsp_winid = nil
    end

    if not state.tldr_bufnr or not vim.api.nvim_buf_is_valid(state.tldr_bufnr) then
      -- Create tldr window if it doesn't exist
      local tldr_lines = get_tldr_content(state.cword)
      state.tldr_winid, state.tldr_bufnr = create_float_window(tldr_lines, ' tldr: ' .. state.cword .. ' ', true)
    else
      -- Recreate tldr window with existing buffer content
      local tldr_lines = vim.api.nvim_buf_get_lines(state.tldr_bufnr, 0, -1, false)
      state.tldr_winid, state.tldr_bufnr = create_float_window(tldr_lines, ' tldr: ' .. state.cword .. ' ', true)
    end

    -- Set up keymaps for tldr window
    vim.keymap.set('n', '<Tab>', toggle_view, { buffer = state.tldr_bufnr, silent = true })
    vim.keymap.set('n', 'q', close_hover_windows, { buffer = state.tldr_bufnr, silent = true })
    vim.keymap.set('n', '<Esc>', close_hover_windows, { buffer = state.tldr_bufnr, silent = true })

    -- Auto-close when leaving window
    setup_close_autocmd(state.tldr_bufnr)

    state.current_view = 'tldr'
  else
    -- Switch to LSP
    if state.tldr_winid and vim.api.nvim_win_is_valid(state.tldr_winid) then
      vim.api.nvim_win_close(state.tldr_winid, true)
      state.tldr_winid = nil
    end

    if not state.lsp_bufnr or not vim.api.nvim_buf_is_valid(state.lsp_bufnr) then
      -- Shouldn't happen, but handle gracefully
      vim.notify('LSP hover buffer no longer available', vim.log.levels.WARN)
      state.toggling = false
      return
    end

    -- Recreate LSP window with existing buffer content
    local lsp_lines = vim.api.nvim_buf_get_lines(state.lsp_bufnr, 0, -1, false)
    state.lsp_winid, state.lsp_bufnr = create_float_window(lsp_lines, ' LSP Hover (Tab for tldr) ', true)

    -- Set up keymaps for LSP window
    vim.keymap.set('n', '<Tab>', toggle_view, { buffer = state.lsp_bufnr, silent = true })
    vim.keymap.set('n', 'q', close_hover_windows, { buffer = state.lsp_bufnr, silent = true })
    vim.keymap.set('n', '<Esc>', close_hover_windows, { buffer = state.lsp_bufnr, silent = true })

    -- Apply markdown syntax highlighting
    vim.bo[state.lsp_bufnr].syntax = 'markdown'

    -- Auto-close when leaving window
    setup_close_autocmd(state.lsp_bufnr)

    state.current_view = 'lsp'
  end

  -- Reset toggling flag after the autocmd delay period to prevent race condition
  vim.defer_fn(function()
    state.toggling = false
  end, 100)
end

-- Custom hover handler for bashls
M.hover = function()
  -- Get word under cursor
  local cword = vim.fn.expand('<cword>')

  -- Check if hover window is already open for the same word
  if state.cword == cword then
    -- Second K press - focus the existing window
    if state.current_view == 'lsp' and state.lsp_winid and vim.api.nvim_win_is_valid(state.lsp_winid) then
      vim.api.nvim_set_current_win(state.lsp_winid)
      return
    elseif state.current_view == 'tldr' and state.tldr_winid and vim.api.nvim_win_is_valid(state.tldr_winid) then
      vim.api.nvim_set_current_win(state.tldr_winid)
      return
    end
  end

  -- First K press or different word - create new hover
  state.cword = cword

  -- Close any existing hover windows
  close_hover_windows()

  -- Track source buffer and cursor position
  state.source_bufnr = vim.api.nvim_get_current_buf()
  state.source_pos = vim.api.nvim_win_get_cursor(0)

  -- Set up autocmd to close hover when cursor moves
  setup_cursor_moved_autocmd()

  -- Get bashls client for position encoding
  local clients = vim.lsp.get_clients({ bufnr = 0, name = 'bashls' })
  local client = clients[1]
  if not client then
    vim.notify('bashls client not found', vim.log.levels.WARN)
    return
  end

  -- Request LSP hover
  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
  vim.lsp.buf_request(0, 'textDocument/hover', params, function(err, result, ctx, config)
    if err then
      vim.notify('LSP hover error: ' .. tostring(err), vim.log.levels.ERROR)
      return
    end

    -- Store the result
    state.lsp_hover_result = result

    if not result or not result.contents then
      -- No LSP hover available, just show tldr
      local tldr_lines = get_tldr_content(cword)
      state.tldr_winid, state.tldr_bufnr = create_float_window(tldr_lines, ' tldr: ' .. cword .. ' ')
      state.current_view = 'tldr'

      -- Set up keymaps
      vim.keymap.set('n', 'q', close_hover_windows, { buffer = state.tldr_bufnr, silent = true })
      vim.keymap.set('n', '<Esc>', close_hover_windows, { buffer = state.tldr_bufnr, silent = true })

      -- Auto-close when leaving window
      setup_close_autocmd(state.tldr_bufnr)

      return
    end

    -- Show LSP hover in a floating window
    local hover_lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
    -- Trim empty lines using vim.split with trimempty
    hover_lines = vim.split(table.concat(hover_lines, '\n'), '\n', { trimempty = true })

    if vim.tbl_isempty(hover_lines) then
      -- No content, just show tldr
      local tldr_lines = get_tldr_content(cword)
      state.tldr_winid, state.tldr_bufnr = create_float_window(tldr_lines, ' tldr: ' .. cword .. ' ')
      state.current_view = 'tldr'

      -- Set up keymaps
      vim.keymap.set('n', 'q', close_hover_windows, { buffer = state.tldr_bufnr, silent = true })
      vim.keymap.set('n', '<Esc>', close_hover_windows, { buffer = state.tldr_bufnr, silent = true })

      -- Auto-close when leaving window
      setup_close_autocmd(state.tldr_bufnr)

      return
    end

    -- Create LSP hover window
    state.lsp_winid, state.lsp_bufnr = create_float_window(hover_lines, ' LSP Hover (Tab for tldr) ')
    state.current_view = 'lsp'

    -- Set up keymaps for LSP window
    vim.keymap.set('n', '<Tab>', toggle_view, { buffer = state.lsp_bufnr, silent = true })
    vim.keymap.set('n', 'q', close_hover_windows, { buffer = state.lsp_bufnr, silent = true })
    vim.keymap.set('n', '<Esc>', close_hover_windows, { buffer = state.lsp_bufnr, silent = true })

    -- Apply markdown syntax highlighting
    vim.bo[state.lsp_bufnr].syntax = 'markdown'

    -- Auto-close when leaving window
    setup_close_autocmd(state.lsp_bufnr)
  end)
end

return M
