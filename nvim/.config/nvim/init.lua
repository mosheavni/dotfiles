vim.loader.enable()
require 'core'
require 'core.lazy-bootstrap' -- bootstraps folke/lazy
require 'user.options'
require 'user.keymaps'
require('lazy').setup('plugins', require('user.lazy').config)
require 'user.autocommands'
require 'user.number-separators'
