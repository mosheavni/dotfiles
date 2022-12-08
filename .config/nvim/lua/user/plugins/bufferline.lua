local utils = require 'user.utils'
local nnoremap = utils.nnoremap

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
nnoremap('<leader>1', '<cmd>BufferLineGoToBuffer 1<cr>')
nnoremap('<leader>2', '<cmd>BufferLineGoToBuffer 2<cr>')
nnoremap('<leader>3', '<cmd>BufferLineGoToBuffer 3<cr>')
nnoremap('<leader>4', '<cmd>BufferLineGoToBuffer 4<cr>')
nnoremap('<leader>5', '<cmd>BufferLineGoToBuffer 5<cr>')
nnoremap('<leader>5', '<cmd>BufferLineGoToBuffer 5<cr>')
nnoremap('<leader>6', '<cmd>BufferLineGoToBuffer 6<cr>')
nnoremap('<leader>7', '<cmd>BufferLineGoToBuffer 7<cr>')
nnoremap('<leader>8', '<cmd>BufferLineGoToBuffer 8<cr>')
nnoremap('<leader>9', '<cmd>BufferLineGoToBuffer 9<cr>')
