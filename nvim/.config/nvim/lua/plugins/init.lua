---@class PluginSpec[]
--- Plugin specifications for Lazy.nvim plugin manager
--- This file contains the core plugin configurations for Neovim
local M = {
  {
    'nvim-lua/plenary.nvim',
    cmd = {
      'PlenaryBustedFile',
      'PlenaryBustedDirectory',
    },
    keys = {
      { '<leader>tf', '<cmd>PlenaryBustedFile %<CR>', mode = 'n' },
    },
  },
  {
    'milisims/nvim-luaref',
    ft = 'lua',
  },
  { 'Bilal2453/luvit-meta', lazy = true },
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
  }, -- Qfilter and Qgrep on Quickfix
  {
    'kevinhwang91/nvim-bqf',
    ft = 'qf',
  },
  {
    'junegunn/vim-easy-align',
    keys = { { 'ga', '<Plug>(EasyAlign)', mode = { 'v', 'n' } } },
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
      local custom_switches = require('user.utils').augroup 'CustomSwitches'
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
    event = 'InsertEnter',
    config = true,
  },
  {
    'kevinhwang91/nvim-hlslens',
    keys = {
      { 'n', [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>zzzv]] },
      { 'N', [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>zzzv]] },
      { '*', [[*<Cmd>lua require('hlslens').start()<CR>N]] },
      { '#', [[#<Cmd>lua require('hlslens').start()<CR>n]] },
      { 'g*', [[g*<Cmd>lua require('hlslens').start()<CR>]] },
      { 'g#', [[g#<Cmd>lua require('hlslens').start()<CR>]] },
    },
    event = 'CmdlineEnter',
    opts = {},
  },
  {
    'machakann/vim-swap',
    keys = {
      { '<leader>sw', '<Plug>(swap-interactive)', mode = { 'n', 'v' } },
    },
    init = function()
      vim.g.swap_no_default_key_mappings = true
    end,
  },

  -- DONE ✅
}

vim.keymap.set('n', '<leader>z', '<cmd>Lazy<CR>', { silent = true })

return M
