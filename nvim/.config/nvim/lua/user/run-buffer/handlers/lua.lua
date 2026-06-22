-- Neovim lua: hot-reload in-process; no shell command.
local M = {}

M.ft = 'lua'

--- Reload a Neovim lua module under `nvim/lua/` via `:luafile %`.
--- Clears `package.loaded` for the dotted module path when applicable.
---@param file_name string Absolute path to the `.lua` file.
local function run_lua(file_name)
  local path = file_name:match 'nvim/lua/(.*)%.lua'
  if path then
    path = path:gsub('/', '.')
    if package.loaded[path] then
      package.loaded[path] = nil
      vim.notify('Unloaded package.path: ' .. path, vim.log.levels.INFO)
    end
  end
  vim.cmd 'luafile %'
  vim.notify('Reloading lua file', vim.log.levels.INFO)
end

---@type RunHandler
M.handler = {
  resolve = function(ctx, on_done)
    run_lua(ctx.file_name)
    on_done { spawn = false }
  end,
}

return M
