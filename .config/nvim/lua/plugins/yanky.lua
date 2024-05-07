local M = {
  'gbprod/yanky.nvim',
  dependencies = { 'kkharji/sqlite.lua' },
  cmd = { 'YankyRingHistory' },
  keys = {
    'yy',
    { 'p', '<Plug>(YankyPutAfter)', mode = { 'n', 'x' } },
    { 'P', '<Plug>(YankyPutBefore)', mode = { 'n', 'x' } },
    { '<c-n>', '<Plug>(YankyCycleForward)' },
    { '<c-m>', '<Plug>(YankyCycleBackward)' },
    { '<leader>y', '<Cmd>YankyRingHistory<cr>' },
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
    require('user.menu').add_actions('Yanky',{
      ['Yank history'] = function()
        vim.cmd('YankyRingHistory')
      end
    })
  end,
}

return M
