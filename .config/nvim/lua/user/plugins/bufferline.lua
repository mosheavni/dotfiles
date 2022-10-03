local utils = require 'user.utils'
local keymap = utils.keymap

----------------
-- Bufferline --
----------------
local status_ok_bufferline, bufferline = pcall(require, 'bufferline')
if not status_ok_bufferline then
  return
end
bufferline.setup {
  options = {
    numbers = 'ordinal',
    diagnostics = 'nvim_lsp',
    separator_style = 'thin',
    show_tab_indicators = true,
    show_buffer_close_icons = true,
    show_close_icon = true,
  },
}
keymap('n', '<leader>1', '<cmd>BufferLineGoToBuffer 1<cr>')
keymap('n', '<leader>2', '<cmd>BufferLineGoToBuffer 2<cr>')
keymap('n', '<leader>3', '<cmd>BufferLineGoToBuffer 3<cr>')
keymap('n', '<leader>4', '<cmd>BufferLineGoToBuffer 4<cr>')
keymap('n', '<leader>5', '<cmd>BufferLineGoToBuffer 5<cr>')
keymap('n', '<leader>5', '<cmd>BufferLineGoToBuffer 5<cr>')
keymap('n', '<leader>6', '<cmd>BufferLineGoToBuffer 5<cr>')
keymap('n', '<leader>7', '<cmd>BufferLineGoToBuffer 5<cr>')
keymap('n', '<leader>8', '<cmd>BufferLineGoToBuffer 5<cr>')
keymap('n', '<leader>9', '<cmd>BufferLineGoToBuffer 5<cr>')
keymap('n', '<leader>10', '<cmd>BufferLineGoToBuffer 5<cr>')
