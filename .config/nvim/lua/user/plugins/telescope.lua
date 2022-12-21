local status_ok, telescope = pcall(require, 'telescope')
if not status_ok then
  return
end

local actions = require 'telescope.actions'
local utils = require 'user.utils'
local nmap = utils.nmap
local nnoremap = utils.nmap

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
-- Projections
require('projections').setup {
  workspaces = { -- Default workspaces to search for
    -- "~/dev",                               dev is a workspace. default patterns is used (specified below)
    -- { "~/Documents/dev", { ".git" } },     Documents/dev is a workspace. patterns = { ".git" }
    { '~/Repos', {} }, --                    An empty pattern list indicates that all subfolders are considered projects
  },
}
-- Autostore session on DirChange and VimExit
local Session = require 'projections.session'
vim.api.nvim_create_autocmd({ 'DirChangedPre', 'VimLeavePre' }, {
  callback = function()
    Session.store(vim.loop.cwd())
  end,
})
vim.api.nvim_create_user_command('StoreProjectSession', function()
  Session.store(vim.loop.cwd())
end, {})

vim.api.nvim_create_user_command('RestoreProjectSession', function()
  Session.restore(vim.loop.cwd())
end, {})

-- Bind <leader>fp to Telescope projections
require('telescope').load_extension 'projections'
nmap('<leader>fp', function()
  vim.cmd 'Telescope projections'
end)

-- Keymaps
nnoremap('<c-p>', function()
  require('telescope.builtin').find_files()
end)
nnoremap('<c-b>', function()
  require('telescope.builtin').buffers()
end)
nnoremap('<F4>', function()
  require('user.git-branches').open()
end)
nnoremap('<leader>hh', function()
  require('telescope.builtin').help_tags()
end)
nnoremap('<leader>/', function()
  -- You can pass additional configuration to telescope to change theme, layout, etc.
  local view = require('telescope.themes').get_dropdown { winblend = 10, previewer = false }

  local important_args = {
    additional_args = function()
      return {
        '--hidden',
        '--glob',
        '!.git',
      }
    end,
  }
  view = vim.tbl_extend('force', view, important_args)
  require('telescope.builtin').live_grep(important_args)
end, { desc = '[/] Fuzzily search in current buffer]' })
