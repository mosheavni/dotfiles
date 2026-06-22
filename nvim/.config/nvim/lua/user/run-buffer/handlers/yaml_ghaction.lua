-- GitHub Actions workflow: `act` via user.gh-actions; cwd is repo root.
local M = {}

M.ft = 'yaml.ghaction'

---@type RunHandler
M.handler = {
  resolve = function(ctx)
    local cmd = require('user.gh-actions').build_act_cmd(ctx.file_name)
    if not cmd then
      return { spawn = false }
    end
    local root = require('user.git').get_toplevel_sync()
    return {
      cmd = cmd,
      spawn = true,
      cwd = root ~= '' and root or vim.fn.expand '%:p:h',
    }
  end,
}

return M
