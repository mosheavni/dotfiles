local M = {
  'kyazdani42/nvim-tree.lua',
  cmd = 'NvimTreeToggle',
  keys = { '<c-o>', '<leader>v' },
  dependencies = { 'kyazdani42/nvim-web-devicons' },
}

local function on_attach(bufnr)
  local api = require 'nvim-tree.api'

  local function opts(desc)
    return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  api.config.mappings.default_on_attach(bufnr)
  vim.keymap.set('n', 'x', api.node.navigate.parent_close, opts 'Close Directory')
  vim.keymap.set('n', 's', api.node.open.vertical, opts 'Open: Vertical Split')
  vim.keymap.set('n', 'i', api.node.open.horizontal, opts 'Open: Horizontal Split')
  vim.keymap.set('n', 'cd', api.tree.change_root_to_node, opts 'CD')
  vim.keymap.set('n', 'r', api.fs.rename, opts 'Rename')
  -- vim.keymap.set('n', 'r', api.fs.rename_node, opts 'Rename node')
  -- vim.keymap.set('n', 'r', api.fs.rename_basename, opts 'Rename basename')
  -- vim.keymap.set('n', 'r', api.fs.rename_sub, opts 'Rename sub')
  vim.keymap.del('n', '<C-e>', { buffer = bufnr })
end

M.config = function()
  local nvim_tree = require 'nvim-tree'
  local api = require 'nvim-tree.api'
  local utils = require 'user.utils'
  local nnoremap = utils.nnoremap

  nvim_tree.setup {
    on_attach = on_attach,
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
    },
    filters = {
      dotfiles = false,
      custom = { '\\^.git' },
    },
  }

  nnoremap('<leader>v', function()
    local api = require 'nvim-tree.api'
    api.tree.find_file { open = true, focus = true }
  end)
  nnoremap('<c-o>', function()
    api.tree.toggle()
  end)
end

return M
