-- GitHub Actions workflow: `act` via user.gh-actions; cwd is repo root.
local M = {}

M.ft = 'yaml.ghaction'

---@type RunHandler
M.handler = {
  resolve = function(ctx)
    local cmd = require('user.gh-actions').build_act_cmd(ctx.file_name)
    if cmd then
      return { cmd = cmd, spawn = true }
    end
    return { spawn = false }
  end,
  cwd = function()
    local root = require('user.git').get_toplevel_sync()
    if root ~= '' then
      return root
    end
    return vim.fn.expand '%:p:h'
  end,
}

return M
