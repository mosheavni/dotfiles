local M = {
  'stevearc/dressing.nvim',
  config = function()
    require('dressing').setup {
      input = {
        enabled = true,
        relative = 'editor',
      },
    }
    vim.cmd [[hi link FloatTitle Normal]]
  end,
  event = 'VeryLazy',
}
return M
