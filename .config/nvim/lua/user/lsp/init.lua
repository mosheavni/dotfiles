local M = {}

M.setup = function()
  require 'user.lsp.config'
  require 'user.lsp.handlers'
  -- Write current buffer to temp file
  function _G.lsp_tmp_write(should_delete)
    local tmp = vim.fn.tempname()
    vim.cmd(string.format('write %s', tmp))
    vim.cmd 'edit'
    -- Create autocmd to delete the file on exit
    if should_delete then
      vim.api.nvim_create_autocmd({ 'VimLeavePre' }, {
        buffer = 0,
        command = 'delete("' .. tmp .. '")',
      })
    end
    return tmp
  end
end

return M
