local M = {}
M.actions = function()
  return {
    ['Format (<leader>lp)'] = function()
      require('user.lsp.formatting').format()
    end,
    ['Code Actions (<leader>la)'] = function()
      vim.lsp.buf.code_action()
    end,
    ['Code Lens (<leader>lx)'] = function()
      vim.lsp.codelens.run()
    end,
    ['Show Definition (gd)'] = function()
      vim.cmd 'Lspsaga peek_definition'
    end,
    ['Show Declaration (gD)'] = function()
      vim.lsp.buf.declaration()
    end,
    ['Show Type Definition (gy)'] = function()
      vim.lsp.buf.type_definition()
    end,
    ['Show Implementation (gi)'] = function()
      vim.lsp.buf.implementation()
    end,
    ['Find References (gr)'] = function()
      vim.cmd 'Lspsaga finder'
    end,
    ['Signature Help (<leader>lk)'] = function()
      vim.lsp.buf.signature_help()
    end,
    ['Signature Documentation (K)'] = function()
      -- vim.lsp.buf.hover()
      vim.cmd 'Lspsaga hover_doc'
    end,
    ['Rename symbol (<leader>lrn)'] = function()
      vim.cmd 'Lspsaga rename ++project'
    end,
    ['Diagnostics quickfix list (<leader>lq)'] = function()
      vim.diagnostic.setqflist()
    end,
    ['Toggle inlay hints (<leader>lh)'] = function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = 0 }, { bufnr = 0 })
    end,
    ['Clear Diagnostics'] = function()
      vim.diagnostic.reset()
    end,
    ['Delete Log'] = function()
      vim.system { 'rm', '-rf', vim.lsp.get_log_path() }
    end,
  }
end

M.setup = function()
  require('user.menu').add_actions('LSP', M.actions())
end

return M
