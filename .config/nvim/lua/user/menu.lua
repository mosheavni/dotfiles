local utils = require 'user.utils'
-- local opts = utils.map_opts
local keymap = utils.keymap
local dap_actions = require('user.plugins.dap').actions
local git_actions = require('user.git').actions
local lsp_actions = require('user.lsp').actions

-- add-prefix function
-- receives a table of functions and returns a table of functions with the
-- prefix added to the key
local function add_prefix(actions, prefix)
  local prefixed_actions = {}
  for k, v in pairs(actions) do
    prefixed_actions[prefix .. ' - ' .. k] = v
  end
  return prefixed_actions
end

-- Merge all actions and prepend type to the name using add_prefix function
-- I.E: Git - Delete tag
-- I.E: Dap - Continue
local actions = vim.tbl_extend('force', add_prefix(dap_actions, 'DAP'), add_prefix(git_actions, 'Git'), add_prefix(lsp_actions, 'LSP'))

keymap('n', '<leader>a', function()
  vim.ui.select(vim.tbl_keys(actions), { prompt = 'Choose action' }, function(choice)
    if choice then
      actions[choice]()
    end
  end)
end)
