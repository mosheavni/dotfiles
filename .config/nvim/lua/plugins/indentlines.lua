----------------------
-- indent_blankline --
----------------------
local M = {
  'lukas-reineke/indent-blankline.nvim',
  main = 'ibl',
  event = 'BufReadPre',
  opts = {
    char = '┊',
    filetype_exclude = {
      'NvimTree',
      'TelescopePrompt',
      'TelescopeResults',
      'alpha',
      'dashboard',
      'help',
      'lazy',
      'lspinfo',
      'mason',
      'noice',
      'nvchad_cheatsheet',
      'packer',
      'terminal',
      '',
    },
    buftype_exclude = { 'terminal' },
    show_trailing_blankline_indent = false,
    show_first_indent_level = false,
    show_current_context = true,
    show_current_context_start = true,
    space_char_blankline = ' ',
    -- char_highlight_list = {
    --   'IndentBlanklineIndent1',
    --   'IndentBlanklineIndent2',
    --   'IndentBlanklineIndent3',
    --   'IndentBlanklineIndent4',
    --   'IndentBlanklineIndent5',
    --   'IndentBlanklineIndent6',
    -- },
  },
}

return M
