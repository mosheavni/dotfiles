return {
  'kevinhwang91/nvim-hlslens',
  keys = { '*', '#', 'n', 'N' },
  config = function()
    local nnoremap = require('user.utils').nnoremap
    require('hlslens').setup()
    nnoremap('n', [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]], true)
    nnoremap('N', [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]], true)
    nnoremap('*', [[*<Cmd>lua require('hlslens').start()<CR>]], true)
    nnoremap('#', [[#<Cmd>lua require('hlslens').start()<CR>]], true)
    nnoremap('g*', [[g*<Cmd>lua require('hlslens').start()<CR>]], true)
    nnoremap('g#', [[g#<Cmd>lua require('hlslens').start()<CR>]], true)
  end,
}
