local utils = require 'user.utils'
local opts = utils.map_opts
local keymap = utils.keymap
local dap = require 'dap'
require('telescope').load_extension 'dap'
local dapui = require 'dapui'
dapui.setup()
require('nvim-dap-virtual-text').setup {
  commented = true,
}
vim.g.dap_virtual_text = true
vim.fn.sign_define('DapBreakpoint', { text = '🛑', texthl = '', linehl = '', numhl = '' })
vim.fn.sign_define('DapBreakpointRejected', { text = '❓', texthl = '', linehl = '', numhl = '' })
vim.fn.sign_define('DapStopped', { text = '⭕️', texthl = '', linehl = '', numhl = '' })

-- Mappings
keymap('n', '<F5>', '<cmd>lua require("dap").continue()<cr>', opts.no_remap)
keymap('n', '<leader>bp', '<cmd>lua require("dap").toggle_breakpoint()<cr>', opts.no_remap)

-- Python
require('dap-python').setup '/usr/local/bin/python3'

table.insert(dap.configurations.python, {
  justMyCode = false,
})

-- Javascript
-- require('dap-vscode-js').setup {
--   debugger_path = '(runtimedir)/site/pack/packer/opt/vscode-js-debug', -- Path to vscode-js-debug installation.
--   adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' }, -- which adapters to register in nvim-dap
-- }

for _, language in ipairs { 'typescript', 'javascript', 'javascriptreact' } do
  dap.configurations[language] = {
    {
      type = 'pwa-node',
      request = 'launch',
      name = 'Launch file',
      program = '${file}',
      cwd = '${workspaceFolder}',
    },
    {
      type = 'pwa-node',
      request = 'attach',
      name = 'Attach',
      processId = require('dap.utils').pick_process,
      cwd = '${workspaceFolder}',
    },
  }
end

-- Bash
dap.adapters.sh = {
  type = 'executable',
  command = 'bash-debug-adapter',
}
dap.configurations.sh = {
  {
    args = {},
    argsString = '',
    cwd = '${workspaceFolder}',
    env = {},
    name = 'Launch file',
    pathBash = '/usr/local/bin/bash',
    pathBashdb = '/usr/local/bin/bashdb',
    pathBashdbLib = '/usr/local/share/bashdb/',
    pathCat = '/usr/local/bin/gcat',
    pathMkfifo = '/usr/bin/mkfifo',
    pathPkill = '/usr/bin/pkill',
    program = '${file}',
    request = 'launch',
    showDebugOutput = false,
    terminalKind = 'debugConsole',
    trace = true,
    type = 'sh',
  },
}

-- Menu
local pretty_print = function(message)
  vim.notify(message, 2, { title = 'DAP Actions', icon = '' })
end

local dap_actions = {
  ['continue'] = function()
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

keymap('n', '<leader>a', function()
  vim.ui.select(vim.tbl_keys(dap_actions), { prompt = 'Choose dap action' }, function(choice)
    if choice then
      dap_actions[choice]()
    end
  end)
end)
