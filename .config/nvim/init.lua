require 'core'
require 'core.lazy-bootstrap' -- bootstraps folke/lazy
require 'user.options'
require 'user.mappings'
-- require 'user.plugins'
require('lazy').setup 'plugins' -- loads each lua/plugin/*
require 'user.autocommands'
require('user.menu').setup()

-- vim.api.nvim_create_autocmd('User', {
--   pattern = 'VeryLazy',
--   callback = function()
--     P 'very lazy'
--   end,
-- })
