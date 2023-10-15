-----------------
-- Look & Feel --
-----------------

local M = {
  {
    'stevearc/dressing.nvim',
    config = function()
      require('dressing').setup {
        select = {
          telescope = require('telescope.themes').get_dropdown {
            layout_config = {
              width = 0.4,
              -- height = 0.8,
            },
          },
        },
        input = {
          enabled = true,
          relative = 'editor',
        },
      }
      vim.cmd [[hi link FloatTitle Normal]]
    end,
    event = 'VeryLazy',
  },
  {
    'rcarriga/nvim-notify',
    event = 'VeryLazy',
    keys = {
      { '<Leader>x', ":lua require('notify').dismiss()<cr>" },
    },
    config = function()
      vim.notify = require 'notify'
    end,
  },
  {
    'luukvbaal/statuscol.nvim',
    event = 'VeryLazy',
    config = function()
      local builtin = require 'statuscol.builtin'
      require('statuscol').setup {
        relculright = true,
        segments = {
          { text = { builtin.foldfunc }, click = 'v:lua.ScFa' },
          { text = { '%s' }, click = 'v:lua.ScSa' },
          {
            text = { builtin.lnumfunc, ' ' },
            condition = { true, builtin.not_empty },
            click = 'v:lua.ScLa',
          },
        },
      }
    end,
  },
  {
    'RRethy/vim-illuminate',
    event = 'BufReadPost',
  },

  {
    'kyazdani42/nvim-web-devicons',
    lazy = true,
  },
  {
    'vim-scripts/CursorLineCurrentWindow',
    event = 'VeryLazy',
  },
  {
    'norcalli/nvim-colorizer.lua',
    config = true,
    event = 'BufReadPre',
  },
}

return M
