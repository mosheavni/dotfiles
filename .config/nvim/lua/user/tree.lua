local status_ok, nvim_tree = pcall(require, 'nvim-tree')
if not status_ok then
  return vim.notify 'Module nvim_tree not installed'
end

local utils = require 'user.utils'
local opts = utils.map_opts
local keymap = utils.keymap

nvim_tree.setup {
  disable_netrw = false,
  hijack_netrw = true,
  open_on_tab = false,
  hijack_cursor = true,
  hijack_unnamed_buffer_when_opening = false,
  update_cwd = true,
  reload_on_bufenter = false,
  update_focused_file = {
    enable = true,
    update_cwd = false,
  },
  view = {
    side = 'left',
    width = 25,
    hide_root_folder = false,
    mappings = {
      custom_only = false,
      list = {
        { key = 'x', action = 'close_node' },
        { key = 's', action = 'vsplit' },
        { key = 'i', action = 'split' },
        { key = '<C-e>', action = '' },
        { key = 'cd', action = 'cd' },
      },
    },
  },
  git = {
    enable = true,
    ignore = true,
  },
  actions = {
    open_file = {
      resize_window = true,
    },
  },
  filters = {
    dotfiles = false,
  },
  -- renderer = {
  --   highlight_git = false,
  --   highlight_opened_files = 'none',
  --
  --   indent_markers = {
  --     enable = false,
  --   },
  --   icons = {
  --     padding = ' ',
  --     symlink_arrow = ' ➛ ',
  --     show = {
  --       file = true,
  --       folder = true,
  --       folder_arrow = true,
  --       git = false,
  --     },
  --     glyphs = {
  --       default = '',
  --       symlink = '',
  --       folder = {
  --         default = '',
  --         empty = '',
  --         empty_open = '',
  --         open = '',
  --         symlink = '',
  --         symlink_open = '',
  --         arrow_open = '',
  --         arrow_closed = '',
  --       },
  --       git = {
  --         unstaged = '✗',
  --         staged = '✓',
  --         unmerged = '',
  --         renamed = '➜',
  --         untracked = '★',
  --         deleted = '',
  --         ignored = '◌',
  --       },
  --     },
  --   },
  -- },
}

keymap('n', '<c-o>', '<cmd>NvimTreeToggle<cr>', opts.no_remap)
keymap('n', '<leader>v', '<cmd>NvimTreeFindFile<cr>', opts.no_remap)
