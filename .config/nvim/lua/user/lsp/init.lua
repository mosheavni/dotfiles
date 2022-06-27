require 'user.lsp.config'
require 'user.lsp.handlers'

-- Write current buffer to temp file
function _G.lsp_tmp_write()
  local tmp = vim.fn.tempname()
  vim.cmd(string.format('write %s', tmp))
  vim.cmd 'edit'
  -- Create autocmd to delete the file on exit
  vim.api.nvim_create_autocmd({ 'VimLeavePre' }, {
    buffer = 0,
    command = 'delete("' .. tmp .. '")',
  })
  return tmp
end

vim.keymap.set('n', '<leader>lt', function()
  _G.lsp_tmp_write()
end)
