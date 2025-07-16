vim.loader.enable()
require 'core'
require 'core.lazy-bootstrap' -- bootstraps folke/lazy
require 'user.options'
require 'user.keymaps'
require('lazy').setup('plugins', require('user.lazy').config)
require 'user.autocommands'
require 'user.number-separators'

if vim.fn.has 'nvim-0.12' == 1 then
  require('vim._extui').enable {
    enable = true, -- Whether to enable or disable the UI.
    msg = { -- Options related to the message module.
      ---@type 'cmd'|'msg' Where to place regular messages, either in the
      ---cmdline or in a separate ephemeral message window.
      target = 'cmd',
      timeout = 4000, -- Time a message is visible in the message window.
    },
  }
end
