local status_ok, telescope = pcall(require, 'telescope')
if not status_ok then
  return
end

local actions = require 'telescope.actions'
local utils = require 'user.utils'
local opts = utils.map_opts
local keymap = utils.keymap

telescope.setup {
  defaults = {
    mappings = {
      i = {
        ['<esc>'] = actions.close,
      },
    },
  },
  pickers = {
    find_files = {
      find_command = {
        'rg',
        '--color=never',
        '--no-heading',
        '--with-filename',
        '--line-number',
        '--files',
        '--trim',
        '--column',
        '--hidden',
        '--smart-case',
        '-g',
        '!.git/',
      },
    },
  },
}

telescope.load_extension 'fzf'
telescope.load_extension 'project'

-- Keymaps
keymap('n', '<c-p>', [[:Telescope find_files<cr>]], opts.no_remap)
keymap('n', '<c-b>', '<cmd>Telescope buffers<cr>', opts.no_remap)
keymap('n', '<F4>', '<cmd>lua require("user.git-branches").open()<cr>', opts.no_remap)
keymap('n', '<leader>hh', '<cmd>Telescope help_tags<cr>', opts.no_remap)
keymap('n', '<leader>/', function()
  -- You can pass additional configuration to telescope to change theme, layout, etc.
  local view = require('telescope.themes').get_dropdown { winblend = 10, previewer = false }
  view = vim.tbl_extend('force', view, {
    additional_args = function()
      return {
        '--hidden',
        '--glob',
        '!.git',
      }
    end,
  })
  require('telescope.builtin').live_grep(view)
end, { desc = '[/] Fuzzily search in current buffer]' })
