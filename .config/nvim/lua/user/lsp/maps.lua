local utils = require 'user.utils'
local opts = utils.map_opts

return function(bufnr)
  local function buf_set_keymap(...)
    vim.api.nvim_buf_set_keymap(bufnr, ...)
  end

  -- Goto previous/next diagnostic warning/error
  -- Use `[g` and `]g` to navigate diagnostics
  buf_set_keymap('n', '[g', '<cmd>lua vim.diagnostic.goto_prev({float=false})<CR>', opts.silent)
  buf_set_keymap('n', ']g', '<cmd>lua vim.diagnostic.goto_next({float=false})<CR>', opts.silent)

  -- GoTo code navigation
  buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts.silent)
  buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts.silent)
  buf_set_keymap('n', 'gy', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts.silent)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts.silent)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references({ includeDeclaration = false })<CR>', opts.silent)
  buf_set_keymap('n', '<leader>lrf', '<cmd>lua vim.lsp.buf.references()<CR>', opts.silent)

  -- Documentation
  buf_set_keymap('i', '<M-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts.silent)
  buf_set_keymap('n', '<leader>lk', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts.silent)
  -- calling twice make the cursor go into the float window. good for navigating big docs
  buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts.silent)

  -- Refactor rename
  buf_set_keymap('n', '<leader>lrn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts.silent)

  -- Workspace
  buf_set_keymap('n', '<leader>lwa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts.silent)
  buf_set_keymap('n', '<leader>lwr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts.silent)
  buf_set_keymap('n', '<leader>lwl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts.silent)

  -- Diagnostics
  buf_set_keymap('n', '<leader>lq', '<cmd>lua vim.diagnostic.setqflist()<CR>', opts.silent)
  buf_set_keymap('n', '<leader>ld', '<cmd>lua vim.diagnostic.open_float()<cr>', opts.silent)

  -- Code action
  buf_set_keymap('n', '<leader>la', '<cmd>lua vim.lsp.buf.code_action()<CR>', {})
  buf_set_keymap('n', '<leader>lx', '<cmd>lua vim.lsp.codelens.run()<CR>', {})
  buf_set_keymap('x', '<leader>la', '<cmd>lua vim.lsp.buf.range_code_action()<CR>', {})
end
