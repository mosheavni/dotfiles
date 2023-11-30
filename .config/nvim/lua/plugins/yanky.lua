local M = {
  'gbprod/yanky.nvim',
  dependencies = { 'kkharji/sqlite.lua' },
  keys = {
    'yy',
    { 'p', '<Plug>(YankyPutAfter)', mode = { 'n', 'x' } },
    { 'P', '<Plug>(YankyPutBefore)', mode = { 'n', 'x' } },
    { '<c-n>', '<Plug>(YankyCycleForward)' },
    { '<c-m>', '<Plug>(YankyCycleBackward)' },
  },
  opts = {
    ring = {
      history_length = 100,
      storage = 'sqlite',
      sync_with_numbered_registers = true,
      cancel_event = 'update',
    },
  },
  init = function()
    require('user.menu').add_actions('Yanky', {
      ['Yank history'] = function()
        require 'yanky' -- this calls config which sets up yanky
        require('telescope').extensions.yank_history.yank_history()
      end,
    })
  end,
  config = function(_, opts)
    require('yanky').setup(opts)
    require('telescope').load_extension 'yank_history'
  end,
}

return M
