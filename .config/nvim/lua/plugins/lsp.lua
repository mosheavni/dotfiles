local M = {
  'neovim/nvim-lspconfig',
  event = 'VeryLazy',
  dependencies = {
    'lukas-reineke/lsp-format.nvim',
    'folke/lsp-colors.nvim',
    'nanotee/nvim-lsp-basics',
    {
      'j-hui/fidget.nvim',
      config = function()
        require('fidget').setup {
          text = {
            spinner = 'moon',
          },
        }
      end,
    },
    'b0o/SchemaStore.nvim',
    { 'folke/neodev.nvim', config = true },
    {
      'someone-stole-my-name/yaml-companion.nvim',
      config = function()
        local nnoremap = require('user.utils').nnoremap
        nnoremap('<leader>cc', ":lua require('yaml-companion').open_ui_select()<cr>", true)
      end,
    },
    'jose-elias-alvarez/typescript.nvim',
    {
      'glepnir/lspsaga.nvim',
      opts = {
        finder_action_keys = {
          edit = '<CR>',
          vsplit = '<C-v>',
          split = '<C-x>',
          quit = 'q',
        },
        code_action_lightbulb = {
          enable = false,
        },
        symbol_in_winbar = {
          enable = true,
          hide_keyword = false,
        },
      },
      config = true,
    },
    {
      'williamboman/mason.nvim',
      dependencies = {
        'williamboman/mason-lspconfig.nvim',
        {
          'jay-babu/mason-null-ls.nvim',
          opts = { automatic_installation = true },
        },
      },
      config = true,
    },
  },
}

M.init = function()
  vim.keymap.set('n', '<leader>ls', function()
    _G.lsp_tmp_write(true)
  end)

  vim.keymap.set('n', '<leader>ls', function()
    _G.lsp_tmp_write(false)
  end)
end

M.config = function()
  require('user.lsp').setup()
end

return M
