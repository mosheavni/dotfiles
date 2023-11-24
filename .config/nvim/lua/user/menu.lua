local utils = require 'user.utils'
local nmap = utils.nmap

local M = {
  actions = require 'user.actions',
}

-- add-prefix function
-- receives a table of functions and returns a table of functions with the
-- prefix added to the key
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

-- Merge all actions and prepend type to the name using add_prefix function
-- I.E: Git - Delete tag
-- I.E: Dap - Continue

M.setup = function()
  nmap('<leader>a', function()
    vim.ui.select(vim.tbl_keys(M.actions), { prompt = 'Choose action (' .. vim.tbl_count(M.actions) .. ' actions)' }, function(choice)
      if choice then
        M.actions[choice]()
      end
    end)
  end)
end

return M
