local utils = require 'user.utils'
local nmap = utils.nmap

local M = {}
M.git_actions = require('user.actions').git
M.lsp_actions = require('user.actions').lsp
M.random_actions = require('user.actions').random

M.dap_actions = {}

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

M.set_actions = function()
  M.actions = vim.tbl_extend('force', add_prefix(M.dap_actions, 'DAP'), add_prefix(M.git_actions, 'Git'), add_prefix(M.lsp_actions, 'LSP'), M.random_actions)
end

M.set_dap_actions = function()
  M.dap_actions = require('user.actions').dap()
  M.set_actions()
end

M.setup = function()
  M.set_actions()
  nmap('<leader>a', function()
    vim.ui.select(vim.tbl_keys(M.actions), { prompt = 'Choose action (' .. vim.tbl_count(M.actions) .. ' actions)' }, function(choice)
      if choice then
        M.actions[choice]()
      end
    end)
  end)
end

return M
