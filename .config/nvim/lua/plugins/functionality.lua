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
          vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<C-e>', true, true, true))
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
    'rest-nvim/rest.nvim',
    keys = { '<Plug>RestNvim', { '<leader>cr', '<Plug>RestNvim' } },
    opts = {},
    init = function()
      require('user.menu').add_actions('REST', {
        ['Send request (<leader>cr)'] = function()
          vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<Plug>RestNvim', true, true, true))
        end,
        ['Open a buffer with a template'] = function()
          _G.tmp_write { should_delete = false, ft = 'http', new = true, vertical = true }
          vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            'POST https://reqres.in/api/v1/users',
            'Content-Type: application/json',
            '',
            '# --silent',
            '# --insecure',
            '',
            '{',
            '  "name": "John Doe",',
            '  "email": "john.doe@gmail.com',
            '}',
          })
          vim.cmd.write()
          P 'Invoke with <leader>cr'
        end,
      })
    end,
  },
}

return M
