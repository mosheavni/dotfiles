local M = {
  actions = require 'user.actions',
}

---Add a prefix to all actions
---@param actions table<string, function>
---@param prefix string
---@return table<string, function>
local function add_prefix(actions, prefix)
  local prefixed_actions = {}
  for k, v in pairs(actions) do
    prefixed_actions['[' .. prefix .. '] ' .. k] = v
  end
  return prefixed_actions
end

---Add actions to the existing actions table
---@param prefix? string optional prefix to add to all actions
---@param actions table<string, function> Actions table
M.add_actions = function(prefix, actions)
  local actions_prefixed = actions
  if prefix ~= nil then
    actions_prefixed = add_prefix(actions, prefix)
  end
  M.actions = vim.tbl_extend('force', M.actions, actions_prefixed)
end

---Get all actions or filter by prefix
---@param opts table|nil optional filter options
---  * {prefix: string} filter actions by prefix
---@return table<string, string>
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

---Setup the menu
---@return nil
M.setup = function()
  vim.keymap.set('n', '<leader>a', function()
    vim.ui.select(vim.tbl_keys(M.actions), { title = 'Actions', prompt = 'Choose action❯ ' }, function(choice)
      if choice then
        M.actions[choice]()
      end
    end)
  end)
end

return M
