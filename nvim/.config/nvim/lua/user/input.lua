---@class SimpleInput
local M = {}

-- Store the original vim.ui.input
local original_input = vim.ui.input

-- Input history
local history = {}
local history_index = 0
local max_history = 50

-- Configuration
local config = {
  width = 60,
  row = nil, -- nil = auto-center vertically
  border = 'rounded',
  title_pos = 'center',
  icon = ' ', -- Pen icon on the left
  icon_hl = 'DiagnosticHint', -- Highlight group for the icon
}

--- Add a value to history
---@param value string
local function history_add(value)
  if not value or value == '' then
    return
  end
  -- Remove duplicate if exists
  for i, v in ipairs(history) do
    if v == value then
      table.remove(history, i)
      break
    end
  end
  -- Add to end
  table.insert(history, value)
  -- Trim if too long
  while #history > max_history do
    table.remove(history, 1)
  end
end

-- Create highlight groups
local function setup_highlights()
  vim.api.nvim_set_hl(0, 'SimpleInputBorder', { link = 'FloatBorder', default = true })
  vim.api.nvim_set_hl(0, 'SimpleInputNormal', { link = 'Normal', default = true })
  vim.api.nvim_set_hl(0, 'SimpleInputTitle', { link = 'FloatTitle', default = true })
end

