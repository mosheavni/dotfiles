local pack = require 'user.pack.add'
pack.add {
  'https://github.com/mrjones2014/smart-splits.nvim',
  'https://github.com/kkharji/sqlite.lua',
  'https://github.com/yorickpeterse/nvim-pqf',
  'https://github.com/tommcdo/vim-lister',
  'https://github.com/kevinhwang91/nvim-bqf',
  'https://github.com/junegunn/vim-easy-align',
  'https://github.com/AndrewRadev/switch.vim',
  'https://github.com/axelvc/template-string.nvim',
  'https://github.com/machakann/vim-swap',
  'https://github.com/andymass/vim-matchup',
  'https://github.com/windwp/nvim-autopairs',
  'https://github.com/iamcco/markdown-preview.nvim',
  'https://github.com/AndrewRadev/linediff.vim',
  'https://github.com/chr4/nginx.vim',
  'https://github.com/mosheavni/github-pr-reviewer.nvim',
  'https://github.com/mosheavni/search-replace.nvim',
  'https://github.com/gbprod/yanky.nvim',
}

local M = {}

function M.eager()
  require('smart-splits').setup {}
  vim.keymap.set('n', '<A-h>', require('smart-splits').resize_left, { desc = 'Resize split left' })
  vim.keymap.set('n', '<A-j>', require('smart-splits').resize_down, { desc = 'Resize split down' })
  vim.keymap.set('n', '<A-k>', require('smart-splits').resize_up, { desc = 'Resize split up' })
  vim.keymap.set('n', '<A-l>', require('smart-splits').resize_right, { desc = 'Resize split right' })
  vim.keymap.set('n', '<C-h>', require('smart-splits').move_cursor_left, { desc = 'Move to left split' })
  vim.keymap.set('n', '<C-j>', require('smart-splits').move_cursor_down, { desc = 'Move to split below' })
  vim.keymap.set('n', '<C-k>', require('smart-splits').move_cursor_up, { desc = 'Move to split above' })
  vim.keymap.set('n', '<C-l>', require('smart-splits').move_cursor_right, { desc = 'Move to right split' })
end

function M.deferred()
  require('pqf').setup {}

  vim.g.swap_no_default_key_mappings = true
  vim.keymap.set({ 'n', 'v' }, '<leader>sw', '<Plug>(swap-interactive)', { desc = 'Swap function arguments interactively' })

  vim.g.loaded_matchparen = 1
  vim.g.matchup_matchparen_offscreen = { method = 'status_manual' }
  require('match-up').setup {}

  require('nvim-autopairs').setup {}

  vim.g.mkdp_filetypes = { 'markdown' }
  require('user.menu').add_actions('Markdown', {
    ['Preview in Browser'] = function()
      vim.cmd.MarkdownPreview()
    end,
  })

  require('github-pr-reviewer').setup {
    mark_as_viewed_key = '<CR>',
    diff_view_toggle_key = '<C-v>',
    toggle_floats_key = '<C-r>',
    next_hunk_key = ']c',
    prev_hunk_key = '[c',
    next_file_key = ']q',
    prev_file_key = '[q',
  }
  vim.keymap.set('n', '<leader>pr', '<cmd>PRReviewMenu<cr>', { desc = 'PR Review Menu' })
  vim.keymap.set('v', '<leader>pr', ":<C-u>'<,'>PRSuggestChange<CR>", { desc = 'Suggest change' })

  require('yanky').setup {
    ring = {
      history_length = 100,
      storage = 'sqlite',
      sync_with_numbered_registers = true,
      cancel_event = 'update',
    },
  }
  vim.keymap.set({ 'n', 'x' }, 'p', '<Plug>(YankyPutAfter)', { desc = 'Paste yank after' })
  vim.keymap.set({ 'n', 'x' }, 'P', '<Plug>(YankyPutBefore)', { desc = 'Paste yank before' })
  vim.keymap.set('n', '<c-n>', '<Plug>(YankyCycleForward)', { desc = 'Cycle yank forward' })
  vim.keymap.set('n', '<c-m>', '<Plug>(YankyCycleBackward)', { desc = 'Cycle yank backward' })
  vim.keymap.set('n', '<leader>y', '<Cmd>YankyRingHistory<cr>', { desc = 'Yank history' })
  require('user.menu').add_actions('Yanky', {
    ['Yank history'] = function()
      vim.cmd 'YankyRingHistory'
    end,
  })

  require('search-replace').setup()

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
  vim.api.nvim_create_autocmd('FileType', {
    group = custom_switches,
    pattern = { 'markdown' },
    callback = function()
      local mfk = [=[\v^(\s*[*+-] )?\[ \]]=]
      local msk = [=[\v^(\s*[*+-] )?\[x\]]=]
      local mtk = [=[\v^(\s*[*+-] )?\[-\]]=]
      local mfok = [=[\v^(\s*\d+\. )?\[ \]]=]
      local mfik = [=[\v^(\s*\d+\. )?\[x\]]=]
      local msik = [=[\v^(\s*\d+\. )?\[-\]]=]
      vim.b['switch_custom_definitions'] = {
        { [mfk] = [=[\1[x]]=], [msk] = [=[\1[-]]=], [mtk] = [=[\1[ ]]=] },
        { [mfok] = [=[\1[x]]=], [mfik] = [=[\1[-]]=], [msik] = [=[\1[ ]]=] },
      }
    end,
  })

  require('template-string').setup {}

  vim.keymap.set({ 'v', 'n' }, 'ga', '<Plug>(EasyAlign)', { desc = 'Align by motion' })
end

return M
