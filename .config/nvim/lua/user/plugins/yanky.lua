local utils = require 'user.utils'
local nmap = utils.nmap
require('yanky').setup {
  ring = {
    history_length = 100,
    storage = 'sqlite',
    sync_with_numbered_registers = true,
    cancel_event = 'update',
  },
}
vim.keymap.set({ 'n', 'x' }, 'p', '<Plug>(YankyPutAfter)')
vim.keymap.set({ 'n', 'x' }, 'P', '<Plug>(YankyPutBefore)')
-- keymap({ 'n', 'x' }, 'gp', '<Plug>(YankyGPutAfter)')
-- keymap({ 'n', 'x' }, 'gP', '<Plug>(YankyGPutBefore)')
nmap('<c-n>', '<Plug>(YankyCycleForward)')
nmap('<c-m>', '<Plug>(YankyCycleBackward)')
