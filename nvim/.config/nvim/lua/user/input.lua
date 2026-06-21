---@class SimpleInput
local M = {}

-- Store the original vim.ui.input
local original_input = vim.ui.input

-- Input history
local history = {}
local history_index = 0
local max_history = 50

-- Active input session (only one at a time)
local session = nil
local session_id = 0

-- Parent to restore after the outermost input in a chain finishes
---@type { win: number, mode: string }|nil
local root_context = nil

---@param mode string
---@return string `'i'`|`'n'`
local function normalize_mode(mode)
  if mode == 'i' or mode == 'R' or mode == 'Rv' or mode:find '^s' then
    return 'i'
  end
  return 'n'
end

local hl_ns = vim.api.nvim_create_namespace 'simple-input'

-- Configuration
local config = {
  width = 60,
  row = nil, -- nil = auto-center vertically
  border = nil, -- nil = |winborder| or 'rounded'
  title_pos = 'center',
  icon = '', -- Shown in float title
  icon_hl = 'DiagnosticHint',
}

---@param config_border string|nil
---@param winborder string|nil
---@return string|string[]
function M.resolve_border(config_border, winborder)
  if config_border ~= nil and config_border ~= '' then
    return config_border
  end
  if type(winborder) == 'string' and winborder ~= '' then
    return winborder
  end
  return 'rounded'
end

local function window_border()
  return M.resolve_border(config.border, vim.o.winborder)
end

local function float_title(prompt)
  return {
    { ' ' .. config.icon .. ' ', config.icon_hl },
    { prompt, 'SimpleInputTitle' },
  }
end

--- Byte column (0-indexed) for cursor at end of `text` (multibyte-safe).
---@param text string
---@return number
function M.end_cursor_col(text)
  local char_count = vim.fn.strchars(text)
  if char_count == 0 then
    return 0
  end
  local col = vim.fn.byteidx(text, char_count)
  return col < 0 and -1 or col
end

--- Float content width from display width of `text`, clamped to editor columns.
---@param text string
---@param min_width number
---@param max_cols number
---@param padding? number
---@return number
function M.compute_float_width(text, min_width, max_cols, padding)
  padding = padding or 5
  local text_width = vim.api.nvim_strwidth(text)
  local max_content = math.max(1, max_cols - 2)
  return math.min(math.max(min_width, text_width + padding), max_content)
end

--- Whether `scope` should anchor the float near the cursor.
---@param scope string|nil
---@return boolean
function M.scope_is_cursor(scope)
  return scope == 'cursor' or scope == 'line'
end

--- Completion base at end of `text` for `getcompletion()` pattern.
---@param text string
---@param method string
---@return string base
---@return number base_start byte index where `base` starts
function M.completion_base(text, method)
  local is_fs = method == 'file' or method == 'file_in_path' or method == 'dir' or method == 'dir_in_path'
  local pattern = is_fs and '[[:fname:]]*$' or '[[:keyword:]]*$'
  local start = vim.fn.match(text, pattern)
  if start < 0 then
    return '', vim.fn.strlen(text)
  end
  return vim.fn.strpart(text, start), start
end

--- Footer text for active completion navigation.
---@param id number 0 = base, 1..total = candidate index
---@param total number
---@return string
function M.format_completion_footer(id, total)
  if total == 0 then
    return ''
  end
  return string.format(' %d/%d ', id, total)
end

--- Validate `vim.ui.input` highlight ranges for extmarks.
--- Each range is `{ byte_start, byte_end, hl_group }` with 0-based byte indexes;
--- `byte_end` is exclusive (same as |input()| highlight callback).
---@param text string
---@param ranges table|nil
---@return { start_col: number, end_col: number, hl: string }[]
function M.normalize_highlight_ranges(text, ranges)
  local result = {}
  if type(ranges) ~= 'table' then
    return result
  end

  local len = vim.fn.strlen(text)
  for _, r in ipairs(ranges) do
    if type(r) == 'table' and type(r[1]) == 'number' and type(r[2]) == 'number' and type(r[3]) == 'string' then
      local start_col, end_col = r[1], r[2]
      if start_col >= 0 and end_col > start_col and end_col <= len then
        table.insert(result, { start_col = start_col, end_col = end_col, hl = r[3] })
      end
    end
  end

  return result
end

--- Whether an input session is currently open.
---@return boolean
function M.is_active()
  return session ~= nil
end

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
  vim.api.nvim_set_hl(0, 'SimpleInputHint', { link = 'Comment', default = true })
end

