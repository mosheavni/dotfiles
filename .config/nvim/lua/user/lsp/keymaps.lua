local utils = require 'user.utils'
local nnoremap = utils.nnoremap
local inoremap = utils.inoremap

return function(bufnr)
  local function returnOpts(description)
    return { buffer = bufnr, silent = true, desc = description }
  end

  -- GoTo code navigation
  nnoremap('gD', vim.lsp.buf.declaration, returnOpts 'Go to declaration')
  nnoremap('gd', vim.lsp.buf.definition, returnOpts 'Go to definition')
  nnoremap('gp', '<cmd>Lspsaga peek_definition<CR>', returnOpts 'Peek definition')
  nnoremap('gy', vim.lsp.buf.type_definition, returnOpts 'Go to type definition')
  nnoremap('gi', vim.lsp.buf.implementation, returnOpts 'Go to implementation')
  nnoremap('gR', '<cmd>lua vim.lsp.buf.references({ includeDeclaration = false })<CR>', returnOpts 'Go to references (native)')
  nnoremap('gr', '<cmd>Lspsaga finder<CR>', returnOpts 'Go to references')

  -- Documentation
  inoremap('<M-k>', vim.lsp.buf.signature_help, returnOpts 'Signature help')
  nnoremap('<leader>lk', vim.lsp.buf.signature_help, returnOpts 'Signature help')
  -- calling twice make the cursor go into the float window. good for navigating big docs
  -- nnoremap('K', vim.lsp.buf.hover, returnOpts 'Hover doc')
  nnoremap('K', ':Lspsaga hover_doc<CR>', returnOpts 'Hover doc')

  -- Refactor rename
  -- nnoremap('<leader>lrn', vim.lsp.buf.rename, returnOpts 'Rename')
  nnoremap('<leader>lrn', ':Lspsaga rename ++project<CR>', returnOpts 'Rename')

  -- Workspace
  nnoremap('<leader>lwa', vim.lsp.buf.add_workspace_folder, returnOpts 'Add workspace folder')
  nnoremap('<leader>lwr', vim.lsp.buf.remove_workspace_folder, returnOpts 'Remove workspace folder')
  nnoremap('<leader>lwl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, returnOpts 'List workspace folders')

  -- Inlay hints
  nnoremap('<leader>lh', function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = bufnr })
  end, returnOpts 'Toggle inlay hints')

  -- Diagnostics
  nnoremap('<leader>lq', vim.diagnostic.setqflist, returnOpts 'Set qflist')
  nnoremap('<leader>ld', vim.diagnostic.open_float, returnOpts 'Open diagnostics float window')

  -- Code action
  nnoremap('<leader>la', vim.lsp.buf.code_action, returnOpts 'Code action')
  nnoremap('<leader>lx', vim.lsp.codelens.run, returnOpts 'Code lens')

  -- code outline
  nnoremap('<leader>o', ':Lspsaga outline<CR>', returnOpts 'Code lens')
end
