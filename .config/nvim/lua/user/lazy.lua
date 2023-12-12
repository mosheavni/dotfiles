return {
  config = {
    change_detection = {
      notify = false,
    },
    ui = {
      border = require('user.utils').float_border,
      custom_keys = {
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
          '2html_plugin',
          'getscript',
          'getscriptPlugin',
          'gzip',
          'logipat',
          'man',
          'matchit',
          'matchparen',
          'netrw',
          'netrwFileHandlers',
          'netrwPlugin',
          'netrwSettings',
          'rplugin',
          'rrhelper',
          'shada',
          'spellfile_plugin',
          'tar',
          'tarPlugin',
          'tohtml',
          'tutor',
          'vimball',
          'vimballPlugin',
          'zip',
          'zipPlugin',
        },
      },
    },
  },
}
