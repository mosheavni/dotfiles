local function join_paths(...)
  local result = table.concat({ ... }, '/')
  return result
end

local temp_dir = vim.loop.os_getenv 'TEMP' or '/tmp'
local package_root = join_paths(temp_dir, 'nvim', 'site', 'lazy')
local lazypath = join_paths(temp_dir, 'nvim', 'site') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    '--single-branch',
    'https://github.com/folke/lazy.nvim.git',
    lazypath,
  }
end
vim.opt.runtimepath:prepend(lazypath)

require('lazy').setup({
  {
    'akinsho/bufferline.nvim',
    version = '^3',
    config = function()
      require 'user.plugins.bufferline'
    end,
  },
}, {
  root = package_root,
})
