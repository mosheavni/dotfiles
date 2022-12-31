local utils = require 'user.utils'
local nnoremap = utils.nnoremap
local M = {
  'neovim/nvim-lspconfig',
  event = 'BufReadPre',
  dependencies = {
    'lukas-reineke/lsp-format.nvim',
    'jose-elias-alvarez/null-ls.nvim',
    'folke/lsp-colors.nvim',
    'nanotee/nvim-lsp-basics',
    -- {
    --   'j-hui/fidget.nvim',
    --   config = function()
    --     require('fidget').setup {
    --       text = {
    --         spinner = 'moon',
    --       },
    --     }
    --   end,
    -- },
    'b0o/SchemaStore.nvim',
    'folke/neodev.nvim',
    {
      'someone-stole-my-name/yaml-companion.nvim',
      config = function()
        nnoremap('<leader>cc', ":lua require('yaml-companion').open_ui_select()<cr>", true)
      end,
    },
    'jose-elias-alvarez/typescript.nvim',
    'SmiteshP/nvim-navic',
    { 'glepnir/lspsaga.nvim', branch = 'main' },
    {
      'williamboman/mason.nvim',
      dependencies = {
        'williamboman/mason-lspconfig.nvim',
        'jayp0521/mason-null-ls.nvim',
      },
    },
  },
}

M.config = function()
  require('user.lsp').setup()
end

return M
