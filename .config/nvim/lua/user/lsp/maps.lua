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
  nnoremap('gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', buffer_opts)
  nnoremap('gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', buffer_opts)
  nnoremap('gp', '<cmd>Lspsaga peek_definition<CR>', buffer_opts)
  nnoremap('gy', '<cmd>lua vim.lsp.buf.type_definition()<CR>', buffer_opts)
  nnoremap('gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', buffer_opts)
  -- nnoremap('gr', '<cmd>lua vim.lsp.buf.references({ includeDeclaration = false })<CR>', buffer_opts)
  nnoremap('gr', '<cmd>Lspsaga lsp_finder<CR>', buffer_opts)

  -- Documentation
  inoremap('<M-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', buffer_opts)
  nnoremap('<leader>lk', '<cmd>lua vim.lsp.buf.signature_help()<CR>', buffer_opts)
  -- calling twice make the cursor go into the float window. good for navigating big docs
  nnoremap('K', '<Cmd>lua vim.lsp.buf.hover()<CR>', buffer_opts)

  -- Refactor rename
  nnoremap('<leader>lrn', '<cmd>lua vim.lsp.buf.rename()<CR>', buffer_opts)

  -- Workspace
  nnoremap('<leader>lwa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', buffer_opts)
  nnoremap('<leader>lwr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', buffer_opts)
  nnoremap('<leader>lwl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', buffer_opts)

  -- Diagnostics
  nnoremap('<leader>lq', '<cmd>lua vim.diagnostic.setqflist()<CR>', buffer_opts)
  nnoremap('<leader>ld', '<cmd>lua vim.diagnostic.open_float()<cr>', buffer_opts)
  -- Goto previous/next diagnostic warning/error
  -- Use `[g` and `]g` to navigate diagnostics
  nnoremap('[g', '<cmd>lua vim.diagnostic.goto_prev({float=false})<CR>', buffer_opts)
  nnoremap(']g', '<cmd>lua vim.diagnostic.goto_next({float=false})<CR>', buffer_opts)

  -- Code action
  nnoremap('<leader>la', '<cmd>lua vim.lsp.buf.code_action()<CR>')
  nnoremap('<leader>lx', '<cmd>lua vim.lsp.codelens.run()<CR>')
  nnoremap('<leader>la', '<cmd>lua vim.lsp.buf.range_code_action()<CR>')
end
