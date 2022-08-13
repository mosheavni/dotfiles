local dap = require 'dap'
require('telescope').load_extension 'dap'
require('dapui').setup()
require('nvim-dap-virtual-text').setup {
  commented = true,
}
vim.g.dap_virtual_text = true
vim.fn.sign_define('DapBreakpoint', { text = '🛑', texthl = '', linehl = '', numhl = '' })

-- Mappings
vim.keymap.set('n', '<F5>', '<cmd>lua require("dap").continue()<cr>', { noremap = true })
vim.keymap.set('n', '<leader>bp', '<cmd>lua require("dap").toggle_breakpoint()<cr>', { noremap = true })

-- Python
require('dap-python').setup '/usr/local/bin/python3'

table.insert(require('dap').configurations.python, {
  justMyCode = false,
})

-- Javascript
require('dap-vscode-js').setup {
  debugger_path = '(runtimedir)/site/pack/packer/opt/vscode-js-debug', -- Path to vscode-js-debug installation.
  adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' }, -- which adapters to register in nvim-dap
}

for _, language in ipairs { 'typescript', 'javascript', 'javascriptreact' } do
  require('dap').configurations[language] = {
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
    showDebugOutput = true,
    terminalKind = 'debugConsole',
    trace = false,
    type = 'sh',
  },
}

-- Menu
local pretty_print = function(message)
  vim.notify(message, 2, { title = 'DAP Actions', icon = '' })
end

local dap_actions = {
  ['continue'] = function()
    require('dap').continue()
  end,
  ['step over'] = function()
    require('dap').step_over()
  end,
  ['step into'] = function()
    require('dap').step_into()
  end,
  ['step out'] = function()
    require('dap').step_out()
  end,
  ['toggle breakpoint'] = function()
    require('dap').toggle_breakpoint()
  end,
  ['clear all breakpoints'] = function()
    require('dap').clear_breakpoints()
  end,
  ['open repl'] = function()
    require('dap').repl.open()
  end,
  ['run last'] = function()
    require('dap').run_last()
  end,
  ['ui'] = function()
    require('dapui').toggle()
  end,
  ['log level trace'] = function()
    require('dap').set_log_level 'TRACE'
    vim.cmd 'DapShowLog'
  end,
}

vim.keymap.set('n', '<leader>a', function()
  vim.ui.select(vim.tbl_keys(dap_actions), { prompt = 'Choose dap action' }, function(choice)
    if choice then
      dap_actions[choice]()
    end
  end)
end)
