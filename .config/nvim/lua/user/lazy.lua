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
  },
}
