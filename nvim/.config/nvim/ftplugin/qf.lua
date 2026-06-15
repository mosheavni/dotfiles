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
  { key = 'q', desc = 'Close quickfix' },
  { key = 'g?', desc = 'Toggle these hints' },
})

vim.keymap.set('n', 'g?', hints.toggle, { buffer = true, desc = 'Toggle quickfix hints' })

vim.api.nvim_create_autocmd({ 'BufLeave', 'WinLeave' }, {
  buffer = 0,
  callback = function()
    hints.close()
  end,
})
