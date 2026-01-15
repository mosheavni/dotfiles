local leet_arg = 'leetcode.nvim'
local M = {
  -------------------------
  -- Functionality Tools --
  -------------------------
  {
    'nvim-lua/plenary.nvim',
    cmd = {
      'PlenaryBustedFile',
      'PlenaryBustedDirectory',
    },
  },
  {
    'chr4/nginx.vim',
    ft = 'nginx',
  },
  {
    'yorickpeterse/nvim-pqf',
    opts = {},
    event = 'QuickFixCmdPre',
    -- ft = 'qf',
  },
  {
    'tommcdo/vim-lister',
    ft = 'qf',
    cmd = { 'Qfilter', 'Qgrep' },
  },
  {
    'kevinhwang91/nvim-bqf',
    ft = 'qf',
  },
  {
    'junegunn/vim-easy-align',
    keys = { { 'ga', '<Plug>(EasyAlign)', desc = 'Align by motion', mode = { 'v', 'n' } } },
  },
  {
    'AndrewRadev/switch.vim',
    keys = {
      { 'gs', nil, { 'n', 'v' }, desc = 'Switch' },
    },
    config = function()
      local fk = [=[\<\(\l\)\(\l\+\(\u\l\+\)\+\)\>]=]
      local sk = [=[\<\(\u\l\+\)\(\u\l\+\)\+\>]=]
      local tk = [=[\<\(\l\+\)\(_\l\+\)\+\>]=]
      local fok = [=[\<\(\u\+\)\(_\u\+\)\+\>]=]
      local folk = [=[\<\(\l\+\)\(\-\l\+\)\+\>]=]
      local fik = [=[\<\(\l\+\)\(\.\l\+\)\+\>]=]
      vim.g['switch_custom_definitions'] = {
        vim.fn['switch#NormalizedCaseWords'] { 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday' },
        vim.fn['switch#NormalizedCase'] { 'yes', 'no' },
        vim.fn['switch#NormalizedCase'] { 'on', 'off' },
        vim.fn['switch#NormalizedCase'] { 'left', 'right' },
        vim.fn['switch#NormalizedCase'] { 'up', 'down' },
        vim.fn['switch#NormalizedCase'] { 'enable', 'disable' },
        vim.fn['switch#NormalizedCase'] { 'Always', 'Never' },
        vim.fn['switch#NormalizedCase'] { 'debug', 'info', 'warning', 'error', 'critical' },
        { '==', '!=', '~=' },
        {
          [fk] = [=[\=toupper(submatch(1)) . submatch(2)]=],
          [sk] = [=[\=tolower(substitute(submatch(0), '\(\l\)\(\u\)', '\1_\2', 'g'))]=],
          [tk] = [=[\U\0]=],
          [fok] = [=[\=tolower(substitute(submatch(0), '_', '-', 'g'))]=],
          [folk] = [=[\=substitute(submatch(0), '-', '.', 'g')]=],
          [fik] = [=[\=substitute(submatch(0), '\.\(\l\)', '\u\1', 'g')]=],
        },
      }
    end,
    init = function()
      local custom_switches = vim.api.nvim_create_augroup('CustomSwitches', { clear = true })
      vim.api.nvim_create_autocmd('FileType', {
        group = custom_switches,
        pattern = { 'gitrebase' },
        callback = function()
          vim.b['switch_custom_definitions'] = {
            { 'pick', 'reword', 'edit', 'squash', 'fixup', 'exec', 'drop' },
          }
        end,
      })
      -- (un)check markdown buxes
      vim.api.nvim_create_autocmd('FileType', {
        group = custom_switches,
        pattern = { 'markdown' },
        callback = function()
          local fk = [=[\v^(\s*[*+-] )?\[ \]]=]
          local sk = [=[\v^(\s*[*+-] )?\[x\]]=]
          local tk = [=[\v^(\s*[*+-] )?\[-\]]=]
          local fok = [=[\v^(\s*\d+\. )?\[ \]]=]
          local fik = [=[\v^(\s*\d+\. )?\[x\]]=]
          local sik = [=[\v^(\s*\d+\. )?\[-\]]=]
          vim.b['switch_custom_definitions'] = {
            {
              [fk] = [=[\1[x]]=],
              [sk] = [=[\1[-]]=],
              [tk] = [=[\1[ ]]=],
            },
            {
              [fok] = [=[\1[x]]=],
              [fik] = [=[\1[-]]=],
              [sik] = [=[\1[ ]]=],
            },
          }
        end,
      })
    end,
  },
  {
    'axelvc/template-string.nvim',
    ft = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact', 'python' },
    opts = {},
  },
  {
    'machakann/vim-swap',
    keys = {
      { '<leader>sw', '<Plug>(swap-interactive)', mode = { 'n', 'v' }, desc = 'Swap function arguments interactively' },
    },
    init = function()
      vim.g.swap_no_default_key_mappings = true
    end,
  },
  {
    'andymass/vim-matchup',
    event = 'BufReadPost',
    init = function()
      -- `matchparen.vim` needs to be disabled manually in case of lazy loading
      vim.g.loaded_matchparen = 1
      vim.g.matchup_matchparen_offscreen = { method = 'status_manual' }
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
    'mosheavni/github-pr-reviewer.nvim',
    dev = vim.env.PR_REVIEW_DEV == 'true',
    opts = {
      -- Key to mark file as viewed and go to next file (only works in review mode)
      mark_as_viewed_key = '<CR>',

      -- Key to toggle between unified and split diff view (only works in review mode)
      diff_view_toggle_key = '<C-v>',

      -- Key to toggle floating windows visibility (only works in review mode)
      toggle_floats_key = '<C-r>',

      -- Key to jump to next hunk (only works in review mode)
      next_hunk_key = ']c',

      -- Key to jump to previous hunk (only works in review mode)
      prev_hunk_key = '[c',

      -- Key to go to next modified file (only works in review mode)
      next_file_key = ']q',

      -- Key to go to previous modified file (only works in review mode)
      prev_file_key = '[q',
    },
    keys = {
      { '<leader>pr', '<cmd>PRReviewMenu<cr>', desc = 'PR Review Menu' },
      {
        '<leader>pr',
        ":<C-u>'<,'>PRSuggestChange<CR>",
        desc = 'Suggest change',
        mode = 'v',
      },
    },
  },
  {
    'gbprod/yanky.nvim',
    dependencies = { 'kkharji/sqlite.lua' },
    cmd = { 'YankyRingHistory' },
    keys = {
      { 'yy', desc = 'Yank' },
      { 'p', '<Plug>(YankyPutAfter)', desc = 'Paste yank after', mode = { 'n', 'x' } },
      { 'P', '<Plug>(YankyPutBefore)', desc = 'Paste yank before', mode = { 'n', 'x' } },
      { '<c-n>', '<Plug>(YankyCycleForward)', desc = 'Cycle yank forward' },
      { '<c-m>', '<Plug>(YankyCycleBackward)', desc = 'Cycle yank backward' },
      { '<leader>y', '<Cmd>YankyRingHistory<cr>', desc = 'Yank history' },
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
    'mrjones2014/smart-splits.nvim',
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('smart-splits').setup {}
      vim.keymap.set('n', '<A-h>', require('smart-splits').resize_left, { desc = 'Resize split left' })
      vim.keymap.set('n', '<A-j>', require('smart-splits').resize_down, { desc = 'Resize split down' })
      vim.keymap.set('n', '<A-k>', require('smart-splits').resize_up, { desc = 'Resize split up' })
      vim.keymap.set('n', '<A-l>', require('smart-splits').resize_right, { desc = 'Resize split right' })
      -- moving between splits
      vim.keymap.set('n', '<C-h>', require('smart-splits').move_cursor_left, { desc = 'Move to left split' })
      vim.keymap.set('n', '<C-j>', require('smart-splits').move_cursor_down, { desc = 'Move to split below' })
      vim.keymap.set('n', '<C-k>', require('smart-splits').move_cursor_up, { desc = 'Move to split above' })
      vim.keymap.set('n', '<C-l>', require('smart-splits').move_cursor_right, { desc = 'Move to right split' })
    end,
  },
}

return M
