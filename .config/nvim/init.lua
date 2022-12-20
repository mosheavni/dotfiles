vim.defer_fn(function()
  pcall(require, 'impatient')
end, 0)

require 'core'
require 'user.options'
require 'user.mappings'
require 'user.autocommands'
require 'user.plugins'

-- vim.api.nvim_create_autocmd('User', {
--   pattern = 'VeryLazy',
--   callback = function()
--     P 'very lazy'
--   end,
-- })
