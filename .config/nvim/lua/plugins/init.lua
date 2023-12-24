local utils = require 'user.utils'
local nmap = utils.nmap

local M = {
  -------------------
  --   Colorscheme --
  -------------------
  {
    'navarasu/onedark.nvim',
    enabled = false,
    config = function()
      require('onedark').setup {
        style = 'dark',
        highlights = {
          EndOfBuffer = { fg = '#61afef' },
        },
      }
      require('onedark').load()
    end,
  },
  {
    'sainnhe/gruvbox-material',
    enabled = true,
    config = function()
      -- load the colorscheme here
      vim.cmd [[
        let g:gruvbox_material_better_performance = 1
        let g:gruvbox_material_background = 'hard' " soft | medium | hard
        colorscheme gruvbox-material
      ]]
    end,
  },
  {
    'tiagovla/tokyodark.nvim',
    enabled = false,
    opts = {},
    config = function(_, opts)
      require('tokyodark').setup(opts) -- calling setup is optional
      vim.cmd [[colorscheme tokyodark]]
    end,
  },
  {
    'dstein64/vim-startuptime',
    cmd = 'StartupTime',
  },

  ------------------------------------
  -- Language Server Protocol (LSP) --
  ------------------------------------
  {
    'folke/trouble.nvim',
    config = true,
    cmd = 'TroubleToggle',
  },
  -- {
  --   'vim-scripts/groovyindent-unix',
  --   ft = { 'groovy', 'Jenkinsfile' },
  -- },
  {
    'sam4llis/nvim-lua-gf',
    ft = 'lua',
  },
  -- {
  --   'martinda/Jenkinsfile-vim-syntax',
  --   ft = { 'groovy', 'Jenkinsfile' },
  -- },
  {
    'chr4/nginx.vim',
    ft = 'nginx',
  },
  {
    'mosheavni/vim-kubernetes',
    ft = 'yaml',
  },
  -- {
  --   'towolf/vim-helm',
  --   ft = { 'yaml', 'yaml.gotexttmpl' },
  -- },
  { 'cuducos/yaml.nvim', ft = 'yaml' },
  {
    'phelipetls/jsonpath.nvim',
    ft = 'json',
    config = function()
      vim.api.nvim_buf_create_user_command(0, 'JsonPath', function()
        local json_path = require('jsonpath').get()
        local register = '+'
        vim.fn.setreg(register, json_path)
        vim.notify('Copied ' .. json_path .. ' to register ' .. register, vim.log.levels.INFO, { title = 'JsonPath' })
      end, {})
    end,
  },
  {
    'chrisbra/vim-sh-indent',
    ft = { 'sh', 'bash', 'zsh' },
  },
  {
    'milisims/nvim-luaref',
    ft = 'lua',
  },
  { 'cuducos/yaml.nvim', ft = 'yaml' },

  -----------------------------
  -- AI and smart completion --
  -----------------------------
  -- {
  --   'github/copilot.vim',
  --   event = 'InsertEnter',
  --   config = function()
  --     vim.cmd [[
  --       imap <silent><script><expr> <M-Enter> copilot#Accept("\<CR>")
  --       " imap <silent> <c-]> <Plug>(copilot-next)
  --       " inoremap <silent> <c-[> <Plug>(copilot-previous)
  --       let g:copilot_no_tab_map = v:true
  --     ]]
  --   end,
  -- },
  {
    'David-Kunz/gen.nvim',
    cmd = { 'Gen' },
  },
  {
    'Exafunction/codeium.nvim',
    lazy = true,
    config = function()
      require('codeium').setup {}
    end,
  },
  {
    'zbirenbaum/copilot.lua',
    event = 'InsertEnter',
    config = function()
      vim.schedule(function()
        require('copilot').setup {
          panel = {
            enabled = true,
            auto_refresh = false,
            keymap = {
              jump_prev = '[[',
              jump_next = ']]',
              accept = '<CR>',
              refresh = 'gr',
              open = '<M-l>',
            },
          },
          suggestion = {
            auto_trigger = true,
            keymap = {
              accept = '<M-Enter>',
            },
          },
        }
      end)
    end,
  },

  --------------
  -- Quickfix --
  --------------
  {
    'yorickpeterse/nvim-pqf',
    config = true,
    event = 'BufWinEnter',
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

  -----------------------
  -- Text Manipulation --
  -----------------------
  {
    'tpope/vim-repeat',
    event = 'VeryLazy',
  },
  {
    'tpope/vim-surround',
    keys = { 'ds', 'cs', 'ys', { 'S', nil, mode = 'v' } },
  },
  {
    'numToStr/Comment.nvim',
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('Comment').setup {
        pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
      }
    end,
    keys = { 'gc', 'gcc', { 'gc', nil, mode = 'v' } },
    dependencies = {
      'JoosepAlviste/nvim-ts-context-commentstring',
    },
  },
  {
    'junegunn/vim-easy-align',
    keys = { { 'ga', '<Plug>(EasyAlign)', mode = { 'v', 'n' } } },
  },
  {
    'AndrewRadev/switch.vim',
    keys = {
      { 'gs', nil, { 'n', 'v' } },
    },
    config = function()
      local fk = [=[\<\(\l\)\(\l\+\(\u\l\+\)\+\)\>]=]
      local sk = [=[\<\(\u\l\+\)\(\u\l\+\)\+\>]=]
      local tk = [=[\<\(\l\+\)\(_\l\+\)\+\>]=]
      local fok = [=[\<\(\u\+\)\(_\u\+\)\+\>]=]
      local fik = [=[\<\(\l\+\)\(-\l\+\)\+\>]=]
      vim.g['switch_custom_definitions'] = {
        vim.fn['switch#NormalizedCaseWords'] { 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday' },
        vim.fn['switch#NormalizedCase'] { 'yes', 'no' },
        vim.fn['switch#NormalizedCase'] { 'on', 'off' },
        vim.fn['switch#NormalizedCase'] { 'left', 'right' },
        vim.fn['switch#NormalizedCase'] { 'up', 'down' },
        vim.fn['switch#NormalizedCase'] { 'enable', 'disable' },
        { '==', '!=' },
        {
          [fk] = [=[\=toupper(submatch(1)) . submatch(2)]=],
          [sk] = [=[\=tolower(substitute(submatch(0), '\(\l\)\(\u\)', '\1_\2', 'g'))]=],
          [tk] = [=[\U\0]=],
          [fok] = [=[\=tolower(substitute(submatch(0), '_', '-', 'g'))]=],
          [fik] = [=[\=substitute(submatch(0), '-\(\l\)', '\u\1', 'g')]=],
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
    'ggandor/leap.nvim',
    keys = {
      { 's', '<Plug>(leap-forward-to)' },
      { 'S', '<Plug>(leap-backward-to)' },
    },
  },
  {
    'axelvc/template-string.nvim',
    ft = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact', 'python' },
    event = 'InsertEnter',
    config = true,
  },
  {
    'mizlan/iswap.nvim',
    cmd = { 'ISwap', 'ISwapWith' },
    init = function()
      nmap('<leader>sw', ':ISwapWith<CR>')
    end,
    config = true,
  },
  {
    'vim-scripts/ReplaceWithRegister',
    keys = {
      { '<leader>p', '<Plug>ReplaceWithRegisterOperator' },
      { '<leader>P', '<Plug>ReplaceWithRegisterLine' },
      { '<leader>p', '<Plug>ReplaceWithRegisterVisual', mode = { 'x' } },
    },
  },
  {
    'vidocqh/auto-indent.nvim',
    event = 'InsertEnter',
    opts = {},
  },

  -- DONE ✅
}

nmap('<leader>z', '<cmd>Lazy<CR>', true)

return M
