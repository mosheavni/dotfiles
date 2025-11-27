---@class SimpleInput
local M = {}

-- Store the original vim.ui.input
local original_input = vim.ui.input

-- Configuration
local config = {
  width = 60,
  row = nil, -- nil = auto-center vertically
  border = 'rounded',
  title_pos = 'center',
  icon = ' ', -- Pen icon on the left
  icon_hl = 'DiagnosticHint', -- Highlight group for the icon
}

-- Create highlight groups
local function setup_highlights()
  vim.api.nvim_set_hl(0, 'SimpleInputBorder', { link = 'FloatBorder', default = true })
  vim.api.nvim_set_hl(0, 'SimpleInputNormal', { link = 'Normal', default = true })
  vim.api.nvim_set_hl(0, 'SimpleInputTitle', { link = 'FloatTitle', default = true })
end

---@param opts {prompt?: string, default?: string, completion?: string}
---@param on_confirm fun(value?: string)
function M.input(opts, on_confirm)
  opts = opts or {}
  local prompt = opts.prompt or 'Input'
  prompt = vim.trim(prompt):gsub(':$', '')

  -- Store parent window and mode
  local parent_win = vim.api.nvim_get_current_win()
  local parent_mode = vim.fn.mode()

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

  -- Result handling
  local function close_and_callback(value)
    -- Restore original guicursor
    vim.o.guicursor = original_guicursor

    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    vim.cmd.stopinsert()
    vim.schedule(function()
      if vim.api.nvim_win_is_valid(parent_win) then
        vim.api.nvim_set_current_win(parent_win)
        if parent_mode == 'i' then
          vim.cmd 'startinsert'
        end
      end
      on_confirm(value)
    end)
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

  -- Optional: Auto-expand width based on text
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    buffer = buf,
    callback = function()
      if not vim.api.nvim_win_is_valid(win) then
        return
      end

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
