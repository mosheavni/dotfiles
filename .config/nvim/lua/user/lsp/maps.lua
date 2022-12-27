local saga = require 'lspsaga'
local utils = require 'user.utils'
local nnoremap = utils.nnoremap
local inoremap = utils.inoremap

return function(bufnr)
  saga.init_lsp_saga {
    finder_action_keys = {
      edit = '<CR>',
      vsplit = '<C-v>',
      split = '<C-x>',
      quit = 'q',
    },
    code_action_lightbulb = {
      enable = false,
    },
  }

  local buffer_opts = { buffer = bufnr, silent = true }

  -- GoTo code navigation
  nnoremap('gD', vim.lsp.buf.declaration, buffer_opts)
  nnoremap('gd', vim.lsp.buf.definition, buffer_opts)
  nnoremap('gp', '<cmd>Lspsaga peek_definition<CR>', buffer_opts)
  nnoremap('gy', vim.lsp.buf.type_definition, buffer_opts)
  nnoremap('gi', vim.lsp.buf.implementation, buffer_opts)
  -- nnoremap('gr', '<cmd>lua vim.lsp.buf.references({ includeDeclaration = false })<CR>', buffer_opts)
  nnoremap('gr', '<cmd>Lspsaga lsp_finder<CR>', buffer_opts)

  -- Documentation
  inoremap('<M-k>', vim.lsp.buf.signature_help, buffer_opts)
  nnoremap('<leader>lk', vim.lsp.buf.signature_help, buffer_opts)
  -- calling twice make the cursor go into the float window. good for navigating big docs
  nnoremap('K', vim.lsp.buf.hover, buffer_opts)

  -- Refactor rename
  nnoremap('<leader>lrn', vim.lsp.buf.rename, buffer_opts)

  -- Workspace
  nnoremap('<leader>lwa', vim.lsp.buf.add_workspace_folder, buffer_opts)
  nnoremap('<leader>lwr', vim.lsp.buf.remove_workspace_folder, buffer_opts)
  nnoremap('<leader>lwl',function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, buffer_opts)

  -- Diagnostics
  nnoremap('<leader>lq', vim.diagnostic.setqflist, buffer_opts)
  nnoremap('<leader>ld', vim.diagnostic.open_float, buffer_opts)
  -- Goto previous/next diagnostic warning/error
  -- Use `[g` and `]g` to navigate diagnostics
  nnoremap('[g', vim.diagnostic.goto_prev, buffer_opts)
  nnoremap(']g', vim.diagnostic.goto_next, buffer_opts)

  -- Code action
  nnoremap('<leader>la', vim.lsp.buf.code_action, buffer_opts)
  nnoremap('<leader>lx', vim.lsp.codelens.run, buffer_opts)
end
