-- Markdown preview: detached mdserve.
local M = {}

M.ft = 'markdown'

---@type RunHandler
M.handler = {
  resolve = function(ctx, on_done)
    local job_id = vim.fn.jobstart({ 'mdserve', '--open', ctx.file_name }, { detach = true })
    if job_id <= 0 then
      vim.notify('Failed to start mdserve', vim.log.levels.ERROR, { title = 'run-buffer' })
    end
    on_done(nil, true)
  end,
}

return M
