-- Handler registry and command resolution for run-buffer.
local utils = require 'user.utils'

---@type table<string, RunHandler>
local handlers = {}

--- Default resolve: `command_for_filetype` + file path, or shebang path only.
---@param ctx RunContext
---@return RunResult
local function default_resolve(ctx)
  local cmd = utils.command_for_filetype(ctx.ft)
  if ctx.first_line:match '^#!' then
    cmd = ctx.file_name
  else
    cmd = cmd .. ' ' .. ctx.file_name
  end
  return { cmd = cmd, done = false }
end

--- Dispatch to a registered handler or the default builder.
---@param ctx RunContext
---@param on_done RunOnDone
local function invoke_resolve(ctx, on_done)
  local h = handlers[ctx.ft]
  if h and h.resolve then
    h.resolve(ctx, on_done)
    return
  end
  local result = default_resolve(ctx)
  on_done(result.cmd, result.done)
end

local M = {}

--- Look up the handler registered for a filetype.
---@param ft string
---@return RunHandler|nil
function M.get(ft)
  return handlers[ft]
end

--- Register a run handler table under a filetype key.
---@param ft string
---@param handler RunHandler
function M.register_handler(ft, handler)
  handlers[ft] = handler
end

--- Register a handler from a `{ ft, handler }` module.
---@param mod RunHandlerModule
function M.register_handler_module(mod)
  handlers[mod.ft] = mod.handler
end

--- Resolve how to run the current buffer and invoke `on_done` with the result.
--- Builds `RunContext` from the current buffer's first line.
---@param ft string
---@param file_name string Absolute path to run.
---@param on_done RunOnDone
function M.run(ft, file_name, on_done)
  invoke_resolve({
    ft = ft,
    file_name = file_name,
    first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or '',
  }, on_done)
end

--- Blocking wrapper around `invoke_resolve` for tests and synchronous callers.
--- Only reliable when the handler calls `on_done` before returning.
---@param ctx RunContext
---@return RunResult
function M.resolve_sync(ctx)
  local result
  invoke_resolve(ctx, function(cmd, done)
    result = { cmd = cmd, done = done }
  end)
  return result
end

require('user.run-buffer.handlers').register_all(M)

return M
