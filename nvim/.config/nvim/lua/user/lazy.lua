local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  vim
    .system({
      'git',
      'clone',
      '--filter=blob:none',
      '--single-branch',
      'https://github.com/folke/lazy.nvim.git',
      lazypath,
    })
    :wait()
end
vim.opt.runtimepath:prepend(lazypath)

require('lazy').setup('plugins', {
  dev = { path = '~/Repos' },
  change_detection = { notify = false },
  ui = {
    border = 'rounded',
    custom_keys = {
      ['<localleader>t'] = function(plugin)
        vim.fn.setreg('+', plugin.dir)
        vim.notify('Copied path to clipboard: ' .. plugin.dir)
      end,
    },
  },
  diff = {
    cmd = 'diffview.nvim',
  },
  checker = { enabled = false },
  performance = {
    rtp = {
      disabled_plugins = {
        '2html_plugin',
        'getscript',
        'getscriptPlugin',
        'gzip',
        'logipat',
        'matchit',
        'matchparen',
        'netrw',
        'netrwFileHandlers',
        'netrwPlugin',
        'netrwSettings',
        'rplugin',
        'rrhelper',
        'shada',
        'spellfile_plugin',
        'tar',
        'tarPlugin',
        'tohtml',
        'tutor',
        'vimball',
        'vimballPlugin',
        'zip',
        'zipPlugin',
      },
    },
  },
})

vim.keymap.set('n', '<leader>z', '<cmd>Lazy<CR>', { silent = true })