---@param opts {prompt?: string, default?: string, completion?: string}
---@param on_confirm fun(value?: string)
function M.input(opts, on_confirm)
  assert(type(on_confirm) == 'function', '`on_confirm` must be a function')

  opts = opts or {}
  local prompt = opts.prompt or 'Input'
  prompt = vim.trim(prompt):gsub(':$', '')

  -- Store parent window and mode
  local parent_win = vim.api.nvim_get_current_win()
  local parent_mode = vim.fn.mode()

  -- Reset history index for new input session
  history_index = #history + 1
  local current_text = opts.default or ''

  -- Calculate window size and position
  local width = config.width
  local height = 1
  local ui = vim.api.nvim_list_uis()[1]
  local win_width = ui.width
  local win_height = ui.height
  local col = math.floor((win_width - width) / 2)
  local row = config.row or math.floor((win_height - height) / 2) - 2

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set buffer options using vim.bo (newer API)
  vim.bo[buf].buftype = 'prompt'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].filetype = 'prompt'
  vim.bo[buf].swapfile = false

  -- Set default text if provided
  if opts.default then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { opts.default })
  end

  -- Handle zindex for nested floating windows
  local parent_zindex = vim.api.nvim_win_get_config(parent_win).zindex
  local zindex = math.max((parent_zindex or 0) + 10, 50)

  -- Create floating window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = config.border,
    title = ' ' .. prompt .. ' ',
    title_pos = config.title_pos,
    noautocmd = true,
    zindex = zindex,
  })

  -- Explicitly clear statusline for this floating window
  vim.api.nvim_set_option_value('statusline', '', { win = win })

  -- Set window options using vim.wo (newer API)
  -- Use window-local call to ensure options are set
  vim.api.nvim_win_call(win, function()
    vim.wo.winhighlight =
      'NormalFloat:SimpleInputNormal,FloatBorder:SimpleInputBorder,FloatTitle:SimpleInputTitle,CursorLine:SimpleInputNormal,CursorColumn:SimpleInputNormal'
    vim.wo.cursorline = false
    vim.wo.cursorcolumn = false
    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.wo.signcolumn = 'no'
    vim.wo.foldcolumn = '0'
    vim.wo.spell = false
    vim.wo.list = false
    vim.wo.wrap = true
    vim.wo.colorcolumn = ''
    vim.wo.winbar = ''
    -- Add icon to statuscolumn on the left
    vim.wo.statuscolumn = ' %#' .. config.icon_hl .. '#' .. config.icon .. ' '
  end)

  -- Store original guicursor and set to vertical bar for input
  -- This prevents the horizontal cursor line from appearing as an underline
  local original_guicursor = vim.o.guicursor
  vim.o.guicursor = 'n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:ver25'

  -- Setup prompt
  vim.fn.prompt_setprompt(buf, '')

  --- Set buffer text and cursor position
  ---@param text string
  local function set_text(text)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })
    vim.api.nvim_win_set_cursor(win, { 1, #text })
  end

  -- Result handling
  local called = false
  local function close_and_callback(value)
    -- Prevent double-calling (prompt callback + keymap)
    if called then
      return
    end
    called = true

    -- Add to history if non-empty
    history_add(value)

    -- Restore original guicursor
    vim.o.guicursor = original_guicursor

    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    vim.cmd.stopinsert()

    -- Switch back to parent window first
    if vim.api.nvim_win_is_valid(parent_win) then
      vim.api.nvim_set_current_win(parent_win)
    end

    -- Call callback synchronously (required for LSP rename)
    on_confirm(value)

    -- Restore insert mode if needed (after callback)
    if parent_mode == 'i' and vim.api.nvim_win_is_valid(parent_win) then
      vim.schedule(function()
        vim.cmd 'startinsert'
      end)
    end
  end

  -- Set up prompt callbacks
  vim.fn.prompt_setcallback(buf, function(text)
    close_and_callback(text)
  end)

  vim.fn.prompt_setinterrupt(buf, function()
    close_and_callback(nil)
  end)

  -- Keymaps
  local opts_map = { noremap = true, silent = true, buffer = buf }

  -- Confirm on Enter (both insert and normal mode)
  vim.keymap.set({ 'i', 'n' }, '<CR>', function()
    local text = vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1]
    close_and_callback(text)
  end, opts_map)

  -- Cancel on Escape
  vim.keymap.set({ 'i', 'n' }, '<Esc>', function()
    close_and_callback(nil)
  end, opts_map)

  vim.keymap.set('n', 'q', function()
    close_and_callback(nil)
  end, opts_map)

  -- History navigation
  vim.keymap.set({ 'i', 'n' }, '<Up>', function()
    if #history == 0 then
      return
    end
    -- Save current text if at the end of history
    if history_index > #history then
      current_text = vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1] or ''
    end
    history_index = math.max(1, history_index - 1)
    set_text(history[history_index] or '')
  end, opts_map)

  vim.keymap.set({ 'i', 'n' }, '<Down>', function()
    if #history == 0 then
      return
    end
    history_index = math.min(#history + 1, history_index + 1)
    if history_index > #history then
      set_text(current_text)
    else
      set_text(history[history_index] or '')
    end
  end, opts_map)

  -- Optional: Auto-expand width based on text
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    buffer = buf,
    callback = function()
      if not vim.api.nvim_win_is_valid(win) then
        return
      end

      -- Prevent "buffer modified" warning
      vim.bo[buf].modified = false

      local text = vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1] or ''
      local text_width = vim.api.nvim_strwidth(text)
      local new_width = math.max(config.width, text_width + 5)
      local new_col = math.floor((win_width - new_width) / 2)

      vim.api.nvim_win_set_config(win, {
        relative = 'editor',
        width = new_width,
        height = height,
        row = row,
        col = new_col,
      })

      -- Keep cursor visible
      vim.fn.winrestview { leftcol = 0 }
    end,
  })

  -- Start in insert mode at the end of the line
  vim.cmd 'startinsert!'
  if opts.default then
    vim.api.nvim_win_set_cursor(win, { 1, #opts.default })
  end
end

-- Enable the custom input
function M.enable()
  setup_highlights()
  vim.ui.input = M.input
end

-- Disable and restore original input
function M.disable()
  vim.ui.input = original_input
end

-- Setup function
function M.setup(user_config)
  config = vim.tbl_deep_extend('force', config, user_config or {})
  M.enable()
end

return M
