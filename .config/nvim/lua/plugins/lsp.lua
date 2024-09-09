local M = {
  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },
}

M.init = require('user.lsp.config').init

M.config = require('user.lsp.config').setup

M.dependencies = {
  'nvimtools/none-ls.nvim',
  {
    'williamboman/mason.nvim',
    cmd = 'Mason',
    keys = { { '<leader>cm', '<cmd>Mason<cr>', desc = 'Mason' } },
    build = ':MasonUpdate',
    opts = {
      ui = {
        border = require('user.utils').float_border,
      },
    },
  },
  'williamboman/mason-lspconfig.nvim',
  {
    'j-hui/fidget.nvim',
    opts = {
      progress = {
        display = {
          progress_icon = { pattern = 'moon', period = 1 },
        },
      },
    },
  },
  {
    'nvimdev/lspsaga.nvim',
    opts = {
      finder = {
        keys = {
          edit = '<CR>',
          vsplit = '<C-v>',
          split = '<C-x>',
        },
      },
      definition = {
        keys = {
          edit = '<CR>',
          vsplit = '<C-v>',
          split = '<C-x>',
        },
      },

      lightbulb = {
        enable = false,
        sign = false,
      },
      symbol_in_winbar = {
        show_file = false,
        enable = true,
        hide_keyword = false,
      },
      outline = {
        keys = {
          toggle_or_jump = '<CR>',
        },
      },
    },
    config = true,
  },
}

local language_specific_plugins = {
  { 'cuducos/yaml.nvim', ft = 'yaml' },
  {
    'phelipetls/jsonpath.nvim',
    ft = 'json',
    config = function()
      vim.api.nvim_buf_create_user_command(0, 'JsonPath', function()
        local json_path = require('jsonpath').get()
        local register = '+'
        vim.fn.setreg(register, json_path)
        vim.notify('Copied ' .. json_path .. ' to register ' .. register, vim.log.levels.INFO, { title = 'JsonPath' })
      end, {})
      require('user.menu').add_actions('JSON', {
        ['Copy Json Path to clipboard (:JsonPath)'] = function()
          vim.cmd [[JsonPath]]
        end,
      })
    end,
  },
  {
    'mosheavni/yaml-companion.nvim',
    ft = 'yaml',
    config = function()
      vim.keymap.set('n', '<leader>cc', ":lua require('yaml-companion').open_ui_select()<cr>", { remap = false, silent = true })
      require('user.menu').add_actions('YAML', {
        ['Change Schema'] = function()
          require('yaml-companion').open_ui_select()
        end,
      })
    end,
  },
  { 'b0o/SchemaStore.nvim', lazy = true },
  {
    'folke/lazydev.nvim',
    ft = 'lua', -- only load on lua files
    opts = {
      library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
      },
    },
    -- config = function(_,opts)
    --   require("lazydev").setup(opts)
    --   require('cmp').register_source('lazydev', )
    -- end
  },
  {
    'ray-x/go.nvim',
    dependencies = { -- optional packages
      'ray-x/guihua.lua',
      'neovim/nvim-lspconfig',
      'nvim-treesitter/nvim-treesitter',
    },
    config = function()
      require('go').setup()
    end,
    event = { 'CmdlineEnter' },
    ft = { 'go', 'gomod' },
    build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
  },
}

return {
  M,
  language_specific_plugins,
}
