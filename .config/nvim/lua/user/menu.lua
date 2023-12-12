local utils = require 'user.utils'
local nmap = utils.nmap

local M = {
  actions = require 'user.actions',
}

local function add_prefix(actions, prefix)
  local prefixed_actions = {}
  for k, v in pairs(actions) do
    prefixed_actions['[' .. prefix .. '] ' .. k] = v
  end
  return prefixed_actions
end

M.add_actions = function(prefix, actions)
  local actions_prefixed = {}
  if prefix ~= nil then
    actions_prefixed = add_prefix(actions, prefix)
  else
    actions_prefixed = actions
  end
  M.actions = vim.tbl_extend('force', M.actions, actions_prefixed)
end

M.setup = function()
  nmap('<leader>a', function()
    vim.ui.select(vim.tbl_keys(M.actions), { prompt = 'Choose action❯ ' }, function(choice)
      if choice then
        M.actions[choice]()
      end
    end)
  end)
end

return M
