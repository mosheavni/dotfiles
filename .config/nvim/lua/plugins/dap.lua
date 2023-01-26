local M = {
  'mfussenegger/nvim-dap',
  init = function()
    vim.api.nvim_create_user_command('DAP', function()
      require('user.menu').set_dap_actions()
      require('dap').toggle_breakpoint()
      require('dapui').toggle()
    end, {})
  end,
  cmd = { 'DAP' },
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'mfussenegger/nvim-dap-python',
    'nvim-telescope/telescope-dap.nvim',
    'rcarriga/cmp-dap',
    'mxsdev/nvim-dap-vscode-js',
    'theHamsta/nvim-dap-virtual-text',
    'jay-babu/mason-nvim-dap.nvim',
  },
}

M.config = function()
  local utils = require 'user.utils'
  local cmp = require 'cmp'
  local opts = utils.map_opts
  local nnoremap = utils.nnoremap
  local mason_nvim_dap = require 'mason-nvim-dap'
  mason_nvim_dap.setup {
    ensure_installed = {
      'bash',
      'chrome',
      'node2',
      'python',
    },
    automatic_setup = true,
  }
  mason_nvim_dap.setup_handlers()

  local dap = require 'dap'
  require('telescope').load_extension 'dap'
  local dapui = require 'dapui'
  dapui.setup()
  require('nvim-dap-virtual-text').setup()

  vim.g.dap_virtual_text = true
  vim.fn.sign_define('DapBreakpoint', { text = '🛑', texthl = '', linehl = '', numhl = '' })
  vim.fn.sign_define('DapBreakpointRejected', { text = '❓', texthl = '', linehl = '', numhl = '' })
  vim.fn.sign_define('DapStopped', { text = '⭕️', texthl = '', linehl = '', numhl = '' })

  -- Mappings
  nnoremap('<F5>', '<cmd>lua require("dap").continue()<cr>', opts.no_remap)
  nnoremap('<leader>bp', '<cmd>lua require("dap").toggle_breakpoint()<cr>', opts.no_remap)

  -- Python
  require('dap-python').setup '/usr/local/bin/python3'
  require('dap-python').setup(vim.fn.stdpath 'data' .. '/mason/packages/debugpy/venv/bin/python3')

  table.insert(dap.configurations.python, {
    justMyCode = false,
  })

  -- lua
  dap.configurations.lua = {
    {
      type = 'nlua',
      request = 'attach',
      name = 'Attach to running Neovim instance',
    },
  }

  dap.adapters.nlua = function(callback, config)
    callback { type = 'server', host = config.host or '127.0.0.1', port = config.port or 8086 }
  end

  -------------
  -- Set CMP --
  -------------
  cmp.setup.filetype({ 'dap-repl', 'dapui_watches' }, {
    sources = {
      { name = 'dap' },
    },
  })
  cmp.setup {
    enabled = function()
      return vim.api.nvim_buf_get_option(0, 'buftype') ~= 'prompt' or require('cmp_dap').is_dap_buffer()
    end,
  }
end

return M
