-- Install/update hooks. Must be registered before the first vim.pack.add().
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if kind ~= 'install' and kind ~= 'update' then
      return
    end

    local ensure_loaded = function()
      if not ev.data.active then
        vim.cmd.packadd(name)
      end
    end

    if name == 'nvim-treesitter' then
      ensure_loaded()
      vim.cmd 'TSUpdate'
    elseif name == 'LuaSnip' and kind == 'install' then
      vim.system({ 'make', 'install_jsregexp' }, { cwd = ev.data.path }):wait()
    elseif name == 'markdown-preview.nvim' and kind == 'install' then
      vim.system({ 'yarn', 'install' }, { cwd = ev.data.path .. '/app' }):wait()
    elseif name == 'mcphub.nvim' and kind == 'install' then
      vim.system({ 'npm', 'install', '-g', 'mcp-hub@latest' }):wait()
    elseif name == 'go.nvim' and kind == 'update' then
      ensure_loaded()
      vim.cmd 'lua require("go.install").update_all_sync()'
    end
  end,
})

require('plugins.look-and-feel').eager()
require('plugins.mini').eager()
require 'plugins.gitsigns'()
require('plugins.functionality').eager()
require 'plugins.kubectl'()

vim.schedule(function()
  require('plugins.look-and-feel').deferred()
  require('plugins.mini').deferred()
  require('plugins.functionality').deferred()
  require 'plugins.git'()
  require 'plugins.treesitter'()
  require 'plugins.lsp'()
  require 'plugins.fzf'()
  require 'plugins.conform'()
  require 'plugins.lint'()
  require 'plugins.blink'()
  require 'plugins.ai'()
  require 'plugins.tree'()
  require 'plugins.overseer'()
  require 'plugins.mini-statusline'()

  vim.api.nvim_exec_autocmds('User', { pattern = 'DeferredPluginsLoaded' })
end)

require 'user.pack.float'
vim.keymap.set('n', '<leader>z', '<cmd>PackFloat<cr>', { silent = true, desc = 'Update plugins' })
