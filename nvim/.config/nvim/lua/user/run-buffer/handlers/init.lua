-- Builtin run-buffer handlers and registry.
local M = {}

---@type table<string, RunHandler>
local handlers = {}

--- Register a handler from a `{ ft, handler }` module.
---@param mod RunHandlerModule
function M.register(mod)
  handlers[mod.ft] = mod.handler
end

--- Lookup a registered handler by filetype.
---@param ft string
---@return RunHandler|nil
function M.get(ft)
  return handlers[ft]
end

local modules = {
  require 'user.run-buffer.handlers.make',
  require 'user.run-buffer.handlers.yaml_ghaction',
  require 'user.run-buffer.handlers.terraform',
  require 'user.run-buffer.handlers.lua',
  require 'user.run-buffer.handlers.groovy',
  require 'user.run-buffer.handlers.markdown',
  require 'user.run-buffer.handlers.html',
}

for _, mod in ipairs(modules) do
  M.register(mod)
end

return M
