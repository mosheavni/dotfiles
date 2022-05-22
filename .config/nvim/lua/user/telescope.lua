local status_ok, telescope = pcall(require, 'telescope')
if not status_ok then
  return
end

local actions = require 'telescope.actions'

telescope.setup {
  -- defaults = { sorting_strategy = "ascending" },
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
  project = {
    base_dirs = {
      { '~/Repos', max_depth = 2 },
    },
    hidden_files = true, -- default: false
    theme = 'dropdown',
  },
}

telescope.load_extension 'fzf'
telescope.load_extension 'project'
