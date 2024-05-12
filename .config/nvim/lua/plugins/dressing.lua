local M = {
  'stevearc/dressing.nvim',
  lazy = true,
  opts = {
    input = {
      enabled = true,
      relative = 'editor',
      trim_prompt = false,
      insert_only = true,
      start_in_insert = true,
    },
  },
  config = function(_, opts)
    require('dressing').setup(opts)
    vim.cmd [[hi link FloatTitle Normal]]
  end,
  init = function()
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.ui.select = function(...)
      require('lazy').load { plugins = { 'dressing.nvim' } }
      return vim.ui.select(...)
    end
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.ui.input = function(...)
      require('lazy').load { plugins = { 'dressing.nvim' } }
      return vim.ui.input(...)
    end
  end,
}
return M
