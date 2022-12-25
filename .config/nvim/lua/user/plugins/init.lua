local utils = require 'user.utils'
local nmap = utils.nmap
local nnoremap = utils.nnoremap
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    '--single-branch',
    'https://github.com/folke/lazy.nvim.git',
    lazypath,
  }
end
vim.opt.runtimepath:prepend(lazypath)

require('lazy').setup({
  -- the colorscheme should be available when starting Neovim
  {
    'navarasu/onedark.nvim',
    lazy = true,
  },
  {
    'dstein64/vim-startuptime',
    cmd = 'StartupTime',
  },

  -- Project Drawer
  {
    'kyazdani42/nvim-tree.lua',
    cmd = 'NvimTreeToggle',
    keys = { '<c-o>', '<leader>v' },
    dependencies = { 'kyazdani42/nvim-web-devicons' },
    config = function()
      require 'user.plugins.tree'
    end,
  },

  -- Git Related
  {
    'tpope/vim-fugitive',
    config = function()
      require 'user.plugins.git'
    end,
    event = 'VeryLazy',
    dependencies = {
      {
        'akinsho/git-conflict.nvim',
        config = function()
          require('git-conflict').setup()
        end,
      },
    },
  },
  {
    'lewis6991/gitsigns.nvim',
    event = 'BufReadPre',
    config = function()
      require 'user.plugins.gitsigns'
    end,
  },
  { 'mosheavni/vim-to-github', cmd = { 'ToGithub' } },

  -- Documents
  { 'milisims/nvim-luaref', event = 'VeryLazy' },
  { 'nanotee/luv-vimdocs', event = 'VeryLazy' },

  -- Fuzzy Search - Telescope
  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
      'gnikdroy/projections.nvim',
    },
    config = function()
      require 'user.plugins.telescope'
    end,
    cmd = 'Telescope',
    keys = { '<c-p>', '<c-b>', 'F4', '<leader>hh', '<leader>/', '<leader>fp' },
  },

  -- LSP, Completion and Language
  -- Tree Sitter
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = function()
      pcall(require('nvim-treesitter.install').update { with_sync = true })
    end,
    config = function()
      require 'user.plugins.treesitter'
    end,
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
      'nvim-treesitter/nvim-treesitter-context',
      'nvim-treesitter/nvim-treesitter-refactor',
      'Afourcat/treesitter-terraform-doc.nvim',
      'p00f/nvim-ts-rainbow',
      { 'cuducos/yaml.nvim', ft = 'yaml' },
    },
    event = 'BufReadPost',
  },

  -- LSP
  {
    'neovim/nvim-lspconfig',
    config = function()
      require('user.lsp').setup()
    end,
    event = 'BufReadPre',
    dependencies = {
      'lukas-reineke/lsp-format.nvim',
      'jose-elias-alvarez/null-ls.nvim',
      'folke/lsp-colors.nvim',
      'nanotee/nvim-lsp-basics',
      -- 'j-hui/fidget.nvim',
      'b0o/SchemaStore.nvim',
      'folke/neodev.nvim',
      'someone-stole-my-name/yaml-companion.nvim',
      'jose-elias-alvarez/typescript.nvim',
      'SmiteshP/nvim-navic',
      { 'glepnir/lspsaga.nvim', branch = 'main' },
      {
        'williamboman/mason.nvim',
        dependencies = {
          'williamboman/mason-lspconfig.nvim',
          'jayp0521/mason-null-ls.nvim',
        },
      },
    },
  },
  {
    'folke/trouble.nvim',
    config = function()
      require('trouble').setup {}
    end,
    cmd = 'TroubleToggle',
  },
  { 'vim-scripts/groovyindent-unix', ft = { 'groovy', 'Jenkinsfile' } },
  { 'sam4llis/nvim-lua-gf', ft = 'lua' },
  { 'martinda/Jenkinsfile-vim-syntax', ft = { 'groovy', 'Jenkinsfile' } },
  { 'chr4/nginx.vim', ft = 'nginx' },
  'mosheavni/vim-kubernetes',
  { 'towolf/vim-helm', ft = { 'yaml', 'yaml.gotexttmpl' } },
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
  { 'chrisbra/vim-sh-indent', ft = { 'sh', 'bash', 'zsh' } },

  -- Completion
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'rafamadriz/friendly-snippets',
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
      'onsails/lspkind-nvim',
      { 'tzachar/cmp-tabnine', build = './install.sh' },
      { 'hrsh7th/cmp-nvim-lua', ft = 'lua' },
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-cmdline',
      'petertriho/cmp-git',
      'hrsh7th/cmp-nvim-lsp-signature-help',
      'hrsh7th/cmp-nvim-lsp-document-symbol',
      'windwp/nvim-autopairs',
      'rcarriga/cmp-dap',
    },
    config = function()
      require 'user.plugins.cmpconf'
    end,
    event = 'InsertEnter',
  },
  {
    'phenomenes/ansible-snippets',
    ft = { 'yaml', 'ansible', 'yaml.ansible' },
    config = function()
      vim.g['ansible_goto_role_paths'] = '.;,roles;'
    end,
  },

  -- Github's suggeetsions engine
  {
    'github/copilot.vim',
    event = 'InsertEnter',
  },
  {
    'aduros/ai.vim',
    cmd = 'AI',
  },
  {
    'jackMort/ChatGPT.nvim',
    config = function()
      require('chatgpt').setup {}
    end,
    dependencies = {
      'MunifTanjim/nui.nvim',
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
    },
    cmd = 'ChatGPT',
  },
  {
    'iamcco/markdown-preview.nvim',
    build = 'cd app && yarn install',
    config = function()
      vim.g.mkdp_filetypes = { 'markdown' }
    end,
    cmd = 'MarkdownPreview',
    ft = 'markdown',
  },

  -- Debug Adapter Protocol (DAP)
  {
    'mfussenegger/nvim-dap',
    init = function()
      vim.api.nvim_create_user_command('DAP', function()
        require 'user.plugins.dap'
        require('user.menu').set_dap_actions()
        require('dap').toggle_breakpoint()
        require('dapui').toggle()
      end, {})
    end,
    dependencies = {
      'rcarriga/nvim-dap-ui',
      'mfussenegger/nvim-dap-python',
      'nvim-telescope/telescope-dap.nvim',
      'mxsdev/nvim-dap-vscode-js',
      'theHamsta/nvim-dap-virtual-text',
      'jayp0521/mason-nvim-dap.nvim',
    },
  },

  -- Functionality Tools
  {
    'gbprod/yanky.nvim',
    dependencies = { 'kkharji/sqlite.lua' },
    event = 'VeryLazy',
    config = function()
      require 'user.plugins.yanky'
    end,
  },
  {
    'mizlan/iswap.nvim',
    cmd = { 'ISwap', 'ISwapWith' },
    config = function()
      require('iswap').setup()
      nmap('<leader>sw', ':ISwapWith<CR>')
    end,
  },
  {
    'monkoose/matchparen.nvim',
    event = 'VeryLazy',
    config = function()
      require('matchparen').setup()
    end,
  },

  -- {
  --   'kevinhwang91/nvim-hlslens',
  --   keys = { '*', '#', 'n', 'N' },
  --   config = function()
  --     require('hlslens').setup()
  --     nnoremap('n', [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]], true)
  --     nnoremap('N', [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]], true)
  --     nnoremap('*', [[*<Cmd>lua require('hlslens').start()<CR>]], true)
  --     nnoremap('#', [[#<Cmd>lua require('hlslens').start()<CR>]], true)
  --     nnoremap('g*', [[g*<Cmd>lua require('hlslens').start()<CR>]], true)
  --     nnoremap('g#', [[g#<Cmd>lua require('hlslens').start()<CR>]], true)
  --   end,
  -- },
  -- (convert "${}" to `${}` in JS and "{}" to f"" in Python)
  {
    'axelvc/template-string.nvim',
    ft = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact', 'python' },
    event = 'InsertEnter',
    config = function()
      require('template-string').setup()
    end,
  },
  'vim-scripts/ReplaceWithRegister',
  {
    'kiran94/s3edit.nvim',
    cmd = 'S3Edit',
    config = function()
      require('s3edit').setup()
    end,
  },
  {
    'voldikss/vim-floaterm',
    keys = { 'F6', 'F7', 'F8' },
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
  },
  {
    'samjwill/nvim-unception',
    event = 'VeryLazy',
  },

  { 'mosheavni/vim-dirdiff', cmd = { 'DirDiff' } },
  {
    'simeji/winresizer',
    keys = {
      '<C-e>',
    },
    config = function()
      vim.g.winresizer_vert_resize = 4
    end,
  },
  {
    'pechorin/any-jump.vim',
    cmd = { 'AnyJump', 'AnyJumpVisual' },
    keys = { '<leader>j' },
    config = function()
      nnoremap('<leader>j', '<cmd>AnyJump<CR>')
    end,
  },
  {
    'kazhala/close-buffers.nvim',
    config = function()
      require('close_buffers').setup {}
    end,
    cmd = { 'BDelete', 'BWipeout' },
  },
  {
    'sindrets/diffview.nvim',
    dependencies = 'nvim-lua/plenary.nvim',
    cmd = {
      'DiffviewClose',
      'DiffviewFileHistory',
      'DiffviewFocusFiles',
      'DiffviewLog',
      'DiffviewOpen',
      'DiffviewRefresh',
      'DiffviewToggleFiles',
    },
    config = function()
      require 'diffview'
    end,
  },

  -- Quickfix
  {
    url = 'https://gitlab.com/yorickpeterse/nvim-pqf.git',
    config = function()
      require('pqf').setup()
    end,
  },
  { 'tommcdo/vim-lister', ft = 'qf', cmd = { 'Qfilter', 'Qgrep' } }, -- Qfilter and Qgrep on Quickfix
  { 'kevinhwang91/nvim-bqf', ft = 'qf' },

  -- Look & Feel
  {
    'stevearc/dressing.nvim',
    config = function()
      require('dressing').setup {
        input = {
          enabled = false,
        },
        -- input = {
        --   override = function(conf)
        --     conf.col = -1
        --     conf.row = 0
        --     return conf
        --   end,
        --   win_options = {
        --     winhighlight = 'NormalFloat:Normal',
        --     winblend = 0,
        --   },
        --   border = 'rounded',
        --   width = '1.0',
        --   prompt_align = 'center',
        --   -- get_config = function()
        --   --   if vim.api.nvim_buf_get_option(0, 'filetype') == 'NvimTree' then
        --   --     return { enabled = false }
        --   --   end
        --   -- end,
        -- },
      }
      vim.cmd [[hi link FloatTitle Normal]]
    end,
    event = 'VeryLazy',
  },
  {
    'folke/noice.nvim',
    config = function()
      require 'user.plugins.noice'
    end,
    dependencies = {
      -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
      'MunifTanjim/nui.nvim',
      -- OPTIONAL:
      --   `nvim-notify` is only needed, if you want to use the notification view.
      --   If not available, we use `mini` as the fallback
      'rcarriga/nvim-notify',
    },
    event = 'VeryLazy',
  },
  {
    'lukas-reineke/indent-blankline.nvim',
    config = function()
      require 'user.plugins.indentlines'
    end,
    event = 'BufReadPre',
  },
  {
    'noib3/nvim-cokeline',
    config = function()
      require 'user.plugins.bufferline'
    end,
    event = 'BufReadPre',
  },
  {
    'RRethy/vim-illuminate',
    event = 'BufReadPost',
  },

  {
    'nvim-lualine/lualine.nvim',
    config = function()
      require 'user.plugins.lualine'
    end,
    dependencies = {
      'SmiteshP/nvim-navic',
    },
    event = 'VeryLazy',
  },
  'kyazdani42/nvim-web-devicons',
  -- 'karb94/neoscroll.nvim',
  'mhinz/vim-startify',
  { 'vim-scripts/CursorLineCurrentWindow', event = 'VeryLazy' },
  {
    'norcalli/nvim-colorizer.lua',
    config = function()
      require 'user.plugins.colorizer'
    end,
    event = 'BufReadPre',
  },

  -- Themes
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

  -- Text Manipulation
  { 'tpope/vim-repeat', event = 'VeryLazy' },
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
  'junegunn/vim-easy-align',
  {
    'nguyenvukhang/nvim-toggler',
    keys = { 'gs' },
    config = function()
      require('nvim-toggler').setup {
        remove_default_keybinds = true,
        inverses = {
          ['enable'] = 'disable',
        },
      }
      vim.keymap.set({ 'n', 'v' }, 'gs', require('nvim-toggler').toggle)
    end,
  },
  {
    'ggandor/leap.nvim',
    event = 'VeryLazy',
  },
  { 'windwp/nvim-ts-autotag', ft = { 'html', 'javascript' } },
  { 'gpanders/editorconfig.nvim', event = 'VeryLazy' },

  -- DONE ✅
}, {
  ui = {
    border = 'rounded',
    custom_keys = {
      ['<localleader>l'] = function(plugin)
        require('lazy.util').open_cmd({ 'git', 'log' }, {
          cwd = plugin.dir,
          terminal = true,
          close_on_exit = true,
          enter = true,
        })
      end,

      -- open a terminal for the plugin dir
      ['<localleader>t'] = function(plugin)
        vim.cmd('FloatermNew --cwd=' .. plugin.dir)
      end,
    },
  },
  checker = {
    -- automatically check for plugin updates
    enabled = false,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        'rplugin',
        'gzip',
        'matchit',
        'matchparen',
        'shada',
        'tarPlugin',
        'tohtml',
        'tutor',
        'zipPlugin',
      },
    },
  },
})

require 'user.plugins.configs'
