-----------------
-- Look & Feel --
-----------------

local M = {
  {
    'rcarriga/nvim-notify',
    event = 'VeryLazy',
    keys = {
      {
        '<Leader>x',
        function()
          require('notify').dismiss { pending = true, silent = true }
        end,
      },
    },
    config = function()
      local notify = require 'notify'
      notify.setup {
        render = 'compact',
        stages = 'static',
        timeout = 3000,
      }
      vim.notify = notify
    end,
  },
  {
    'echasnovski/mini.indentscope',
    version = false,
    event = 'VeryLazy',
    opts = {
      symbol = '│',
      options = { try_as_border = true },
    },
    config = function(_, opts)
      require('mini.indentscope').setup(opts)
      vim.cmd 'highlight! MiniIndentscopeSymbol ctermfg=109 guifg=#7daea3'
    end,
    init = function()
      vim.api.nvim_create_autocmd('FileType', {
        pattern = {
          'help',
          'fugitive',
          'dashboard',
          'NvimTree',
          'Trouble',
          'trouble',
          'lazy',
          'mason',
          'notify',
          'floaterm',
          'lazyterm',
        },
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })

      vim.api.nvim_create_autocmd('TermOpen', {
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })
    end,
  },
  {
    'folke/twilight.nvim',
    cmd = { 'Twilight', 'TwilightEnable', 'TwilightDisable' },
    opts = {},
  },
  {
    'luukvbaal/statuscol.nvim',
    branch = '0.10',
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
    event = 'BufReadPost',
  },
  {
    'NvChad/nvim-colorizer.lua',
    opts = {
      filetypes = { '*', '!packer', '!dashboard', '!NvimTree', '!Trouble', '!trouble', '!lazy', '!mason', '!notify', '!floaterm', '!lazyterm' },
      user_default_options = { mode = 'virtualtext', names = false },
    },
    config = function(_, opts)
      require('colorizer').setup(opts)
      require('colorizer').attach_to_buffer(0, { mode = 'virtualtext', css = true })
    end,
    event = 'BufReadPost',
  },
}

return M
