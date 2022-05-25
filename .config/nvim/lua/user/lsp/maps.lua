local utils = require 'user.utils'
local opts = utils.map_opts
local keymap = utils.keymap

return function()
  -- Goto previous/next diagnostic warning/error
  -- Use `[g` and `]g` to navigate diagnostics
  keymap('n', '[g', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts.silent)
  keymap('n', ']g', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts.silent)

  -- GoTo code navigation
  keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts.silent)
  keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts.silent)
  keymap('n', 'gy', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts.silent)
  keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts.silent)
  keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references({ includeDeclaration = false })<CR>', opts.silent)

  -- Documentation
  keymap('i', '<M-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts.silent)
  keymap('n', '<leader>lk', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts.silent)
  -- calling twice make the cursor go into the float window. good for navigating big docs
  keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts.silent)

  -- Refactor rename
  keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts.silent)

  -- Code action
  keymap('n', '<leader>la', '<cmd>lua vim.lsp.buf.code_action()<CR>', {})
  keymap('n', '<leader>lx', '<cmd>lua vim.lsp.codelens.run()<CR>', {})
  keymap('x', '<leader>la', '<cmd>lua vim.lsp.buf.range_code_action()<CR>', {})
  keymap('n', '<leader>lq', '<cmd>lua vim.diagnostic.setqflist()<CR>', opts.silent)
  keymap('n', '<leader>lp', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts.silent)
  -- vim.keymap.set('n', '<leader>lp', function()
  --   utils.lsp_formatting(0)
  -- end, { silent = true })
  keymap('n', '<leader>le', '<cmd>lua vim.diagnostic.open_float()<cr>', opts.silent)
end
