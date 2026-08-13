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

-- Set up the operator mapping
vim.keymap.set('n', 'd', function()
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.o.operatorfunc = function(_)
    local start_line = vim.fn.line "'["
    local end_line = vim.fn.line "']"
    remove_qf_items(start_line, end_line)
  end
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
