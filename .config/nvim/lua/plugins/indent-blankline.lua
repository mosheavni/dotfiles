----------------------
-- indent_blankline --
----------------------
local M = {
  'lukas-reineke/indent-blankline.nvim',
  main = 'ibl',
  event = 'BufReadPre',
  opts = {
    indent = {
      char = '┊',
    },
    exclude = {
      filetypes = {
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
      buftypes = { 'terminal' },
    },
  },
}

return M
