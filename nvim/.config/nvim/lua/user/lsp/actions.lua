local M = {}
M.actions = function()
  return {
    ['Code Actions (<leader>la)'] = function()
      vim.lsp.buf.code_action()
    end,
    ['Code Lens (<leader>lx)'] = function()
      vim.lsp.codelens.run()
    end,
    ['Show Definition (gd)'] = function()
      vim.lsp.buf.definition()
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
    ['Find References (gR)'] = function()
      vim.lsp.buf.references { includeDeclaration = false }
    end,
    ['Add workspace folder'] = function()
      vim.lsp.buf.add_workspace_folder()
    end,
    ['Remove workspace folder'] = function()
      vim.lsp.buf.remove_workspace_folder()
    end,
    ['List workspace folders'] = function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end,
    ['Signature Help (<leader>lk)'] = function()
      vim.lsp.buf.signature_help()
    end,
    ['Signature Documentation (K)'] = function()
      vim.lsp.buf.hover()
    end,
    ['Rename symbol (<leader>lr)'] = function()
      vim.lsp.buf.rename()
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
      vim.system { 'rm', '-rf', vim.lsp.log.get_filename() }
    end,
  }
end

M.setup = function()
  require('user.menu').add_actions('LSP', M.actions())
end

return M
