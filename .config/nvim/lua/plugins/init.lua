local utils = require 'user.utils'
local nmap = utils.nmap

local M = {
  -------------------
  --   Colorscheme --
  -------------------
  -- {
  --   'navarasu/onedark.nvim',
  --   config = function()
  --     require('onedark').setup {
  --       style = 'dark',
  --       highlights = {
  --         EndOfBuffer = { fg = '#61afef' },
  --       },
  --     }
  --     require('onedark').load()
  --   end,
  -- },
  -- {
  --   'uloco/bluloco.nvim',
  --   enabled = false,
  --   lazy = false,
  --   priority = 1000,
  --   dependencies = { 'rktjmp/lush.nvim' },
  --   config = function()
  --     vim.cmd [[colorscheme bluloco-dark]]
  --   end,
  -- },
  {
    'sainnhe/gruvbox-material',
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
    event = 'VeryLazy',
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
    event = 'VeryLazy',
  },
  {
    'nanotee/luv-vimdocs',
    event = 'VeryLazy',
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
  -- {
  --   'jackMort/ChatGPT.nvim',
  --   config = true,
  --   dependencies = {
  --     'MunifTanjim/nui.nvim',
  --     'nvim-lua/plenary.nvim',
  --     'nvim-telescope/telescope.nvim',
  --   },
  --   cmd = 'ChatGPT',
  -- },
  -- {
  --   'dense-analysis/neural',
  --   dependencies = {
  --     'muniftanjim/nui.nvim',
  --     'elpiloto/significant.nvim',
  --   },
  --   opts = {
  --     source = {
  --       openai = {
  --         api_key = vim.env.OPENAI_API_KEY,
  --       },
  --     },
  --   },
  -- },

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

  ------------
  -- Themes --
  ------------
  -- 'Mofiqul/vscode.nvim',
  -- 'cpea2506/one_monokai.nvim',
  -- 'drewtempelmeyer/palenight.vim',
  -- 'ellisonleao/gruvbox.nvim',
  -- 'folke/tokyonight.nvim',
  -- 'ghifarit53/tokyonight-vim',
  -- 'jacoborus/tender.vim',
  -- 'joshdick/onedark.vim',
  -- 'marko-cerovac/material.nvim',
  -- 'rafamadriz/neon',
  -- 'rebelot/kanagawa.nvim',
  -- { 'dracula/vim', as = 'dracula' },
  -- { 'luisiacc/gruvbox-baby', branch = 'main' },
  -- {
  --   'catppuccin/nvim',
  --   name = 'catppuccin',
  -- },

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
    'nguyenvukhang/nvim-toggler',
    keys = {
      { 'gs', nil, { 'n', 'v' } },
    },
    opts = {
      remove_default_keybinds = true,
      inverses = {
        ['enable'] = 'disable',
        ['internet-facing'] = 'internal',
      },
    },
    config = function(_, opts)
      require('nvim-toggler').setup(opts)
      vim.keymap.set({ 'n', 'v' }, 'gs', require('nvim-toggler').toggle)
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
    'windwp/nvim-ts-autotag',
    ft = { 'html', 'javascript', 'jsx', 'markdown', 'typescript', 'xml' },
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
    opts = {},
  },

  -- DONE ✅
}

nmap('<leader>z', ':Lazy<CR>', true)

return M
