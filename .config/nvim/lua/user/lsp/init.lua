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

  vim.keymap.set('n', '<leader>ls', function()
    _G.lsp_tmp_write(true)
  end)

  vim.keymap.set('n', '<leader>ls', function()
    _G.lsp_tmp_write(false)
  end)
end

M.actions = {
  ['Format'] = function()
    require('user.lsp.formatting').format()
  end,
  ['Code Actions'] = function()
    vim.lsp.buf.code_action()
  end,
  ['Code Lens'] = function()
    vim.lsp.codelens.run()
  end,
  ['Show Definition'] = function()
    vim.cmd 'Lspsaga peek_definition'
  end,
  ['Show Declaration'] = function()
    vim.lsp.buf.declaration()
  end,

  ['Show Type Definition'] = function()
    vim.lsp.buf.type_definition()
  end,
  ['Show Implementation'] = function()
    vim.lsp.buf.implementation()
  end,
  ['Find References'] = function()
    vim.cmd 'Lspsaga lsp_finder'
  end,
  ['Signature Help'] = function()
    vim.lsp.buf.signature_help()
  end,
  ['Signature Documentation'] = function()
    vim.lsp.buf.hover()
  end,
  ['Diagnostics quickfix list'] = function()
    vim.diagnostic.setqflist()
  end,
}

return M
