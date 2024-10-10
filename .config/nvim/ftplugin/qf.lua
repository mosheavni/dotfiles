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

local function remove_qf_item()
  local qf_list = vim.fn.getqflist()
  if #qf_list > 0 then
    local curqfidx = vim.fn.line '.'
    table.remove(qf_list, curqfidx)
    vim.fn.setqflist(qf_list, 'r')
    vim.cmd(curqfidx .. 'cfirst')
    vim.cmd 'copen'
  end
end
vim.api.nvim_create_user_command('RemoveQFItem', remove_qf_item, {})
vim.keymap.set('n', 'dd', '<CMD>RemoveQFItem<CR>', { remap = false, buffer = true })

-- map yy to yank file name
vim.keymap.set('n', 'yy', function()
  local line = vim.api.nvim_get_current_line()
  local filename = vim.split(line, ' ')[1]
  vim.fn.setreg('"', filename)
  vim.notify('Copied ' .. filename .. ' to register')
end, { remap = false, buffer = true })
