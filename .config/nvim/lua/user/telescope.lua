local status_ok, telescope = pcall(require, 'telescope')
if not status_ok then
  return
end

local actions = require 'telescope.actions'

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
