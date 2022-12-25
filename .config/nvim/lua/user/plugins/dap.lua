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
require('nvim-dap-virtual-text').setup {
  commented = true,
}

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

-- Javascript
-- dap.adapters.node2 = {
--   type = 'executable',
--   command = 'node',
--   args = { vim.fn.stdpath 'data' .. '/mason/packages/node-debug2-adapter/out/src/nodeDebug.js' },
-- }
-- require('dap-vscode-js').setup {
--   -- node_path = "node", -- Path of node executable. Defaults to $NODE_PATH, and then "node"
--   debugger_path = vim.fn.stdpath 'data' .. '/mason/packages/js-debug-adapter', -- Path to vscode-js-debug installation.
--   -- debugger_cmd = { "js-debug-adapter" }, -- Command to use to launch the debug server. Takes precedence over `node_path` and `debugger_path`.
--   adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' }, -- which adapters to register in nvim-dap
--   -- log_file_path = "(stdpath cache)/dap_vscode_js.log" -- Path for file logging
--   -- log_file_level = false -- Logging level for output to file. Set to false to disable file logging.
--   -- log_console_level = vim.log.levels.ERROR -- Logging level for output to console. Set to false to disable console output.
-- }
--
-- P(dap.configurations)
-- for _, language in ipairs { 'typescript', 'javascript', 'javascriptreact' } do
--   dap.configurations[language] = {
--     {
--       name = 'Launch',
--       type = 'node2',
--       request = 'launch',
--       program = '${file}',
--       cwd = vim.fn.getcwd(),
--       sourceMaps = true,
--       protocol = 'inspector',
--       console = 'integratedTerminal',
--     },
--     {
--       -- For this to work you need to make sure the node process is started with the `--inspect` flag.
--       name = 'Attach to process',
--       type = 'node2',
--       request = 'attach',
--       processId = require('dap.utils').pick_process,
--     },
--     -- {
--     --   request = 'launch',
--     --   type = 'pwa-node',
--     --   name = 'Launch file',
--     --   program = '${file}',
--     --   cwd = '${workspaceFolder}',
--     --   runtimeExecutable = 'ts-node',
--     -- },
--     -- {
--     --   type = 'pwa-node',
--     --   request = 'attach',
--     --   name = 'Attach',
--     --   processId = require('dap.utils').pick_process,
--     --   cwd = '${workspaceFolder}',
--     --   runtimeExecutable = 'ts-node',
--     -- },
--   }
-- end

-- Bash
-- dap.adapters.sh = {
--   type = 'executable',
--   command = 'bash-debug-adapter',
-- }
-- dap.configurations.sh = {
--   {
--     args = {},
--     argsString = '',
--     cwd = '${workspaceFolder}',
--     env = {},
--     name = 'Launch file',
--     pathBash = '/usr/local/bin/bash',
--     pathBashdb = '/usr/local/bin/bashdb',
--     pathBashdbLib = '/usr/local/share/bashdb/',
--     pathCat = '/usr/local/bin/gcat',
--     pathMkfifo = '/usr/bin/mkfifo',
--     pathPkill = '/usr/bin/pkill',
--     program = '${file}',
--     request = 'launch',
--     showDebugOutput = false,
--     terminalKind = 'debugConsole',
--     trace = true,
--     type = 'sh',
--   },
-- }

-- Menu
local M = {}
M.actions = {
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

-- keymap('n', '<leader>am', function()
--   vim.ui.select(vim.tbl_keys(M.actions), { prompt = 'Choose dap action' }, function(choice)
--     if choice then
--       M.actions[choice]()
--     end
--   end)
-- end)

return M
