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

-- local function buf_set_keymap(...)
--   vim.api.nvim_buf_set_keymap(bufnr, ...)
-- buf_set_keymap('n', '[g', '<cmd>lua vim.diagnostic.goto_prev({float=false})<CR>', opts.silent)
-- buf_set_keymap('n', ']g', '<cmd>lua vim.diagnostic.goto_next({float=false})<CR>', opts.silent)
-- buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts.silent)
-- buf_set_keymap('n', 'gd', '<cmd>Lspsaga peek_definition<CR>', opts.silent)
-- buf_set_keymap('n', 'gy', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts.silent)
-- buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts.silent)
-- buf_set_keymap('n', 'gr', '<cmd>Lspsaga lsp_finder<CR>', opts.silent)
-- buf_set_keymap('i', '<M-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts.silent)
-- buf_set_keymap('n', '<leader>lk', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts.silent)
-- buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts.silent)
-- buf_set_keymap('n', '<leader>lrn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts.silent)
-- buf_set_keymap('n', '<leader>lwa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts.silent)
-- buf_set_keymap('n', '<leader>lwr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts.silent)
-- buf_set_keymap('n', '<leader>lwl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts.silent)
-- buf_set_keymap('n', '<leader>lq', '<cmd>lua vim.diagnostic.setqflist()<CR>', opts.silent)
-- buf_set_keymap('n', '<leader>ld', '<cmd>lua vim.diagnostic.open_float()<cr>', opts.silent)
-- buf_set_keymap('n', '<leader>la', '<cmd>lua vim.lsp.buf.code_action()<CR>', {})
-- buf_set_keymap('n', '<leader>lx', '<cmd>lua vim.lsp.codelens.run()<CR>', {})
-- buf_set_keymap('x', '<leader>la', '<cmd>lua vim.lsp.buf.range_code_action()<CR>', {})
