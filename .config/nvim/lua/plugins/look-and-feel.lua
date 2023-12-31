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
    'sainnhe/sonokai',
    enabled = true,
    config = function()
      vim.cmd [[
        let g:sonokai_style = 'shusia'
        colorscheme sonokai
      ]]
      require('user.menu').add_actions('Colorscheme', {
        ['Toggle Sonokai Style'] = function()
          local styles = { 'default', 'atlantis', 'andromeda', 'shusia', 'maia', 'espresso' }
          local current_value = vim.g.sonokai_style
          local index = require('user.utils').tbl_get_next(styles, current_value)
          vim.g.sonokai_style = styles[index]
          vim.cmd [[colorscheme sonokai]]
          P('Set sonokai_style to ' .. styles[index])
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
      require('user.menu').add_actions('Colorizer', {
        ['Attach to Buffer (:ColorizerAttachToBuffer)'] = function()
          vim.cmd 'ColorizerAttachToBuffer'
        end,
        ['Toggle (:ColorizerToggle)'] = function()
          vim.cmd 'ColorizerToggle'
        end,
        ['Detach from Buffer (:ColorizerDetachFromBuffer)'] = function()
          vim.cmd 'ColorizerDetachFromBuffer'
        end,
        ['Reload All Buffers (:ColorizerReloadAllBuffers)'] = function()
          vim.cmd 'ColorizerReloadAllBuffers'
        end,
      })
    end,
    event = 'BufReadPost',
  },
}

return M
