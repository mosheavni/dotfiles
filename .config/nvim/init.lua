require 'impatient' -- impatient MUST be first

function _G.put_text(...)
  local objects = {}
  for i = 1, select('#', ...) do
    local v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  local lines = vim.split(table.concat(objects, '\n'), '\n')
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  vim.fn.append(lnum, lines)
  return ...
end

function _G.P(v, r)
  if r then
    print(vim.inspect(v))
  else
    vim.notify(vim.inspect(v), 4, {
      title = 'P debug',
      icon = '✎',
    })
  end
  return v
end

vim.cmd [[
set runtimepath^=~/.vim
set runtimepath+=~/.vim/after
let &packpath = &runtimepath
]]

-- local nvim_lsp = require 'lspconfig'
-- local on_attaches = require 'user.lsp.on-attach'
-- local on_attach = on_attaches.default
--
-- local capabilities = vim.lsp.protocol.make_client_capabilities()
-- capabilities.textDocument.completion.completionItem.snippetSupport = true
-- capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)
-- nvim_lsp['terraformls'].setup {
--   cmd = {
--     'terraform-ls',
--     'serve',
--     '-log-file=/tmp/terraform-ls-{{pid}}.log',
--     [[-tf-log-file='/tmp/terraform-exec-1-{{args}}.log']],
--   },
--   on_attach = on_attach,
--   capabilities = capabilities,
-- }

require 'user.options'
require 'user.mappings'
require 'user.plugins'
require 'user.plugin-configs'
require 'user.cmpconf'
require 'user.treesitter'
require 'user.lsp'
require 'user.autocommands'
require 'user.neoscroll'
require 'user.gitsigns'
-- require 'user.tree'
require 'user.telescope'
require 'user.lualine'
require 'user.spectre'
require 'user.which-key'
