-- Handler registry and command resolution for run-buffer.
local utils = require 'user.utils'

---@type table<string, RunHandler>
local handlers = {}

--- Filetypes whose resolved command must not include the buffer path.
local append_file = {
  terraform = false,
}

--- Default resolve: `command_for_filetype` + file path, or shebang path only.
---@param ctx RunContext
---@return RunResult
local function default_resolve(ctx)
  local cmd
  if ctx.first_line:match '^#!' then
    cmd = ctx.file_name
  else
    cmd = utils.command_for_filetype(ctx.ft)
    if append_file[ctx.ft] ~= false then
      cmd = cmd .. ' ' .. ctx.file_name
    end
  end
  return { cmd = cmd, spawn = true }
end

--- Dispatch to a registered handler or the default builder.
---@param ctx RunContext
---@return RunResult
local function invoke_resolve(ctx)
  local h = handlers[ctx.ft]
  if h and h.resolve then
    return h.resolve(ctx)
  end
  return default_resolve(ctx)
end

local M = {}

--- Register a handler from a `{ ft, handler }` module.
---@param mod RunHandlerModule
function M.register_handler_module(mod)
  handlers[mod.ft] = mod.handler
end

--- Working directory for running the buffer (handler `cwd` or parent of the buffer file).
---@param ft string
---@return string
function M.cwd(ft)
  local h = handlers[ft]
  if h and h.cwd then
    return h.cwd()
  end
  return vim.fn.expand '%:p:h'
end

--- Resolve how to run the current buffer.
--- Builds `RunContext` from the current buffer's first line.
---@param ft string
---@param file_name string Absolute path to run.
---@return RunResult
function M.run(ft, file_name)
  return invoke_resolve {
    ft = ft,
    file_name = file_name,
    first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or '',
  }
end

require('user.run-buffer.handlers').register_all(M)

return M
