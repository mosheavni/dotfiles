require 'core'
require 'core.lazy-bootstrap' -- bootstraps folke/lazy
require 'user.options'
require 'user.mappings'
require('lazy').setup('plugins', require('user.lazy').config)
require 'user.autocommands'

vim.api.nvim_create_autocmd('User', {
  pattern = 'VeryLazy',
  callback = function()
    require('user.menu').setup()
  end,
})
