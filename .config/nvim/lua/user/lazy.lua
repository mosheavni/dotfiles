local M = {}
M.config = {
  change_detection = {
    notify = false,
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
        'gzip',
        'man',
        'matchit',
        'matchparen',
        'rplugin',
        'shada',
        'tarPlugin',
        'tohtml',
        'tutor',
        'zipPlugin',
      },
    },
  },
}

return M
