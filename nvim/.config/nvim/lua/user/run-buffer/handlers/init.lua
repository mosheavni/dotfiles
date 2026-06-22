-- Builtin run-buffer handlers: one module per filetype under handlers/.
local M = {}

local modules = {
  require 'user.run-buffer.handlers.make',
  require 'user.run-buffer.handlers.yaml_ghaction',
  require 'user.run-buffer.handlers.lua',
  require 'user.run-buffer.handlers.groovy',
  require 'user.run-buffer.handlers.markdown',
  require 'user.run-buffer.handlers.terraform',
  require 'user.run-buffer.handlers.html',
}

--- Register all builtin handler modules with the run-buffer registry.
---@param registry table Object with `register_handler_module(mod)`.
function M.register_all(registry)
  for _, mod in ipairs(modules) do
    registry.register_handler_module(mod)
  end
end

return M
