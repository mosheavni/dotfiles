local M = {
  'kevinhwang91/nvim-ufo',
  dependencies = { 'kevinhwang91/promise-async' },
  event = 'BufReadPost',
  keys = {
    { '<leader>fo', '<cmd>lua require("ufo").openAllFolds()<cr>' },
    { '<leader>fc', '<cmd>lua require("ufo").closeAllFolds()<cr>' },
    { '<leader>fp', '<cmd>lua require("ufo").peekFoldedLinesUnderCursor()<cr>' },
  },
  opts = {
    open_fold_hl_timeout = 0,
  },

  init = function()
    ---@diagnostic disable-next-line: inject-field
    vim.o.foldcolumn = '1' -- '0' is not bad
    ---@diagnostic disable-next-line: inject-field
    vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
    ---@diagnostic disable-next-line: inject-field
    vim.o.foldlevelstart = 99
    ---@diagnostic disable-next-line: inject-field
    vim.o.foldenable = true
  end,
}

return M
