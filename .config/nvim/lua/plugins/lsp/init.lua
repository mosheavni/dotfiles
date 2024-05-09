local M = {
  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },
  opts = {
    setup = {
      docker_compose_language_service = function() end,
    },
  },
}

M.init = require('user.lsp.config').init

M.config = require('user.lsp.config').setup

M.dependencies = {
  'nvimtools/none-ls.nvim',
  'folke/lsp-colors.nvim',
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
  'nanotee/nvim-lsp-basics',
  {
    'j-hui/fidget.nvim',
    config = function()
      require('fidget').setup {
        progress = {
          display = {
            progress_icon = { pattern = 'moon', period = 1 },
          },
        },
      }
    end,
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
  {
    'folke/neodev.nvim',
    opts = {
      override = function(_, library)
        library.enabled = true
        library.plugins = true
      end,
    },
  },
}

local language_specific_plugins = {
  { 'mfussenegger/nvim-jdtls', ft = 'java' },
  {
    'jose-elias-alvarez/typescript.nvim',
    ft = { 'typescript', 'typescriptreact', 'typescript.tsx', 'javascript' },
  },
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
    'someone-stole-my-name/yaml-companion.nvim',
    ft = 'yaml',
    config = function()
      local nnoremap = require('user.utils').nnoremap
      nnoremap('<leader>cc', ":lua require('yaml-companion').open_ui_select()<cr>", true)
      require('user.menu').add_actions('YAML', {
        ['Change Schema'] = function()
          require('yaml-companion').open_ui_select()
        end,
      })
    end,
  },
  { 'b0o/SchemaStore.nvim', lazy = true },
}

return {
  M,
  language_specific_plugins,
}
