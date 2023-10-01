return {
  'kevinhwang91/nvim-hlslens',
  keys = {
    { 'n', [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]] },
    { 'N', [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]] },
    { '*', [[*<Cmd>lua require('hlslens').start()<CR>]] },
    { '#', [[#<Cmd>lua require('hlslens').start()<CR>]] },
    { 'g*', [[g*<Cmd>lua require('hlslens').start()<CR>]] },
    { 'g#', [[g#<Cmd>lua require('hlslens').start()<CR>]] },
  },
  config = true,
}
