-- HTML: open in the system browser via vim.ui.open.
local M = {}

M.ft = 'html'

---@type RunHandler
M.handler = {
  resolve = function(ctx)
    vim.ui.open(ctx.file_name)
    return { spawn = false }
  end,
}

return M
