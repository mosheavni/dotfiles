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

require('lazy').setup {
  -- the colorscheme should be available when starting Neovim
  'navarasu/onedark.nvim',
  'nvim-lua/plenary.nvim',
  {
    'dstein64/vim-startuptime',
    cmd = 'StartupTime',
  },

  -- Project Drawer
  {
    'kyazdani42/nvim-tree.lua',
    command = 'NvimTreeToggle',
    dependencies = { 'kyazdani42/nvim-web-devicons' },
    config = function()
      require 'user.plugins.tree'
    end,
    event = 'VeryLazy',
  },

  -- Git Related
  {
    'tpope/vim-fugitive',
    config = function()
      require 'user.git'
    end,
    event = 'VeryLazy',
  },
  {
    'lewis6991/gitsigns.nvim',
    event = 'BufWinEnter',
    config = function()
      require 'user.plugins.gitsigns'
    end,
  },
  { 'mosheavni/vim-to-github', cmd = { 'ToGithub' } },
  {
    'akinsho/git-conflict.nvim',
    config = function()
      require('git-conflict').setup()
    end,
    event = 'VeryLazy',
  },

  -- Documents
  { 'milisims/nvim-luaref', event = 'VeryLazy' },
  { 'nanotee/luv-vimdocs', events = 'VeryLazy' },

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
  },

  -- LSP
  {
    'neovim/nvim-lspconfig',
    config = function()
      require('user.lsp').setup()
    end,
    event = 'UIEnter',
    dependencies = {
      'lukas-reineke/lsp-format.nvim',
      'jose-elias-alvarez/null-ls.nvim',
      'b0o/SchemaStore.nvim',
      'folke/lsp-colors.nvim',
      'nanotee/nvim-lsp-basics',
      'j-hui/fidget.nvim',
      'folke/neodev.nvim',
      'someone-stole-my-name/yaml-companion.nvim',
      'jose-elias-alvarez/typescript.nvim',
      'SmiteshP/nvim-navic',
      { 'glepnir/lspsaga.nvim', branch = 'main' },
      {
        'folke/trouble.nvim',
        config = function()
          require('trouble').setup {}
        end,
      },
    },
  },
  {
    'williamboman/mason.nvim',
    dependencies = {
      'williamboman/mason-lspconfig.nvim',
      'jayp0521/mason-null-ls.nvim',
      'jayp0521/mason-nvim-dap.nvim',
    },
    event = 'VeryLazy',
  },
  { 'vim-scripts/groovyindent-unix', ft = { 'groovy', 'Jenkinsfile' } },
  { 'sam4llis/nvim-lua-gf', ft = 'lua' },
  { 'martinda/Jenkinsfile-vim-syntax', ft = { 'groovy', 'Jenkinsfile' } },
  { 'chr4/nginx.vim', ft = 'nginx' },
  'mosheavni/vim-kubernetes',
  { 'towolf/vim-helm', ft = { 'yaml', 'yaml.gotexttmpl' } },
  { 'mogelbrod/vim-jsonpath', ft = 'json' },
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
    },
    config = function()
      require 'user.plugins.cmpconf'
    end,
  },
  { 'phenomenes/ansible-snippets', ft = { 'yaml', 'ansible', 'yaml.ansible' } },

  -- Github's suggeetsions engine
  {
    'github/copilot.vim',
    event = 'InsertEnter',
  },
  'aduros/ai.vim',
  {
    'jackMort/ChatGPT.nvim',
    config = function()
      require('chatgpt').setup {
        -- optional configuration
      }
    end,
    dependencies = {
      'MunifTanjim/nui.nvim',
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
    },
  },
  {
    'iamcco/markdown-preview.nvim',
    build = 'cd app && yarn install',
    setup = function()
      vim.g.mkdp_filetypes = { 'markdown' }
    end,
    cmd = 'MarkdownPreview',
    ft = 'markdown',
  },

  -- Debug Adapter Protocol (DAP)
  {
    {
      'mfussenegger/nvim-dap',
      config = function()
        require 'user.plugins.dap'
      end,
    },
    'rcarriga/nvim-dap-ui',
    'mfussenegger/nvim-dap-python',
    'nvim-telescope/telescope-dap.nvim',
    'mxsdev/nvim-dap-vscode-js',
    'theHamsta/nvim-dap-virtual-text',
    'Pocco81/dap-buddy.nvim',
  },
  {
    'rcarriga/cmp-dap',
    after = 'nvim-cmp',
  },

  -- Functionality Tools
  {
    'gbprod/yanky.nvim',
    dependencies = { 'kkharji/sqlite.lua' },
    lazy = true,
  },
  'mizlan/iswap.nvim',
  'kevinhwang91/nvim-hlslens',
  -- (convert "${}" to `${}` in JS and "{}" to f"" in Python)
  {
    'axelvc/template-string.nvim',
    ft = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact', 'python' },
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
  { 'pechorin/any-jump.vim', cmd = { 'AnyJump', 'AnyJumpVisual' } },
  {
    'kazhala/close-buffers.nvim',
    config = function()
      require('close_buffers').setup {}
    end,
  },

  'folke/which-key.nvim',
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
  { 'kevinhwang91/nvim-bqf', ft = 'qf' },
  { 'tommcdo/vim-lister', ft = 'qf', cmd = { 'Qfilter', 'Qgrep' } }, -- Qfilter and Qgrep on Quickfix

  -- Look & Feel
  { 'stevearc/dressing.nvim', event = 'VeryLazy' },
  'rcarriga/nvim-notify',
  {
    'lukas-reineke/indent-blankline.nvim',
    config = function()
      require 'user.plugins.indentlines'
    end,
  },
  {
    'akinsho/bufferline.nvim',
    tag = 'v2.*',
    event = 'UIEnter',
    config = function()
      require 'user.plugins.bufferline'
    end,
  },
  'RRethy/vim-illuminate',

  {
    'nvim-lualine/lualine.nvim',
    config = function()
      require 'user.plugins.lualine'
    end,
  },
  'kyazdani42/nvim-web-devicons',
  -- 'karb94/neoscroll.nvim',
  'mhinz/vim-startify',
  'vim-scripts/CursorLineCurrentWindow',
  {
    'norcalli/nvim-colorizer.lua',
    config = function()
      require 'user.plugins.colorizer'
    end,
    event = { 'UIEnter' },
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
  'tpope/vim-repeat',
  'tpope/vim-surround',
  {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup {}
    end,
  },
  'junegunn/vim-easy-align',
  'nguyenvukhang/nvim-toggler',

  {
    'ggandor/leap.nvim',
  },
  { 'windwp/nvim-ts-autotag', ft = { 'html', 'javascript' } },
  'gpanders/editorconfig.nvim',

  -- -- you can use the VeryLazy event for things that can
  -- -- load later and are not important for the initial UI
  -- { 'stevearc/dressing.nvim', event = 'VeryLazy' },
  --
  -- {
  --   'cshuaimin/ssr.nvim',
  --   -- init is always executed during startup, but doesn't load the plugin yet.
  --   -- init implies lazy loading
  --   init = function()
  --     vim.keymap.set({ 'n', 'x' }, '<leader>cR', function()
  --       -- this require will automatically load the plugin
  --       require('ssr').open()
  --     end, { desc = 'Structural Replace' })
  --   end,
  -- },
  --
  -- {
  --   'monaqa/dial.nvim',
  --   -- lazy-load on keys
  --   keys = { '<C-a>', '<C-x>' },
  -- },
  --
  -- -- local plugins need to be explicitly configured with dir
  -- { dir = '~/projects/secret.nvim' },
  --
  -- -- you can use a custom url to fetch a plugin
  -- { url = 'git@github.com:folke/noice.nvim.git' },
  --
  -- -- local plugins can also be configure with the dev option.
  -- -- This will use {config.dev.path}/noice.nvim/ instead of fetching it from Github
  -- -- With the dev option, you can easily switch between the local and installed version of a plugin
  -- { 'folke/noice.nvim', dev = true },
}
require 'user.plugins.configs'
