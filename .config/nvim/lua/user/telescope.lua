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
  extensions = {
    project = {
      base_dirs = {
        '~/Repos',
      },
      hidden_files = true,
      theme = 'dropdown',
    },
  },
}

telescope.load_extension 'fzf'
telescope.load_extension 'project'

-- Keymaps
keymap('n', '<c-p>', [[(expand('%') =~ 'NERD_tree' ? "\<c-w>\<c-w>" : '').":Telescope find_files\<cr>"]], opts.no_remap_expr_silent)
keymap('n', '<c-b>', '<cmd>Telescope buffers<cr>', opts.no_remap)
keymap('n', '<F4>', '<cmd>lua require("user.git-branches").open()<cr>', opts.no_remap)
keymap('n', '<leader>hh', '<cmd>Telescope help_tags<cr>', opts.no_remap)
