P = function(v)
  print(vim.inspect(v))
  return v
end

vim.cmd [[
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
]]

require('user.options')
require('user.mappings')
require('user.autocommands')
require('impatient')
require('user.plugins')
require('user.neoscroll')
require('user.gitsigns')
require('user.treesitter')
require('user.treesitter-context')
require('user.telescope')
require('user.lualine')
require('user.plugin-configs')
require('user.lsp')
require('user.cmpconf')
require('user.spectre')
