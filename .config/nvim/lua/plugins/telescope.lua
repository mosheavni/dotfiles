local M = {
  'nvim-telescope/telescope.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
  },
  cmd = 'Telescope',
  keys = { '<c-p>', '<c-b>', '<F4>', '<leader>hh', '<leader>/', '<leader>fp' },
}

M.config = function()
  local telescope = require 'telescope'
  local actions = require 'telescope.actions'
  local action_layout = require 'telescope.actions.layout'
  local utils = require 'user.utils'
  local nnoremap = utils.nmap

  telescope.setup {
    defaults = {
      prompt_prefix = ' ',
      selection_caret = ' ',
      mappings = {
        i = {
          ['<esc>'] = actions.close,
          ['<M-p>'] = action_layout.toggle_preview,
        },
        n = {
          ['<esc>'] = actions.close,
          ['<M-p>'] = action_layout.toggle_preview,
        },
      },
    },
    pickers = {
      buffers = {
        sort_lastused = true,
        theme = 'dropdown',
        previewer = true,
        mappings = {
          i = {
            ['<c-d>'] = actions.delete_buffer,
          },
          n = {
            ['<c-d>'] = actions.delete_buffer,
          },
        },
      },
      oldfiles = {
        only_cwd = true,
      },
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
  nnoremap('<leader>i', function()
    require('telescope.builtin').oldfiles()
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
end

return M
