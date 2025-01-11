local actions = function()
  local dap = require 'dap'
  local dapui = require 'dapui'
  return {
    ['continue (F5)'] = function()
      dap.continue()
    end,
    ['step over (<leader>do)'] = function()
      dap.step_over()
    end,
    ['step into (<leader>di)'] = function()
      dap.step_into()
    end,
    ['step out (<leader>dO)'] = function()
      dap.step_out()
    end,
    ['terminate (<leader>dq)'] = function()
      dap.terminate()
    end,
    ['toggle breakpoint (<leader>db)'] = function()
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
    ['ui (<leader>du)'] = function()
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
  },
}

M.keys = {
  { '<F5>', '<cmd>lua require("dap").continue()<cr>' },
  { '<leader>db', '<cmd>lua require("dap").toggle_breakpoint()<cr>' },
}

M.config = function()
  local dap = require 'dap'
  local dapui = require 'dapui'
  local dap_python = require 'dap-python'
  local cmp = require 'cmp'
  local mason_nvim_dap = require 'mason-nvim-dap'

  dapui.setup()
  dap.listeners.after.event_initialized['dapui_config'] = function()
    dapui.open {}
  end
  dap.listeners.before.event_terminated['dapui_config'] = function()
    dapui.close {}
  end
  dap.listeners.before.event_exited['dapui_config'] = function()
    dapui.close {}
  end

  ---@diagnostic disable-next-line: missing-fields
  require('nvim-dap-virtual-text').setup {
    commented = true, -- Show virtual text alongside comment
  }

  ---@diagnostic disable-next-line: missing-fields
  mason_nvim_dap.setup {
    automatic_installation = true,
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
        mason_nvim_dap.default_setup(config)
      end,
    },
  }

  dap_python.setup 'python3'
  dap.adapters.bashdb = {
    type = 'executable',
    command = vim.fn.stdpath 'data' .. '/mason/packages/bash-debug-adapter/bash-debug-adapter',
    name = 'bashdb',
  }
  local dap_conf_sh = {
    {
      type = 'bashdb',
      request = 'launch',
      name = 'Launch file',
      showDebugOutput = true,
      pathBashdb = vim.fn.stdpath 'data' .. '/mason/packages/bash-debug-adapter/extension/bashdb_dir/bashdb',
      pathBashdbLib = vim.fn.stdpath 'data' .. '/mason/packages/bash-debug-adapter/extension/bashdb_dir',
      trace = true,
      file = '${file}',
      program = '${file}',
      cwd = '${workspaceFolder}',
      pathCat = 'cat',
      pathBash = '/opt/homebrew/bin/bash',
      pathMkfifo = 'mkfifo',
      pathPkill = 'pkill',
      args = {},
      env = {},
      terminalKind = 'integrated',
    },
  }
  dap.configurations.sh = dap_conf_sh
  dap.configurations.bash = dap_conf_sh

  vim.fn.sign_define('DapBreakpoint', { text = '', texthl = 'DiagnosticSignError', linehl = '', numhl = '' })
  vim.fn.sign_define('DapBreakpointRejected', { text = '', texthl = 'DiagnosticSignError', linehl = '', numhl = '' })
  vim.fn.sign_define('DapStopped', { text = '', texthl = 'DiagnosticSignWarn', linehl = 'Visual', numhl = 'DiagnosticSignWarn' })

  -- Actions
  local the_actions = actions()
  require('user.menu').add_actions('DAP', the_actions)
  vim.keymap.set('n', '<leader>dm', function()
    vim.ui.select(vim.tbl_keys(the_actions), { prompt = 'Choose DAP action', title = 'DAP Actions' }, function(choice)
      if choice then
        the_actions[choice]()
      end
    end)
  end)

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

  -------------
  -- keymaps --
  -------------
  local opts = { noremap = true, silent = true, buffer = true }

  -- Continue / Start
  vim.keymap.set('n', '<leader>dc', function()
    dap.continue()
  end, opts)

  -- Step Over
  vim.keymap.set('n', '<leader>do', function()
    dap.step_over()
  end, opts)

  -- Step Into
  vim.keymap.set('n', '<leader>di', function()
    dap.step_into()
  end, opts)

  -- Step Out
  vim.keymap.set('n', '<leader>dO', function()
    dap.step_out()
  end, opts)

  -- Keymap to terminate debugging
  vim.keymap.set('n', '<leader>dq', function()
    dap.terminate()
  end, opts)

  -- Toggle DAP UI
  vim.keymap.set('n', '<leader>du', function()
    dapui.toggle()
  end, opts)
end

return M
