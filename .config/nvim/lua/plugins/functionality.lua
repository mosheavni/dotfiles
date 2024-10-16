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
    'gbprod/substitute.nvim',
    keys = {
      { '<leader>p' },
      { '<leader>P' },
    },
    dependencies = 'yanky.nvim',
    config = function()
      require('substitute').setup {
        on_substitute = require('yanky.integration').substitute(),
      }
      -- Lua
      vim.keymap.set('n', '<leader>p', require('substitute').operator, { noremap = true })
      vim.keymap.set('n', '<leader>P', require('substitute').line, { noremap = true })
      -- vim.keymap.set('n', 'S', require('substitute').eol, { noremap = true })
      vim.keymap.set('x', '<leader>p', require('substitute').visual, { noremap = true })
    end,
  },
  {
    'mosheavni/vim-kubernetes',
    ft = 'yaml',
    config = function()
      require('user.menu').add_actions('Kubernetes', {
        ['Apply (:KubeApply)'] = function()
          vim.cmd [[KubeApply]]
        end,
        ['Apply Directory (:KubeApplyDir)'] = function()
          vim.cmd [[KubeApplyDir]]
        end,
        ['Create (:KubeCreate)'] = function()
          vim.cmd [[KubeCreate]]
        end,
        ['Decode Secret (:KubeDecodeSecret)'] = function()
          vim.cmd [[KubeDecodeSecret]]
        end,
        ['Delete (:KubeDelete)'] = function()
          vim.cmd [[KubeDelete]]
        end,
        ['Delete Dir (:KubeDeleteDir)'] = function()
          vim.cmd [[KubeDeleteDir]]
        end,
        ['Encode Secret (:KubeEncodeSecret)'] = function()
          vim.cmd [[KubeEncodeSecret]]
        end,
        ['Recreate (:KubeRecreate)'] = function()
          vim.cmd [[KubeRecreate]]
        end,
      })
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
    'chomosuke/term-edit.nvim',
    ft = 'floaterm',
    opts = {
      prompt_end = '%$ ',
    },
    version = '1.*',
  },
  { 'echasnovski/mini.splitjoin', version = false, opts = {}, keys = { 'gS' } },
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
    opts = {},
    cmd = { 'BDelete', 'BWipeout' },
    keys = {
      { '<leader>bd', '<cmd>BDelete this<cr>' },
      { '<leader>bh', '<cmd>BDelete hidden<cr>' },
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
    'desdic/greyjoy.nvim',
    cmd = { 'Greyjoy' },
    init = function()
      require('user.menu').add_actions('Greyjoy', {
        ['Run command (:Greyjoy)'] = function()
          vim.cmd.Greyjoy()
        end,
      })
    end,
    config = function(_, opts)
      local greyjoy = require 'greyjoy'
      greyjoy.setup(opts)
      greyjoy.load_extension 'generic'
      greyjoy.load_extension 'makefile'
      greyjoy.load_extension 'docker_compose'
    end,
    opts = {
      extensions = {
        generic = {
          commands = {
            ['run python {filename}'] = {
              command = { 'python3', '{filename}' },
              filetype = 'python',
            },
            ['run go {filename}'] = {
              command = { 'go', 'run', '{filename}' },
              filetype = 'go',
            },
          },
        },
      },
    },
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
    'AndrewRadev/linediff.vim',
    cmd = { 'Linediff' },
  },
  {
    'ellisonleao/carbon-now.nvim',
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
}

return M
