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
  local actions_prefixed = actions
  if prefix ~= nil then
    actions_prefixed = add_prefix(actions, prefix)
  end
  M.actions = vim.tbl_extend('force', M.actions, actions_prefixed)
end

M.get_actions = function(opts)
  if opts and opts.prefix then
    -- filter only for actions starting with [prefix]
    local actions = {}
    for k, v in pairs(M.actions) do
      if k:lower():find('^%[' .. opts.prefix:lower() .. '%]') then
        actions[k] = v
      end
    end
    return actions
  end
  return M.actions
end

M.setup = function()
  vim.keymap.set('n', '<leader>a', function()
    vim.ui.select(vim.tbl_keys(M.actions), { prompt = 'Choose action❯ ' }, function(choice)
      if choice then
        M.actions[choice]()
      end
    end)
  end)
end

return M
