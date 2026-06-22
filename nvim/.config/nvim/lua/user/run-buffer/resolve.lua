-- Handler registry and command resolution for run-buffer.
local utils = require 'user.utils'

---@type table<string, RunHandler>
local handlers = {}

local M = {}

--- Register a handler from a `{ ft, handler }` module.
---@param mod RunHandlerModule
function M.register_handler_module(mod)
  handlers[mod.ft] = mod.handler
end

--- Resolve how to run the current buffer.
--- Builds `RunContext` from the current buffer's first line.
---@param ft string
---@param file_name string Absolute path to run.
---@return RunResult
function M.run(ft, file_name)
  local ctx = {
    ft = ft,
    file_name = file_name,
    first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or '',
  }
  local h = handlers[ctx.ft]
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

require('user.run-buffer.handlers').register_all(M)

return M
