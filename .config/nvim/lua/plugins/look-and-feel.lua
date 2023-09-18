local utils = require 'user.utils'
local inoremap = utils.inoremap
local nmap = utils.nmap
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
              height = 0.8,
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
    config = function()
      vim.notify = require 'notify'
      nmap('<Leader>x', ":lua require('notify').dismiss()<cr>", true)
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
