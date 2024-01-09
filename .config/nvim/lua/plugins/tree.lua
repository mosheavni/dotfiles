local sort_current = 1
local SORT_METHODS = {
  'name',
  'case_sensitive',
  'modification_time',
  'extension',
}
local function on_attach(bufnr)
  local api = require 'nvim-tree.api'
  local cycle_sort = function()
    if sort_current >= #SORT_METHODS then
      sort_current = 1
    else
      sort_current = sort_current + 1
    end
    api.tree.reload()
    P('Sort Method: ' .. SORT_METHODS[sort_current])
  end

  local function opts(desc)
    return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  api.config.mappings.default_on_attach(bufnr)
  vim.keymap.set('n', 'x', api.node.navigate.parent_close, opts 'Close Directory')
  vim.keymap.set('n', 'v', api.node.open.vertical, opts 'Open: Vertical Split')
  vim.keymap.set('n', 'i', api.node.open.horizontal, opts 'Open: Horizontal Split')
  vim.keymap.set('n', 'cd', api.tree.change_root_to_node, opts 'CD')
  vim.keymap.set('n', 'T', cycle_sort, opts 'Cycle Sort')
  vim.keymap.del('n', 's', { buffer = bufnr })
  vim.keymap.del('n', '<C-e>', { buffer = bufnr })

  local function move_file_to()
    local node = api.tree.get_node_under_cursor()
    local file_src = node['absolute_path']
    ---@diagnostic disable-next-line: redundant-parameter
    local file_out = vim.fn.input('MOVE TO: ', file_src, 'file')
    local dir = vim.fn.fnamemodify(file_out, ':h')
    vim.system({ 'mkdir', '-p', dir }, { text = true }):wait()
    vim.system({ 'mv', file_src, file_out }, { text = true }):wait()
  end
  vim.keymap.set('n', 'r', move_file_to, opts 'Move File To')
end

local M = {
  'nvim-tree/nvim-tree.lua',
  cmd = 'NvimTreeToggle',
  keys = { '<c-o>', '<leader>v' },
  dependencies = { 'kyazdani42/nvim-web-devicons' },
}

M.config = function()
  local nvim_tree = require 'nvim-tree'
  local api = require 'nvim-tree.api'
  local utils = require 'user.utils'
  local nnoremap = utils.nnoremap
  -- vim.cmd [[
  --   highlight! NvimTreeOpenedFolderIcon ctermfg=109 guifg=#d8a657
  --   highlight! NvimTreeClosedFolderIcon ctermfg=109 guifg=#d8a657
  -- ]]

  local sort_by = function()
    return SORT_METHODS[sort_current]
  end

  nvim_tree.setup {
    on_attach = on_attach,
    sort = { sorter = sort_by },
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
      width = '20%',
    },
    filters = {
      dotfiles = false,
      custom = { '\\^.git' },
    },
  }

  api.events.subscribe(api.events.Event.FileCreated, function(file)
    vim.cmd('edit ' .. file.fname)
  end)

  nnoremap('<leader>v', function()
    api.tree.find_file { open = true, focus = true }
  end)
  nnoremap('<c-o>', function()
    api.tree.toggle()
  end)
end

return M
