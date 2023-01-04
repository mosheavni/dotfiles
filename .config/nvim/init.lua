require 'core'
require 'core.lazy-bootstrap' -- bootstraps folke/lazy
require 'user.options'
require 'user.mappings'
-- require 'user.plugins'
require('lazy').setup('plugins', {
  change_detection = {
    notify = true,
  },
  ui = {
    border = 'rounded',
    custom_keys = {
      ['<localleader>l'] = function(plugin)
        require('lazy.util').open_cmd({ 'git', 'log' }, {
          cwd = plugin.dir,
          terminal = true,
          close_on_exit = true,
          enter = true,
        })
      end,

      -- open a terminal for the plugin dir
      ['<localleader>t'] = function(plugin)
        vim.cmd('FloatermNew --cwd=' .. plugin.dir)
      end,
    },
  },
  diff = {
    cmd = 'diffview.nvim',
  },
  checker = {
    -- automatically check for plugin updates
    enabled = false,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        'rplugin',
        'gzip',
        'matchit',
        'matchparen',
        'shada',
        'tarPlugin',
        'tohtml',
        'tutor',
        'zipPlugin',
      },
    },
  },
})
require 'user.autocommands'
require('user.menu').setup()

-- vim.api.nvim_create_autocmd('User', {
--   pattern = 'VeryLazy',
--   callback = function()
--     P 'very lazy'
--   end,
-- })
