local open_quickfix = function(new_split_cmd)
  local qf_idx = vim.fn.line '.'
  vim.cmd 'wincmd p'
  vim.cmd(new_split_cmd)
  vim.cmd(qf_idx .. 'cc')
end
vim.keymap.set('n', '<c-v>', function()
  open_quickfix 'vnew'
end, { buffer = true })

vim.keymap.set('n', '<C-s>', function()
  open_quickfix 'split'
end, { buffer = true })

vim.keymap.set('n', '<C-t>', function()
  open_quickfix 'tabnew'
end, { buffer = true, desc = 'Open quickfix item in new tab' })

local function remove_qf_items(start_line, end_line)
  local qf_list = vim.fn.getqflist()
  if #qf_list == 0 then
    return
  end

  -- Remove items in reverse order to maintain indices
  for i = end_line, start_line, -1 do
    if i >= 1 and i <= #qf_list then
      table.remove(qf_list, i)
    end
  end

  vim.fn.setqflist(qf_list, 'r')

  -- Position cursor at the start line or the last available item
  if #qf_list > 0 then
    local new_pos = math.min(start_line, #qf_list)
    vim.cmd(new_pos .. 'cfirst')
  end
  vim.cmd 'copen'
end

-- Operator function for removing quickfix items
_G.op = _G.op or {}
function _G.op.qf_delete_operator(_)
  local start_line = vim.fn.line "'["
  local end_line = vim.fn.line "']"
  remove_qf_items(start_line, end_line)
end

-- Set up the operator mapping
vim.keymap.set('n', 'd', function()
  vim.o.operatorfunc = 'v:lua.op.qf_delete_operator'
  return 'g@'
end, { expr = true, buffer = true, desc = 'Delete quickfix items' })

-- Also support dd directly for line-wise delete
vim.keymap.set('n', 'dd', function()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  remove_qf_items(line, line)
end, { buffer = true, desc = 'Delete quickfix item' })

-- map yy to yank file name
vim.keymap.set('n', 'yy', function()
  local line = vim.api.nvim_get_current_line()
  local filename = vim.split(line, ' ')[1]
  vim.fn.setreg('"', filename)
  vim.notify('Copied ' .. filename .. ' to register')
end, { remap = false, buffer = true })

-- Toggleable keymap hints (g?)
local Hints = require 'user.hints'
local hints = Hints.new('Quickfix - Available Keymaps', {
  { key = '<CR>', desc = 'Open item' },
  { key = '<C-v>', desc = 'Open in vertical split' },
  { key = '<C-s>', desc = 'Open in horizontal split' },
  { key = '<C-t>', desc = 'Open in new tab' },
  { key = 'dd', desc = 'Delete item' },
  { key = 'd{motion}', desc = 'Delete items' },
  { key = 'yy', desc = 'Yank file name' },
  { key = 'p', desc = 'Toggle preview' },
  { key = 'q', desc = 'Close quickfix' },
  { key = 'g?', desc = 'Toggle these hints' },
})

vim.keymap.set('n', 'g?', hints.toggle, { buffer = true, desc = 'Toggle quickfix hints' })

-- Floating, Treesitter-highlighted preview of the entry under the cursor
-- (lightweight replacement for nvim-bqf's preview).
local preview_ns = vim.api.nvim_create_namespace 'qf_preview'
local preview = { win = nil, buf = nil, fname = nil, enabled = true }

local function preview_win_valid()
  return preview.win ~= nil and vim.api.nvim_win_is_valid(preview.win)
end

local function close_preview()
  if preview_win_valid() then
    vim.api.nvim_win_close(preview.win, true)
  end
  if preview.buf ~= nil and vim.api.nvim_buf_is_valid(preview.buf) then
    vim.api.nvim_buf_delete(preview.buf, { force = true })
  end
  preview.win, preview.buf, preview.fname = nil, nil, nil
end

--- Resolve the quickfix/location-list entry under the cursor.
---@return { bufnr: integer, fname: string, lnum: integer }|nil
local function current_entry()
  local win = vim.api.nvim_get_current_win()
  local info = vim.fn.getwininfo(win)[1]
  if not info or info.quickfix == 0 then
    return nil
  end
  local list = info.loclist == 1 and vim.fn.getloclist(win) or vim.fn.getqflist()
  local item = list[vim.fn.line '.']
  if not item or item.valid == 0 or not item.bufnr or item.bufnr == 0 then
    return nil
  end
  local fname = vim.api.nvim_buf_get_name(item.bufnr)
  if fname == '' then
    return nil
  end
  return { bufnr = item.bufnr, fname = fname, lnum = math.max(item.lnum, 1) }
end

---@return string[]|nil
local function file_lines(bufnr, fname)
  if vim.api.nvim_buf_is_loaded(bufnr) then
    return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  end
  if vim.fn.filereadable(fname) == 1 then
    return vim.fn.readfile(fname)
  end
  return nil
end

local function detect_ft(bufnr, fname)
  local ft = vim.bo[bufnr].filetype
  if ft ~= '' then
    return ft
  end
  return vim.filetype.match { filename = fname }
end

-- Start Treesitter highlighting the same way lua/plugins/treesitter.lua does.
local function start_treesitter(buf, ft)
  local lang = ft and ft ~= '' and vim.treesitter.language.get_lang(ft)
  if not lang then
    return
  end
  local ok, installed = pcall(vim.treesitter.language.add, lang)
  if not ok or not installed then
    return
  end
  if not vim.treesitter.query.get(lang, 'highlights') then
    return
  end
  pcall(vim.treesitter.start, buf, lang)
end

-- A small preview docked just above the quickfix window.
local PREVIEW_HEIGHT = 12

local function preview_win_config(entry)
  local qf_row = vim.api.nvim_win_get_position(0)[1]
  -- Leave room for the float's border (2 rows) above the qf window.
  local height = math.min(PREVIEW_HEIGHT, math.max(qf_row - 2, 3))
  return {
    relative = 'editor',
    row = math.max(qf_row - height - 2, 0),
    col = 0,
    width = math.max(vim.o.columns - 2, 1),
    height = height,
    style = 'minimal',
    border = 'rounded',
    focusable = false,
    noautocmd = true,
    zindex = 40,
    title = ' ' .. vim.fn.fnamemodify(entry.fname, ':t') .. ':' .. entry.lnum .. ' ',
    title_pos = 'left',
  }
end

local function update_preview()
  if not preview.enabled then
    return
  end
  local entry = current_entry()
  if not entry then
    return close_preview()
  end

  -- Build (or reuse) a scratch buffer holding the target file's contents.
  if preview.fname ~= entry.fname or not (preview.buf and vim.api.nvim_buf_is_valid(preview.buf)) then
    local lines = file_lines(entry.bufnr, entry.fname)
    if not lines then
      return close_preview()
    end
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = 'wipe'
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    start_treesitter(buf, detect_ft(entry.bufnr, entry.fname))
    local old = preview.buf
    preview.buf, preview.fname = buf, entry.fname
    if preview_win_valid() then
      vim.api.nvim_win_set_buf(preview.win, buf)
    end
    if old and vim.api.nvim_buf_is_valid(old) and old ~= buf then
      vim.api.nvim_buf_delete(old, { force = true })
    end
  end

  -- Open or reposition the floating window.
  local config = preview_win_config(entry)
  if preview_win_valid() then
    vim.api.nvim_win_set_config(preview.win, config)
  else
    preview.win = vim.api.nvim_open_win(preview.buf, false, config)
  end
  -- Re-apply on every update: nvim_win_set_config re-applies style='minimal',
  -- which would otherwise reset number/cursorline/etc.
  vim.wo[preview.win].wrap = false
  vim.wo[preview.win].number = true
  vim.wo[preview.win].relativenumber = false
  vim.wo[preview.win].cursorline = true
  vim.wo[preview.win].signcolumn = 'no'
  vim.wo[preview.win].foldenable = false
  vim.wo[preview.win].winhighlight = 'NormalFloat:Normal,CursorLine:CursorLine'

  -- Highlight and center the target line.
  local lnum = math.min(entry.lnum, vim.api.nvim_buf_line_count(preview.buf))
  vim.api.nvim_buf_clear_namespace(preview.buf, preview_ns, 0, -1)
  vim.api.nvim_buf_set_extmark(preview.buf, preview_ns, lnum - 1, 0, { line_hl_group = 'CursorLine' })
  vim.api.nvim_win_set_cursor(preview.win, { lnum, 0 })
  vim.api.nvim_win_call(preview.win, function()
    vim.cmd 'normal! zz'
  end)
end

local function toggle_preview()
  preview.enabled = not preview.enabled
  if preview.enabled then
    update_preview()
  else
    close_preview()
  end
  vim.notify('Quickfix preview ' .. (preview.enabled and 'enabled' or 'disabled'))
end

vim.keymap.set('n', 'p', toggle_preview, { buffer = true, desc = 'Toggle quickfix preview' })

vim.api.nvim_create_autocmd('CursorMoved', {
  buffer = 0,
  callback = update_preview,
  desc = 'Update quickfix preview on cursor move',
})

vim.api.nvim_create_autocmd({ 'BufLeave', 'WinLeave' }, {
  buffer = 0,
  callback = function()
    hints.close()
    close_preview()
  end,
})

update_preview()
