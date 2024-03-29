local utils = require 'user.utils'
local tnoremap = utils.tnoremap

local M = {
  -------------------------
  -- Functionality Tools --
  -------------------------
  {
    'andymass/vim-matchup',
    event = 'BufReadPost',
    init = function()
      -- `matchparen.vim` needs to be disabled manually in case of lazy loading
      vim.g.loaded_matchparen = 1
    end,
  },
  {
    'tpope/vim-speeddating',
    keys = { '<C-a>', '<C-x>' },
  },
  {
    'voldikss/vim-floaterm',
    keys = { '<F6>', '<F7>', '<F8>' },
    cmd = {
      'FloatermFirst',
      'FloatermHide',
      'FloatermKill',
      'FloatermLast',
      'FloatermNew',
      'FloatermNext',
      'FloatermPrev',
      'FloatermSend',
      'FloatermShow',
      'FloatermToggle',
      'FloatermUpdate',
    },
    init = function()
      vim.g['floaterm_height'] = 0.9
      vim.g['floaterm_keymap_new'] = '<F7>'
      vim.g['floaterm_keymap_next'] = '<F8>'
      vim.g['floaterm_keymap_toggle'] = '<F6>'
      vim.g['floaterm_width'] = 0.7
      require('user.menu').add_actions('Terminal', {
        ['Toggle (<F6>)'] = function()
          vim.cmd.FloatermToggle()
        end,
        ['Create a new window (<F7>)'] = function()
          vim.cmd.FloatermNew()
        end,
        ['Move to next window (<F8>)'] = function()
          vim.cmd.FloatermNext()
        end,
        ['Move to previous window'] = function()
          vim.cmd.FloatermPrev()
        end,
      })
    end,
  },
  {
    'danymat/neogen',
    dependencies = 'nvim-treesitter/nvim-treesitter',
    cmd = { 'Neogen' },
    opts = {
      snippet_engine = 'luasnip',
    },
    -- Uncomment next line if you want to follow only stable versions
    -- version = "*"
  },
  {
    'mosheavni/vim-dirdiff',
    cmd = { 'DirDiff' },
    init = function()
      require('user.menu').add_actions('Diff', {
        ['Between 2 directories'] = function()
          local pretty_print = require('user.utils').pretty_print
          vim.ui.input({ prompt = 'Directory A: ' }, function(a)
            if not a or a == '' then
              pretty_print 'Canceled.'
              return
            end
            vim.ui.input({ prompt = 'Directory B: ' }, function(b)
              if not b or b == '' then
                pretty_print 'Canceled.'
                return
              end
              vim.cmd('DirDiff ' .. a .. ' ' .. b)
            end)
          end)
        end,
      })
    end,
  },
  {
    'simeji/winresizer',
    keys = { '<C-e>' },
    config = function()
      vim.g.winresizer_vert_resize = 4
      vim.g.winresizer_start_key = '<C-e>'
      tnoremap('<C-e>', '<Cmd>WinResizerStartResize<CR>', true)
    end,
    init = function()
      require('user.menu').add_actions(nil, {
        ['Resize window (<C-e>)'] = function()
          vim.fn.feedkeys(vim.keycode '<C-e>')
        end,
      })
    end,
  },
  {
    'kazhala/close-buffers.nvim',
    config = true,
    cmd = { 'BDelete', 'BWipeout' },
    keys = {
      { '<leader>bd', '<cmd>BDelete this<cr>' },
    },
    init = function()
      require('user.menu').add_actions(nil, {
        ['Delete Buffer'] = function()
          vim.cmd.BDelete 'this'
        end,
        ['Delete all hidden buffers (:BDelete hidden)'] = function()
          vim.cmd.BDelete 'hidden'
        end,
      })
    end,
  },
  {
    'iamcco/markdown-preview.nvim',
    build = 'cd app && yarn install',
    config = function()
      vim.g.mkdp_filetypes = { 'markdown' }
    end,
    cmd = 'MarkdownPreview',
    ft = 'markdown',
    init = function()
      require('user.menu').add_actions('Markdown', {
        ['Preview in Browser'] = function()
          vim.cmd.MarkdownPreview()
        end,
      })
    end,
  },
  {
    'max397574/better-escape.nvim',
    opts = {
      mapping = { 'jk' },
    },
    event = 'InsertEnter',
  },
  {
    'AndrewRadev/linediff.vim',
    cmd = { 'Linediff' },
  },
  {
    'ellisonleao/carbon-now.nvim',
    lazy = true,
    cmd = 'CarbonNow',
    opts = { open_cmd = 'open' },
    init = function()
      require('user.menu').add_actions('Carbon', {
        ['Create a beautiful image of the code'] = function()
          vim.cmd.CarbonNow()
        end,
      })
    end,
  },
  {
    'backdround/global-note.nvim',
    cmd = 'GlobalNote',
    keys = { '<leader>n' },
    config = function()
      local global_note = require 'global-note'
      global_note.setup {
        additional_presets = {},
      }

      vim.keymap.set('n', '<leader>n', global_note.toggle_note, {
        desc = 'Toggle global note',
      })

      -- autocommand to run :MarkdownPreview when opening a global note
      -- in the path /Users/mavni/.local/share/nvim/global-note/global.md
      vim.api.nvim_create_autocmd('BufReadPost', {
        group = vim.api.nvim_create_augroup('GlobalNote', {}),
        pattern = '*/.local/share/nvim/global-note/global.md',
        command = 'MarkdownPreview',
      })
    end,
  },
}

return M
