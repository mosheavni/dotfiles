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
}

return M
