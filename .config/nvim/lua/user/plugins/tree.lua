local status_ok, nvim_tree = pcall(require, 'nvim-tree')
if not status_ok then
  return vim.notify 'Module nvim_tree not installed'
end

local utils = require 'user.utils'
local opts = utils.map_opts
local keymap = utils.keymap

nvim_tree.setup {
  actions = {
    open_file = {
      resize_window = true,
    },
  },
  disable_netrw = false,
  git = {
    enable = false,
    ignore = true,
  },
  hijack_cursor = true,
  select_prompts = true,
  hijack_netrw = true,
  hijack_unnamed_buffer_when_opening = false,
  open_on_tab = false,
  reload_on_bufenter = false,
  sync_root_with_cwd = true,
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
  filters = {
    dotfiles = false,
    custom = { '\\^.git' },
  },
}

keymap('n', '<c-o>', '<cmd>NvimTreeToggle<cr>', opts.no_remap)
keymap('n', '<leader>v', '<cmd>NvimTreeFindFile<cr>', opts.no_remap)
