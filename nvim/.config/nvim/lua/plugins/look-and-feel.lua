-----------------
-- Look & Feel --
-----------------

local M = {
  -------------------
  --   Colorscheme --
  -------------------
  {
    'navarasu/onedark.nvim',
    enabled = false,
    config = function()
      require('onedark').setup {
        style = 'dark',
        highlights = {
          EndOfBuffer = { fg = '#61afef' },
        },
      }
      require('onedark').load()
    end,
  },
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    opts = {
      styles = {
        bold = true,
        italic = true,
        transparency = true,
      },
    },
    config = function(_, opts)
      require('rose-pine').setup(opts)
      vim.cmd [[colorscheme rose-pine]]
    end,
  },
  {
    'sainnhe/sonokai',
    enabled = false,
    config = function()
      vim.cmd [[
        let g:sonokai_style = 'shusia'
        let g:sonokai_transparent_background = 1
        colorscheme sonokai
      ]]
      vim.api.nvim_set_hl(0, 'WinSeparator', { fg = '#797D7D' })
      require('user.menu').add_actions('Colorscheme', {
        ['Toggle Sonokai Style'] = function()
          local styles = { 'default', 'atlantis', 'andromeda', 'shusia', 'maia', 'espresso' }
          local current_value = vim.g.sonokai_style
          local index = require('user.utils').tbl_get_next(styles, current_value)
          vim.g.sonokai_style = styles[index]
          vim.cmd [[colorscheme sonokai]]
          require('user.utils').pretty_print('Set sonokai_style to ' .. styles[index])
        end,
      })
    end,
  },
  {
    'sainnhe/gruvbox-material',
    enabled = false,
    config = function()
      -- load the colorscheme here
      vim.cmd [[
        let g:gruvbox_material_better_performance = 1
        let g:gruvbox_material_background = 'hard' " soft | medium | hard
        colorscheme gruvbox-material
      ]]
    end,
  },
  {
    'tiagovla/tokyodark.nvim',
    enabled = false,
    opts = {},
    config = function(_, opts)
      require('tokyodark').setup(opts) -- calling setup is optional
      vim.cmd [[colorscheme tokyodark]]
    end,
  },

  -----------
  -- other --
  -----------
  {
    'nvim-tree/nvim-web-devicons',
    lazy = true,
  },
  {
    'eero-lehtinen/oklch-color-picker.nvim',
    opts = {
      highlight = {
        enabled = true,
      },
    },
    keys = {
      { '<Leader>p', '<cmd>lua require("oklch-color-picker").pick_under_cursor()<CR>' },
    },
  },
  {
    'dstein64/vim-startuptime',
    cmd = 'Startup Time (:StartupTime)',
    init = function()
      require('user.menu').add_actions(nil, {
        ['StartupTime'] = function()
          vim.cmd [[StartupTime]]
        end,
      })
    end,
  },
  {
    'luukvbaal/statuscol.nvim',
    branch = '0.10',
    event = { 'BufReadPre', 'BufNewFile' },
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
    'kevinhwang91/nvim-ufo',
    dependencies = { 'kevinhwang91/promise-async' },
    event = 'BufReadPost',
    keys = {
      { '<leader>fo', '<cmd>lua require("ufo").openAllFolds()<cr>' },
      { '<leader>fc', '<cmd>lua require("ufo").closeAllFolds()<cr>' },
      { '<leader>fp', '<cmd>lua require("ufo").peekFoldedLinesUnderCursor()<cr>' },
    },
    opts = {
      open_fold_hl_timeout = 0,
    },

    init = function()
      ---@diagnostic disable-next-line: inject-field
      vim.o.foldcolumn = '1' -- '0' is not bad
      ---@diagnostic disable-next-line: inject-field
      vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
      ---@diagnostic disable-next-line: inject-field
      vim.o.foldlevelstart = 99
      ---@diagnostic disable-next-line: inject-field
      vim.o.foldenable = true
    end,
  },
  {
    'vim-scripts/CursorLineCurrentWindow',
    event = 'BufReadPost',
  },
}

return M
