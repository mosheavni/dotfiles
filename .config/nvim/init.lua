vim.defer_fn(function()
  pcall(require, 'impatient')
end, 0)

require 'core'
require 'user.options'
require 'user.mappings'
require 'user.autocommands'
require 'user.plugins'
require 'user.plugin-configs'
