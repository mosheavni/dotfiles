local utils = require 'user.utils'
local nnoremap = utils.nnoremap
local tnoremap = utils.tnoremap

local M = {
  -------------------------
  -- Functionality Tools --
  -------------------------
  {
    'monkoose/matchparen.nvim',
    keys = { '%' },
    config = true,
  },
  -- {
  --   'utilyre/sentiment.nvim',
  --   version = '*',
  --   event = 'VeryLazy', -- keep for lazy loading
  --   config = function()
  --     vim.cmd [[hi! link MatchParen TabLineSel]]
  --     require('sentiment').setup {
  --       excluded_filetypes = { 'fugitive' },
  --     }
  --   end,
  -- },
  {
    'kiran94/s3edit.nvim',
    cmd = 'S3Edit',
    config = true,
  },
  {
    'voldikss/vim-floaterm',
    keys = { 'F6', 'F7', 'F8' },
    cmd = {
      'FloatermFirst',
      'FloatermHide',
      'FloatermKill',
      'FloatermLast',
      'FloatermNew',
      'FloatermNext',
      'FloatermPrev',
      'FloatermSend',
      'FloatermShow',
      'FloatermToggle',
      'FloatermUpdate',
    },
    init = function()
      nnoremap('<F6>', '<Cmd>FloatermToggle<CR>', true)
      nnoremap('<F7>', '<Cmd>FloatermNew<CR>', true)
      nnoremap('<F8>', '<Cmd>FloatermNext<CR>', true)
      vim.g['floaterm_height'] = 0.9
      vim.g['floaterm_keymap_new'] = '<F7>'
      vim.g['floaterm_keymap_next'] = '<F8>'
      vim.g['floaterm_keymap_toggle'] = '<F6>'
      vim.g['floaterm_width'] = 0.7
    end,
  },
  -- {
  --   'samjwill/nvim-unception',
  --   event = 'VeryLazy',
  -- },
  {
    'mosheavni/vim-dirdiff',
    cmd = { 'DirDiff' },
  },
  {
    'simeji/winresizer',
    keys = { '<C-e>' },
    config = function()
      vim.g.winresizer_vert_resize = 4
      vim.g.winresizer_start_key = '<C-e>'
      tnoremap('<C-e>', '<Esc><Cmd>WinResizerStartResize<CR>', true)
    end,
  },
  {
    'pechorin/any-jump.vim',
    cmd = { 'AnyJump', 'AnyJumpVisual' },
    keys = { '<leader>j', '<cmd>AnyJump<CR>' },
  },
  {
    'kazhala/close-buffers.nvim',
    config = true,
    cmd = { 'BDelete', 'BWipeout' },
  },
  {
    'iamcco/markdown-preview.nvim',
    build = 'cd app && yarn install',
    config = function()
      vim.g.mkdp_filetypes = { 'markdown' }
    end,
    cmd = 'MarkdownPreview',
    ft = 'markdown',
  },
  {
    'max397574/better-escape.nvim',
    opts = {
      mapping = { 'jk' },
    },
    event = 'InsertEnter',
  },
  {
    'AndrewRadev/linediff.vim',
    cmd = { 'Linediff' },
  },
  {
    'ellisonleao/carbon-now.nvim',
    lazy = true,
    cmd = 'CarbonNow',
    opts = { open_cmd = 'open' },
  },
  {
    'stevearc/oil.nvim',
    opts = {},
    cmd = { 'Oil' },
  },
  {
    'rest-nvim/rest.nvim',
    keys = { { '<leader>cr', '<Plug>RestNvim' } },
    opts = {},
  },
}

return M
