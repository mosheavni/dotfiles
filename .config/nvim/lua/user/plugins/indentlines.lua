----------------------
-- indent_blankline --
----------------------
-- vim.cmd [[highlight IndentBlanklineIndent1 guifg=#C678DD gui=nocombine]]
-- vim.cmd [[highlight IndentBlanklineIndent2 guifg=#E06C75 gui=nocombine]]
-- vim.cmd [[highlight IndentBlanklineIndent3 guifg=#E5C07B gui=nocombine]]
-- vim.cmd [[highlight IndentBlanklineIndent4 guifg=#98C379 gui=nocombine]]
-- vim.cmd [[highlight IndentBlanklineIndent5 guifg=#56B6C2 gui=nocombine]]
-- vim.cmd [[highlight IndentBlanklineIndent6 guifg=#61AFEF gui=nocombine]]

local status_ok_indent_blankline, indent_blankline = pcall(require, 'indent_blankline')
if not status_ok_indent_blankline then
  return
end
indent_blankline.setup {
  char = '┊',
  filetype_exclude = {
    'NvimTree',
    'TelescopePrompt',
    'TelescopeResults',
    'alpha',
    'help',
    'lspinfo',
    'mason.nvim',
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
}
