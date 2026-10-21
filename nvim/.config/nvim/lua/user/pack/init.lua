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
    end
  end,
})

require 'plugins.treesitter'()
require('plugins.mini').eager()
require 'plugins.gitsigns'()
require('plugins.editor').eager()
require 'plugins.kubectl'()

vim.schedule(function()
  require('plugins.mini').deferred()
  require('plugins.editor').deferred()
  require 'plugins.git'()
  require 'plugins.lsp'()
  require 'plugins.fzf'()
  require 'plugins.conform'()
  require 'plugins.lint'()
  require 'plugins.blink'()
  require 'plugins.ai'()
  require 'plugins.tree'()
  require 'plugins.mini-statusline'()

  vim.api.nvim_exec_autocmds('User', { pattern = 'DeferredPluginsLoaded' })
end)

-- Plugin updates via the native vim.pack confirmation buffer (:h vim.pack.update()).
vim.keymap.set('n', '<leader>z', function()
  vim.pack.update()
end, { desc = 'Update plugins (vim.pack)' })

vim.api.nvim_create_autocmd('FileType', {
  desc = 'Key hints for the vim.pack update confirmation buffer',
  group = vim.api.nvim_create_augroup('PackUpdateHints', { clear = true }),
  pattern = 'nvim-pack',
  callback = function(ev)
    local hints = table.concat({
      ':w     apply updates',
      ':q     discard',
      ']] [[  next/prev plugin',
      'K      details for change at cursor',
      'gx     open commit/repo in browser',
      'gra    plugin actions (update/skip/delete)',
      'gO     buffer outline',
    }, '\n')
    vim.keymap.set('n', 'g?', function()
      vim.notify(hints, vim.log.levels.INFO, { title = 'vim.pack update keys' })
    end, { buffer = ev.buf, desc = 'Show update-buffer keys' })
    vim.notify('g? for keys · :w apply · :q discard', vim.log.levels.INFO, { title = 'vim.pack' })
  end,
})
