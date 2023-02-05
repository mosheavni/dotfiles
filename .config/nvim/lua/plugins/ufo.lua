local M = {
  'kevinhwang91/nvim-ufo',
  dependencies = { 'kevinhwang91/promise-async' },
  event = 'BufReadPost',

  opts = {},

  init = function()
    vim.o.foldcolumn = '1' -- '0' is not bad
    vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true
    vim.keymap.set('n', '<leader>fo', function()
      require('ufo').openAllFolds()
    end)
    vim.keymap.set('n', '<leader>fc', function()
      require('ufo').closeAllFolds()
    end)
  end,
}

return M
