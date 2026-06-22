-- HTML: open in the system browser via vim.ui.open.
local M = {}

M.ft = 'html'

---@type RunHandler
M.handler = {
  resolve = function(ctx, on_done)
    vim.ui.open(ctx.file_name)
    on_done(nil, true)
  end,
}

return M
