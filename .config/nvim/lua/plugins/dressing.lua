local M = {
  'stevearc/dressing.nvim',
  config = function()
    require('dressing').setup {
      input = {
        enabled = true,
        relative = 'editor',
        trim_prompt = false,
        insert_only = true,
        start_in_insert = true,
      },
    }
    vim.cmd [[hi link FloatTitle Normal]]
  end,
  event = 'VeryLazy',
}
return M
