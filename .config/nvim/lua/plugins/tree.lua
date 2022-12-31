local M = {
  'kyazdani42/nvim-tree.lua',
  cmd = 'NvimTreeToggle',
  keys = { '<c-o>', '<leader>v' },
  dependencies = { 'kyazdani42/nvim-web-devicons' },
}

M.config = function()
  local nvim_tree = require 'nvim-tree'
  local api = require 'nvim-tree.api'
  local utils = require 'user.utils'
  local nnoremap = utils.nnoremap

  nvim_tree.setup {
    actions = {
      open_file = {
        resize_window = false,
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
          { key = 'r', action = 'full_rename' },
        },
      },
    },
    filters = {
      dotfiles = false,
      custom = { '\\^.git' },
    },
  }

  nnoremap('<leader>v', function()
    vim.cmd.NvimTreeFindFile()
  end)
  nnoremap('<c-o>', function()
    api.tree.toggle()
  end)
end

return M
