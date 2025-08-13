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
    'mosheavni/vim-dirdiff', -- todo convert to difftool
    cmd = { 'DirDiff' },
    init = function()
      require('user.menu').add_actions('Diff', {
        ['Between 2 directories'] = function()
          local pretty_print = require('user.utils').pretty_print
          vim.defer_fn(function()
            vim.ui.input({ prompt = 'Directory A❯ ' }, function(a)
              if not a or a == '' then
                pretty_print 'Canceled.'
                return
              end
              vim.defer_fn(function()
                vim.ui.input({ prompt = 'Directory B❯ ' }, function(b)
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
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    opts = {},
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
    keys = {
      { '<c-e>', "<cmd>lua require('oil').open_float()<cr>" },
    },
    opts = {
      -- Configuration for the floating window in oil.open_float
      float = {
        -- optionally override the oil buffers window title with custom function: fun(winid: integer): string
        get_win_title = nil,
        -- preview_split: Split direction: "auto", "left", "right", "above", "below".
        -- max_width and max_height can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
        max_width = 0.6,
        max_height = 0.7,
        preview_split = 'right',
        -- This is the config that will be passed to nvim_open_win.
        -- Change values here to customize the layout
        override = function(conf)
          return conf
        end,
      },
      view_options = {
        -- Show files and directories that start with "."
        show_hidden = true,
      },
    },
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
            vim.ui.select({ 'easy', 'medium', 'hard' }, { prompt = 'Choose difficulty for a random leet❯ ' }, function(level)
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
  {
    'jiaoshijie/undotree',
    dependencies = 'nvim-lua/plenary.nvim',
    opts = {},
    keys = { -- load the plugin only when using it's keybinding:
      { '<leader>u', "<cmd>lua require('undotree').toggle()<cr>" },
    },
  },
  {
    'mrjones2014/smart-splits.nvim',
    config = function()
      require('smart-splits').setup()
      vim.keymap.set('n', '<A-h>', require('smart-splits').resize_left)
      vim.keymap.set('n', '<A-j>', require('smart-splits').resize_down)
      vim.keymap.set('n', '<A-k>', require('smart-splits').resize_up)
      vim.keymap.set('n', '<A-l>', require('smart-splits').resize_right)
      -- moving between splits
      vim.keymap.set('n', '<C-h>', require('smart-splits').move_cursor_left)
      vim.keymap.set('n', '<C-j>', require('smart-splits').move_cursor_down)
      vim.keymap.set('n', '<C-k>', require('smart-splits').move_cursor_up)
      vim.keymap.set('n', '<C-l>', require('smart-splits').move_cursor_right)
    end,
  },
  {
    'nvzone/typr',
    dependencies = 'nvzone/volt',
    opts = {},
    cmd = { 'Typr', 'TyprStats' },
  },
}

return M
