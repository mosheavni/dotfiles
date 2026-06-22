-- Neovim lua: hot-reload in-process; no shell command.
local M = {}

M.ft = 'lua'

---@type RunHandler
M.handler = {
  resolve = function(ctx)
    local path = ctx.file_name:match 'nvim/lua/(.*)%.lua'
    if path then
      path = path:gsub('/', '.')
      if package.loaded[path] then
        package.loaded[path] = nil
        vim.notify('Unloaded package.path: ' .. path, vim.log.levels.INFO)
      end
    end
    vim.cmd 'luafile %'
    vim.notify('Reloading lua file', vim.log.levels.INFO)
    return { spawn = false }
  end,
}

return M
