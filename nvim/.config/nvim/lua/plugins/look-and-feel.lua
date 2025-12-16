-----------------
-- Look & Feel --
-----------------

local M = {
  -------------------
  --   Colorscheme --
  -------------------
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    opts = {
      variant = 'moon', -- auto, main, moon, dawn
      styles = {
        bold = true,
        italic = true,
        transparency = true,
      },
      highlight_groups = {
        StatusLine = { fg = 'love', bg = 'love', blend = 10 },
        StatusLineNC = { fg = 'subtle', bg = 'surface' },
      },
    },
    config = function(_, opts)
      require('rose-pine').setup(opts)
      vim.cmd [[colorscheme rose-pine]]
    end,
  },

  -----------
  -- other --
  -----------
  {
    'nvim-tree/nvim-web-devicons',
    lazy = true,
    opts = {
      override_by_extension = {
        hcl = {
          icon = '',
          color = '#7182D0',
          name = 'HCL',
        },
      },
    },
    config = function(_, opts)
      require('nvim-web-devicons').setup(opts)
      require('nvim-web-devicons').set_icon_by_filetype { fugitive = 'git' }
    end,
  },
  {
    'eero-lehtinen/oklch-color-picker.nvim',
    opts = {
      highlight = {
        enabled = true,
      },
    },
    keys = {
      { '<Leader>pc', '<cmd>lua require("oklch-color-picker").pick_under_cursor()<CR>', desc = 'Pick color under cursor' },
    },
  },
  {
    'luukvbaal/statuscol.nvim',
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
  {
    -- Make sure to set this up properly if you have lazy=true
    'MeanderingProgrammer/render-markdown.nvim',
    opts = {
      file_types = { 'markdown', 'Avante' },
    },
    ft = { 'markdown', 'Avante' },
  },
}

return M
