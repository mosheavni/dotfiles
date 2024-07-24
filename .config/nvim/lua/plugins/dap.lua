local actions = function()
  local dap = require 'dap'
  local dapui = require 'dapui'
  return {
    ['continue (F5)'] = function()
      dap.continue()
    end,
    ['step over'] = function()
      dap.step_over()
    end,
    ['step into'] = function()
      dap.step_into()
    end,
    ['step out'] = function()
      dap.step_out()
    end,
    ['toggle breakpoint'] = function()
      dap.toggle_breakpoint()
    end,
    ['clear all breakpoints'] = function()
      dap.clear_breakpoints()
    end,
    ['open repl'] = function()
      dap.repl.open()
    end,
    ['run last'] = function()
      dap.run_last()
    end,
    ['ui'] = function()
      dapui.toggle()
    end,
    ['log level trace'] = function()
      dap.set_log_level 'TRACE'
      vim.cmd 'DapShowLog'
    end,
  }
end

local M = {
  'mfussenegger/nvim-dap',
  init = function()
    vim.api.nvim_create_user_command('DAP', function()
      require 'dap'
      require('dapui').toggle()
    end, {})
    require('user.menu').add_actions('DAP', {
      ['Load DAP'] = function()
        vim.cmd.DAP()
      end,
    })
  end,
  cmd = { 'DAP' },
  dependencies = {
    'nvim-neotest/nvim-nio',
    'rcarriga/nvim-dap-ui',
    { 'mfussenegger/nvim-dap-python', lazy = true },
    'rcarriga/cmp-dap',
    'mxsdev/nvim-dap-vscode-js',
    'theHamsta/nvim-dap-virtual-text',
    'jay-babu/mason-nvim-dap.nvim',
    { 'leoluz/nvim-dap-go', lazy = true },
  },
}

M.keys = {
  { '<F5>', '<cmd>lua require("dap").continue()<cr>' },
  { '<leader>bp', '<cmd>lua require("dap").toggle_breakpoint()<cr>' },
}

M.config = function()
  local cmp = require 'cmp'
  local mason_nvim_dap = require 'mason-nvim-dap'
  ---@diagnostic disable-next-line: missing-fields
  mason_nvim_dap.setup {
    ensure_installed = {
      'bash',
      'chrome',
      'node2',
      'python',
    },
    automatic_setup = true,
    handlers = {
      function(config)
        -- all sources with no handler get passed here

        -- Keep original functionality
        require('mason-nvim-dap').default_setup(config)
      end,
    },
  }
  -- mason_nvim_dap.setup_handlers()

  local dap = require 'dap'
  local dapui = require 'dapui'
  dapui.setup()
  require('nvim-dap-virtual-text').setup { enabled = true }

  vim.fn.sign_define('DapBreakpoint', { text = '🛑', texthl = '', linehl = '', numhl = '' })
  vim.fn.sign_define('DapBreakpointRejected', { text = '❓', texthl = '', linehl = '', numhl = '' })
  vim.fn.sign_define('DapStopped', { text = '⭕️', texthl = '', linehl = '', numhl = '' })

  -- Actions
  local the_actions = actions()
  require('user.menu').add_actions('DAP', the_actions)
  vim.keymap.set('n', '<leader>dm', function()
    vim.ui.select(vim.tbl_keys(the_actions), { prompt = 'Choose DAP action' }, function(choice)
      if choice then
        the_actions[choice]()
      end
    end)
  end)

  -- Python
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
    ---@diagnostic disable-next-line: undefined-field
    callback { type = 'server', host = config.host or '127.0.0.1', port = config.port or 8086 }
  end

  -- go
  require('dap-go').setup()

  -------------
  -- Set CMP --
  -------------
  ---@diagnostic disable-next-line: missing-fields
  cmp.setup.filetype({ 'dap-repl', 'dapui_watches' }, {
    sources = {
      { name = 'dap' },
    },
  })
  ---@diagnostic disable-next-line: missing-fields
  cmp.setup {
    enabled = function()
      return vim.api.nvim_get_option_value('buftype', { buf = 0 }) ~= 'prompt' or require('cmp_dap').is_dap_buffer()
    end,
  }
end

return M
