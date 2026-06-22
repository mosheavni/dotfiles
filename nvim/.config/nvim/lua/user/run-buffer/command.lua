-- Build how to run the current buffer (handler lookup + default command).
local handlers = require 'user.run-buffer.handlers'
local utils = require 'user.utils'

local M = {}

--- Build a run plan for the current buffer.
--- Reads the buffer's first line into `RunContext` for shebang detection.
---@param ft string
---@param file_name string Absolute path to run.
---@return RunResult
function M.build(ft, file_name)
  local ctx = {
    ft = ft,
    file_name = file_name,
    first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or '',
  }
  local h = handlers.get(ctx.ft)
  if h and h.resolve then
    return h.resolve(ctx)
  end
  local cmd
  if ctx.first_line:match '^#!' then
    cmd = ctx.file_name
  else
    cmd = utils.command_for_filetype(ctx.ft) .. ' ' .. ctx.file_name
  end
  return { cmd = cmd, spawn = true }
end

return M
