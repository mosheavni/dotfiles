local M = {
  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },
}

M.init = function()
  _G.start_ls = function()
    local ft = vim.api.nvim_get_option_value('filetype', { buf = 0 })
    local file_name = _G.tmp_write { should_delete = false, new = false, ft = ft }
    -- load lsp
    require 'lspconfig'
    return file_name
  end
  vim.keymap.set('n', '<leader>ls', _G.start_ls)
  require('user.menu').add_actions('LSP', {
    ['Start LSP (<leader>ls)'] = function()
      _G.start_ls()
    end,
  })
end

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
        border = 'rounded',
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
    'SmiteshP/nvim-navic',
    lazy = true,
    opts = {
      highlight = true,
    },
    config = function(_, opts)
      local navic = require 'nvim-navic'
      navic.setup(opts)
      _G.get_winbar = function()
        return vim.api.nvim_win_get_config(0).relative == '' and require('nvim-navic').get_location() or vim.fn.expand '%:~:.'
      end

      -- vim.o.winbar = "%{%v:lua.require'nvim-navic'.get_location()%}"
      vim.o.winbar = '%{%v:lua._G.get_winbar()%}'
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
      'justinsgithub/wezterm-types',
    },
    opts = {
      library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
        { path = 'wezterm-types', mods = { 'wezterm' } },
      },
    },
    -- config = function(_,opts)
    --   require("lazydev").setup(opts)
    --   require('cmp').register_source('lazydev', )
    -- end
  },
}

return {
  M,
  language_specific_plugins,
}
