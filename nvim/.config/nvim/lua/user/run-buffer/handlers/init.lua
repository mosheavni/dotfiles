-- Builtin run-buffer handlers (except Makefile, which lives in make.lua).
local utils = require 'user.utils'

local M = {}

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

local modules = {
  require 'user.run-buffer.handlers.make',
  -- GitHub Actions workflow: `act` via user.gh-actions; cwd is repo root.
  {
    ft = 'yaml.ghaction',
    handler = {
      resolve = function(ctx, on_done)
        local cmd = require('user.gh-actions').build_act_cmd(ctx.file_name)
        on_done(cmd, cmd == nil)
      end,
      cwd = function()
        local root = require('user.git').get_toplevel_sync()
        if root ~= '' then
          return root
        end
        return vim.fn.expand '%:p:h'
      end,
    },
  },
  -- Neovim lua: hot-reload in-process; no shell command.
  {
    ft = 'lua',
    handler = {
      resolve = function(ctx, on_done)
        run_lua(ctx.file_name)
        on_done(nil, true)
      end,
    },
  },
  -- Jenkinsfile: validate via user.jenkins-validate; no shell command.
  {
    ft = 'groovy',
    handler = {
      resolve = function(_, on_done)
        require('user.jenkins-validate').validate()
        on_done(nil, true)
      end,
    },
  },
  -- Markdown preview: detached mdserve.
  {
    ft = 'markdown',
    handler = {
      resolve = function(ctx, on_done)
        local job_id = vim.fn.jobstart({ 'mdserve', '--open', ctx.file_name }, { detach = true })
        if job_id <= 0 then
          vim.notify('Failed to start mdserve', vim.log.levels.ERROR, { title = 'run-buffer' })
        end
        on_done(nil, true)
      end,
    },
  },
  -- Terraform: `terraform plan` without appending the file path.
  {
    ft = 'terraform',
    handler = {
      resolve = function(ctx, on_done)
        on_done(utils.command_for_filetype(ctx.ft), false)
      end,
    },
  },
  -- HTML: open in the system browser via vim.ui.open.
  {
    ft = 'html',
    handler = {
      resolve = function(ctx, on_done)
        vim.ui.open(ctx.file_name)
        on_done(nil, true)
      end,
    },
  },
}

--- Register all builtin handler modules with the run-buffer registry.
---@param registry table Object with `register_handler_module(mod)`.
function M.register_all(registry)
  for _, mod in ipairs(modules) do
    registry.register_handler_module(mod)
  end
end

return M
