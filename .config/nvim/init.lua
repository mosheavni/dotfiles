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
P = function(v, r)
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
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
]]

require 'user.options'
require 'user.mappings'
require 'user.autocommands'
require 'impatient'
require 'user.plugins'
require 'user.neoscroll'
require 'user.gitsigns'
require 'user.treesitter'
require 'user.telescope'
require 'user.lualine'
require 'user.plugin-configs'
require 'user.lsp'
require 'user.cmpconf'
require 'user.spectre'
require 'user.which-key'
