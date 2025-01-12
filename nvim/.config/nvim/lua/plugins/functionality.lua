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
    'mosheavni/vim-dirdiff',
    cmd = { 'DirDiff' },
    init = function()
      require('user.menu').add_actions('Diff', {
        ['Between 2 directories'] = function()
          local pretty_print = require('user.utils').pretty_print
          vim.defer_fn(function()
            vim.ui.input({ prompt = 'Directory A: ' }, function(a)
              if not a or a == '' then
                pretty_print 'Canceled.'
                return
              end
              vim.defer_fn(function()
                vim.ui.input({ prompt = 'Directory B: ' }, function(b)
                  if not b or b == '' then
                    pretty_print 'Canceled.'
                    return
                  end
                  vim.cmd('DirDiff ' .. a .. ' ' .. b)
                end)
              end, 100)
            end)
          end, 100)
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
    'gbprod/yanky.nvim',
    dependencies = { 'kkharji/sqlite.lua' },
    cmd = { 'YankyRingHistory' },
    keys = {
      'yy',
      { 'p', '<Plug>(YankyPutAfter)', mode = { 'n', 'x' } },
      { 'P', '<Plug>(YankyPutBefore)', mode = { 'n', 'x' } },
      { '<c-n>', '<Plug>(YankyCycleForward)' },
      { '<c-m>', '<Plug>(YankyCycleBackward)' },
      { '<leader>y', '<Cmd>YankyRingHistory<cr>' },
    },
    opts = {
      ring = {
        history_length = 100,
        storage = 'sqlite',
        sync_with_numbered_registers = true,
        cancel_event = 'update',
      },
    },
    init = function()
      require('user.menu').add_actions('Yanky', {
        ['Yank history'] = function()
          vim.cmd 'YankyRingHistory'
        end,
      })
    end,
  },
  {
    'AndrewRadev/linediff.vim',
    cmd = { 'Linediff' },
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
