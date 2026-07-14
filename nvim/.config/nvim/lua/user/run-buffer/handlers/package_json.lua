local utils = require 'user.utils'

local M = {}

M.ft = 'json.package'

--- Read the `scripts` table from a package.json into numbered labels for `inputlist`.
---@param path string Absolute path to package.json.
---@return { text: string, value: string }[] Options like `{ text = "1 - test", value = "test" }`.
function M.get_script_options(path)
  local options = {}

  local pkg = utils.read_json_file(path)
  if not pkg or type(pkg.scripts) ~= 'table' then
    return options
  end

  local names = vim.tbl_keys(pkg.scripts)
  table.sort(names)
  for i, name in ipairs(names) do
    table.insert(options, { text = i .. ' - ' .. name .. ': ' .. pkg.scripts[name], value = name })
  end

  return options
end

--- Prompt for a package.json script via `inputlist`; returns `npm run <script>` or nil.
---@param file_name string Absolute path to package.json.
---@return string|nil cmd
function M.pick_script_cmd(file_name)
  local options = M.get_script_options(file_name)
  if #options == 0 then
    vim.notify('No scripts found in ' .. vim.fs.basename(file_name), vim.log.levels.WARN, { title = 'run-buffer' })
    return nil
  end
  if #options == 1 then
    return 'npm run ' .. options[1].value
  end
  local labels = vim.tbl_map(function(option)
    return option.text
  end, options)
  local idx = vim.fn.inputlist(labels)
  if idx <= 0 then
    return nil
  end
  return 'npm run ' .. options[idx].value
end

---@type RunHandler
M.handler = {
  resolve = function(ctx)
    local cmd = M.pick_script_cmd(ctx.file_name)
    if not cmd then
      return { spawn = false }
    end
    return { cmd = cmd, spawn = true }
  end,
}

return M
