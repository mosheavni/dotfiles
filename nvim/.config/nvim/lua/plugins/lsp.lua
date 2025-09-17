local M = {
  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },
}

M.init = require('user.lsp.config').init
M.config = require('user.lsp.config').setup

M.dependencies = {
  'nvimtools/none-ls.nvim',
  {
    'mason-org/mason.nvim',
    cmd = 'Mason',
    keys = { { '<leader>cm', '<cmd>Mason<cr>', desc = 'Mason' } },
    build = ':MasonUpdate',
    opts = {
      ui = {
        border = 'rounded',
      },
    },
  },
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
    'SmiteshP/nvim-navic',
    lazy = true,
    opts = {
      highlight = true,
    },
    config = function(_, opts)
      local navic = require 'nvim-navic'
      navic.setup(opts)
      vim.o.winbar = "%{%v:lua.require'nvim-navic'.get_location()%}"
    end,
  },
}

local language_specific_plugins = {
  { 'cuducos/yaml.nvim', ft = 'yaml' },
  {
    'phelipetls/jsonpath.nvim',
    ft = 'json',
    config = function()
      vim.api.nvim_buf_create_user_command(0, 'JsonPath', function()
        ---@diagnostic disable-next-line: missing-parameter
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
    dependencies = {
      'DrKJeff16/wezterm-types',
    },
    opts = {
      library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
        { path = 'snacks.nvim', words = { 'Snacks' } },
        { path = 'wezterm-types', mods = { 'wezterm' } },
      },
    },
  },
  {
    'ray-x/go.nvim',
    dependencies = { -- optional packages
      'ray-x/guihua.lua',
      'neovim/nvim-lspconfig',
      'nvim-treesitter/nvim-treesitter',
    },
    opts = {
      lsp_cfg = true,
      lsp_gofumpt = true,
      lsp_inlay_hints = {
        enable = false,
      },
      dap_vt = true,
    },
    config = function(_, opts)
      require('go').setup(opts)
      local format_sync_grp = vim.api.nvim_create_augroup('GoFormat', {})
      vim.api.nvim_create_autocmd('BufWritePre', {
        pattern = '*.go',
        callback = function()
          require('go.format').goimports()
        end,
        group = format_sync_grp,
      })
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
