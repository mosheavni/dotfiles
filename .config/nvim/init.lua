require 'core'
require 'user.options'
require 'user.mappings'
require 'user.plugins'
require 'user.autocommands'
require('user.menu').setup()

-- vim.api.nvim_create_autocmd('User', {
--   pattern = 'VeryLazy',
--   callback = function()
--     P 'very lazy'
--   end,
-- })
