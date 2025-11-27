return {
  config = {
    dev = { path = '~/Repos' },
    change_detection = { notify = false },
    ui = {
      border = 'rounded',
      custom_keys = {
        ['<localleader>t'] = function(plugin)
          vim.fn.setreg('+', plugin.dir)
          vim.notify('Copied path to clipboard: ' .. plugin.dir)
        end,
      },
    },
    diff = {
      cmd = 'diffview.nvim',
    },
    checker = { enabled = false },
    performance = {
      rtp = {
        disabled_plugins = {
          '2html_plugin',
          'getscript',
          'getscriptPlugin',
          'gzip',
          'logipat',
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
