local utils = require 'user.utils'
local opts = utils.map_opts
local keymap = utils.keymap

-- Goto previous/next diagnostic warning/error
-- Use `[g` and `]g` to navigate diagnostics
keymap('n', '[g', '<cmd>lua vim.diagnostic.goto_prev({ float = false })<CR>', opts.silent)
keymap('n', ']g', '<cmd>lua vim.diagnostic.goto_next({ float = false })<CR>', opts.silent)

-- GoTo code navigation
keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts.silent)
keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts.silent)
keymap('n', 'gy', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts.silent)
keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts.silent)
keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references({ includeDeclaration = false })<CR>', opts.silent)

-- Documentation
keymap('i', '<M-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts.silent)
keymap('n', '<leader>k', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts.silent)
-- calling twice make the cursor go into the float window. good for navigating big docs
keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts.silent)

-- Refactor rename
keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts.silent)

-- Code action
keymap('n', '<leader>a', '<cmd>lua vim.lsp.buf.code_action()<CR>', {})
keymap('n', '<leader>x', '<cmd>lua vim.lsp.codelens.run()<CR>', {})
keymap('x', '<leader>a', '<cmd>lua vim.lsp.buf.range_code_action()<CR>', {})
keymap('n', '<leader>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts.silent)
keymap('n', '<leader>p', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts.silent)
keymap('n', '<leader>e', '<cmd>lua vim.diagnostic.open_float()<cr>', opts.silent)


-- gD = 'lua vim.lsp.buf.declaration()',
-- gd = 'lua vim.lsp.buf.definition()',
-- gt = 'lua vim.lsp.buf.type_definition()',
-- gi = 'lua vim.lsp.buf.implementation()',
-- gr = 'lua vim.lsp.buf.references()',
-- K = 'lua vim.lsp.buf.hover()',
-- ['<C-k>'] = 'lua vim.lsp.buf.signature_help()',
-- ['<space>rn'] = 'lua vim.lsp.buf.rename()',
-- ['<space>ca'] = 'lua vim.lsp.buf.code_action()',
-- ['<space>f'] = 'lua vim.lsp.buf.formatting()',
-- ['<space>e'] = 'lua vim.diagnostic.open_float()',
-- ['[d'] = 'lua vim.diagnostic.goto_prev()',
-- [']d'] = 'lua vim.diagnostic.goto_next()',