---@param opts {prompt?: string, default?: string, completion?: string, scope?: string, highlight?: fun(text: string): {[1]: number, [2]: number, [3]: string}[]}
---@param on_confirm fun(value?: string)
function M.input(opts, on_confirm)
  assert(type(on_confirm) == 'function', '`on_confirm` must be a function')

  if session ~= nil then
    on_confirm(nil)
    return
  end

  opts = opts or {}
  local prompt = opts.prompt or 'Input'
  prompt = vim.trim(prompt):gsub(':$', '')

  if root_context == nil then
    root_context = {
      win = vim.api.nvim_get_current_win(),
      mode = normalize_mode(vim.fn.mode()),
    }
  end

  session_id = session_id + 1
  local my_session = session_id

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

  -- Anchor near the cursor for cursor/line scopes, centered otherwise.
  -- Anchor to a fixed buffer position in the current window (`bufpos`) so the
  -- float stays put while typing instead of re-anchoring to its own cursor.
  local near_cursor = M.scope_is_cursor(opts.scope)
  local relative = near_cursor and 'win' or 'editor'
  local anchor_win, anchor_bufpos
  if near_cursor then
    anchor_win = vim.api.nvim_get_current_win()
    local cpos = vim.api.nvim_win_get_cursor(anchor_win)
    anchor_bufpos = { cpos[1] - 1, cpos[2] }
    row, col = 1, 0
  end

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set buffer options using vim.bo (newer API)
  vim.bo[buf].buftype = 'prompt'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].filetype = 'prompt'
  vim.bo[buf].swapfile = false

  -- Handle zindex for nested floating windows
  local parent_win = vim.api.nvim_get_current_win()
  local parent_zindex = vim.api.nvim_win_is_valid(parent_win) and vim.api.nvim_win_get_config(parent_win).zindex or 0
  local zindex = math.max((parent_zindex or 0) + 10, 50)

  -- Create floating window
  local border = window_border()

  local win_opts = {
    relative = relative,
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = border,
    title = float_title(prompt),
    title_pos = config.title_pos,
    noautocmd = true,
    zindex = zindex,
  }
  if near_cursor then
    win_opts.win = anchor_win
    win_opts.bufpos = anchor_bufpos
  end

  local win = vim.api.nvim_open_win(buf, true, win_opts)

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
    vim.wo.statuscolumn = ''
  end)

  -- Store original guicursor and set to vertical bar for input
  -- This prevents the horizontal cursor line from appearing as an underline
  local original_guicursor = vim.o.guicursor
  vim.o.guicursor = 'n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:ver25'

  -- Setup prompt
  vim.fn.prompt_setprompt(buf, '')

  -- Set default text after prompt setup, matching Snacks input behavior.
  if opts.default then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { opts.default })
  end

  ---@type { base: string, base_start: number, items: string[], id: number }|nil
  local complete_state = nil
  local suppress_complete_clear = false

  local function completion_footer()
    if complete_state == nil or #complete_state.items == 0 then
      return nil
    end
    return {
      { M.format_completion_footer(complete_state.id, #complete_state.items), 'SimpleInputHint' },
    }
  end

  local function refresh_highlights()
    vim.api.nvim_buf_clear_namespace(buf, hl_ns, 0, -1)
    if not vim.is_callable(opts.highlight) then
      return
    end

    local text = vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1] or ''
    local ok, ranges = pcall(opts.highlight, text)
    if not ok then
      return
    end

    for _, r in ipairs(M.normalize_highlight_ranges(text, ranges)) do
      vim.api.nvim_buf_set_extmark(buf, hl_ns, 0, r.start_col, {
        end_row = 0,
        end_col = r.end_col,
        hl_group = r.hl,
        strict = false,
      })
    end
  end

  --- Set buffer text and cursor position
  ---@param text string
  local function set_text(text)
    suppress_complete_clear = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })
    vim.api.nvim_win_set_cursor(win, { 1, M.end_cursor_col(text) })
    refresh_highlights()
    suppress_complete_clear = false
  end

  local function refresh_float_layout()
    if not vim.api.nvim_win_is_valid(win) then
      return
    end

    ui = vim.api.nvim_list_uis()[1]
    win_width = ui.width
    win_height = ui.height

    local text = vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1] or ''
    local new_width = M.compute_float_width(text, config.width, win_width)

    local new_col, new_row = 0, 1
    if not near_cursor then
      new_col = math.floor((win_width - new_width) / 2)
      new_row = config.row or math.floor((win_height - height) / 2) - 2
    end

    local win_config = {
      relative = relative,
      width = new_width,
      height = height,
      row = new_row,
      col = new_col,
      style = 'minimal',
      border = border,
      title = float_title(prompt),
      title_pos = config.title_pos,
      zindex = zindex,
    }
    if near_cursor then
      win_config.win = anchor_win
      win_config.bufpos = anchor_bufpos
    end
    local footer = completion_footer()
    if footer then
      win_config.footer = footer
      win_config.footer_pos = 'right'
    end
    vim.api.nvim_win_set_config(win, win_config)

    vim.fn.winrestview { leftcol = 0 }
  end

  local resize_au = vim.api.nvim_create_autocmd('VimResized', {
    callback = refresh_float_layout,
  })

  local colorscheme_au = vim.api.nvim_create_autocmd('ColorScheme', {
    callback = function()
      setup_highlights()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_call(win, function()
          vim.wo.winhighlight =
            'NormalFloat:SimpleInputNormal,FloatBorder:SimpleInputBorder,FloatTitle:SimpleInputTitle,CursorLine:SimpleInputNormal,CursorColumn:SimpleInputNormal'
        end)
      end
      refresh_highlights()
    end,
  })

  local text_change_au = vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    buffer = buf,
    callback = function()
      vim.bo[buf].modified = false
      if not suppress_complete_clear then
        complete_state = nil
      end
      refresh_float_layout()
      refresh_highlights()
    end,
  })

  if opts.default then
    refresh_highlights()
  end

  session = my_session

  local function cleanup_autocmds()
    pcall(vim.api.nvim_del_autocmd, resize_au)
    pcall(vim.api.nvim_del_autocmd, colorscheme_au)
    pcall(vim.api.nvim_del_autocmd, text_change_au)
  end

  -- Result handling
  local called = false
  local function close_and_callback(value)
    -- Prevent double-calling (prompt callback + keymap)
    if called then
      return
    end
    called = true

    cleanup_autocmds()
    if session == my_session then
      session = nil
    end

    -- Add to history if non-empty
    history_add(value)

    -- Restore original guicursor
    vim.o.guicursor = original_guicursor

    pcall(vim.api.nvim_win_close, win, true)
    vim.cmd.stopinsert()

    local tab_before = vim.fn.tabpagenr()
    local win_before = vim.api.nvim_get_current_win()

    on_confirm(value)

    -- Chained vim.ui.input sets session again inside on_confirm.
    if session ~= nil then
      return
    end

    local restore = root_context
    root_context = nil
    local navigated = vim.fn.tabpagenr() ~= tab_before or vim.api.nvim_get_current_win() ~= win_before
    if not navigated and restore ~= nil and vim.api.nvim_win_is_valid(restore.win) then
      vim.api.nvim_set_current_win(restore.win)
    end

    -- Defer mode restore + redraw so |print()| / |echom| from on_confirm stay visible
    -- (second |stopinsert| was clearing the message line; |lazyredraw| needs |redraw!|).
    vim.schedule(function()
      if session ~= nil then
        return
      end
      if restore ~= nil and restore.mode == 'i' and restore.win and vim.api.nvim_win_is_valid(restore.win) then
        vim.cmd 'startinsert'
      end
      vim.cmd 'redraw!'
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

  -- Cancel on Escape / Ctrl-C (same as |input()| and mini.input)
  vim.keymap.set({ 'i', 'n' }, '<Esc>', function()
    close_and_callback(nil)
  end, opts_map)

  vim.keymap.set({ 'i', 'n' }, '<C-c>', function()
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

  if opts.completion and opts.completion ~= '' then
    local function cycle_completion(forward)
      local text = vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1] or ''
      if complete_state == nil then
        local base, base_start = M.completion_base(text, opts.completion)
        local ok, items = pcall(vim.fn.getcompletion, base, opts.completion)
        if not ok or #items == 0 then
          return
        end
        complete_state = { base = base, base_start = base_start, items = items, id = 0 }
      end

      local n = #complete_state.items
      local delta = forward and 1 or -1
      complete_state.id = (complete_state.id + delta) % (n + 1)
      local shown = complete_state.id == 0 and complete_state.base or complete_state.items[complete_state.id]
      local prefix = vim.fn.strpart(text, 0, complete_state.base_start)
      set_text(prefix .. shown)
      refresh_float_layout()
    end

    vim.keymap.set('i', '<Tab>', function()
      cycle_completion(true)
    end, opts_map)

    vim.keymap.set('i', '<S-Tab>', function()
      cycle_completion(false)
    end, opts_map)
  end

  -- defer_fn: chained opens run inside another input's close callback (after stopinsert).
  vim.defer_fn(function()
    if session ~= my_session or not vim.api.nvim_win_is_valid(win) then
      return
    end
    vim.api.nvim_win_call(win, function()
      vim.cmd 'startinsert!'
    end)
    if opts.default then
      vim.api.nvim_win_set_cursor(win, { 1, M.end_cursor_col(opts.default) })
    end
  end, 0)
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
