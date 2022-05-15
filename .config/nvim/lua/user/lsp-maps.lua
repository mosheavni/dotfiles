return function(keymap, opt)

  -- Goto previous/next diagnostic warning/error
  -- Use `[g` and `]g` to navigate diagnostics
  keymap('n', '[g', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opt.silent_opt)
  keymap('n', ']g', '<cmd>lua vim.diagnostic.goto_next()<CR>', opt.silent_opt)

  -- GoTo code navigation
  keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opt.silent_opt)
  keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opt.silent_opt)
  keymap('n', 'gy', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opt.silent_opt)
  keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opt.silent_opt)
  keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references({ includeDeclaration = false })<CR>', opt.silent_opt)

  -- Documentation
  keymap('i', '<M-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opt.silent_opt)
  -- keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opt.silent_opt)
  -- calling twice make the cursor go into the float window. good for navigating big docs
  keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opt.silent_opt)

  -- Refactor rename
  keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opt.silent_opt)

  -- Code action
  keymap('n', '<leader>a', '<cmd>lua vim.lsp.buf.code_action()<CR>', {})
  keymap('n', '<leader>x', '<cmd>lua vim.lsp.codelens.run()<CR>', {})
  keymap('x', '<leader>a', '<cmd>lua vim.lsp.buf.range_code_action()<CR>', {})
  keymap('n', '<leader>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opt.silent_opt)
  keymap('n', '<leader>p', '<cmd>lua vim.lsp.buf.formatting()<CR>', opt.silent_opt)
  keymap('n', '<leader>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opt.silent_opt)

end
