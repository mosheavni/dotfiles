return function(bufnr)
  local function returnOpts(description)
    return { remap = false, buffer = bufnr, silent = true, desc = description }
  end

  -- rename
  vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, returnOpts 'Rename')
  -- goto definition/declaration
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, returnOpts 'Go to definition')
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, returnOpts 'Go to declaration')
  vim.keymap.set('n', '<leader>lk', vim.lsp.buf.signature_help, returnOpts 'Signature help')

  -- GoTo code navigation
  vim.keymap.set('n', 'gy', vim.lsp.buf.type_definition, returnOpts 'Go to type definition')
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, returnOpts 'Go to implementation')
  vim.keymap.set('n', 'gR', vim.lsp.buf.references, returnOpts 'Go to references')

  -- Hover
  vim.keymap.set('n', 'K', function()
    vim.lsp.buf.hover {
      border = 'rounded',
      max_height = 30,
    }
  end, returnOpts 'Hover documentation')

  -- Workspace
  vim.keymap.set('n', '<leader>lwa', vim.lsp.buf.add_workspace_folder, returnOpts 'Add workspace folder')
  vim.keymap.set('n', '<leader>lwr', vim.lsp.buf.remove_workspace_folder, returnOpts 'Remove workspace folder')
  vim.keymap.set('n', '<leader>lwl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, returnOpts 'List workspace folders')

  -- Inlay hints
  vim.keymap.set('n', '<leader>lh', function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = bufnr })
  end, returnOpts 'Toggle inlay hints')

  -- Diagnostics
  vim.keymap.set('n', '<leader>lq', vim.diagnostic.setqflist, returnOpts 'Set qflist with diagnostics')
  vim.keymap.set('n', '<leader>ld', vim.diagnostic.open_float, returnOpts 'Open diagnostics float window')

  -- Code action
  vim.keymap.set('n', '<leader>la', vim.lsp.buf.code_action, returnOpts 'Code action')
  vim.keymap.set('n', '<leader>lx', vim.lsp.codelens.run, returnOpts 'Code lens')
end
