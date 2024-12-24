local leet_arg = 'leetcode.nvim'
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
    'chomosuke/term-edit.nvim',
    event = 'TermOpen',
    opts = {
      prompt_end = '%$ ',
    },
    version = '1.*',
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
  {
    'stevearc/oil.nvim',
    cmd = { 'Oil' },
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {},
  },
  {
    'kawre/leetcode.nvim',
    build = ':TSUpdate html',
    lazy = leet_arg ~= vim.fn.argv(0, -1),

    dependencies = {
      'ibhagwan/fzf-lua',
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
    },
    opts = {
      lang = 'python3',
      arg = leet_arg,
      hooks = {
        enter = function()
          vim.keymap.set('n', '<leader>l', '<cmd>Leet<cr>')
          vim.keymap.set('n', '<leader>lr', function()
            vim.ui.select({ 'easy', 'medium', 'hard' }, { prompt = 'Choose difficulty for a random leet: ' }, function(level)
              vim.cmd('Leet random difficulty=' .. level)
            end)
          end, { remap = false })
          require('lazy').load { plugins = { 'copilot.lua' } }
        end,
        ['question_enter'] = function()
          vim.keymap.set('n', '<c-cr>', '<cmd>Leet run<CR>', { buffer = true })
          require('copilot.command').disable()
        end,
      },
    },
  },
}

return M
