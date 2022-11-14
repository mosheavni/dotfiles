local fn = vim.fn

-- Install packer
local install_path = vim.fn.stdpath 'data' .. '/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  PACKER_BOOTSTRAP = fn.system {
    'git',
    'clone',
    '--depth',
    '1',
    'https://github.com/wbthomason/packer.nvim',
    install_path,
  }
  print 'Installing packer close and reopen Neovim...'
  vim.cmd [[packadd packer.nvim]]
end

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, 'packer')
if not status_ok then
  return
end
packer.init {
  max_jobs = 10,
  display = {
    open_fn = function()
      return require('packer.util').float { border = 'rounded' }
    end,
  },
}
return packer.startup(function(use)
  -- Infrastructure
  use 'wbthomason/packer.nvim'
  use 'lewis6991/impatient.nvim'
  use 'nvim-lua/plenary.nvim'
  use {
    'dstein64/vim-startuptime',
    cmd = 'StartupTime',
  }

  -- Project Drawer
  use {
    'kyazdani42/nvim-tree.lua',
    command = 'NvimTreeToggle',
    requires = { 'kyazdani42/nvim-web-devicons' },
    config = "require('user.plugins.tree')",
  }

  -- Git Related
  use 'tpope/vim-fugitive'
  use {
    'lewis6991/gitsigns.nvim',
    event = 'BufWinEnter',
    config = function()
      require 'user.plugins.gitsigns'
    end,
  }
  use { 'mosheavni/vim-to-github', cmd = { 'ToGithub' } }
  use 'akinsho/git-conflict.nvim'

  -- Documents
  use 'nanotee/luv-vimdocs'
  use 'milisims/nvim-luaref'

  -- Fuzzy Search - Telescope
  use {
    'nvim-telescope/telescope.nvim',
    requires = {
      { 'nvim-lua/plenary.nvim' },
      { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
      { 'nvim-telescope/telescope-project.nvim' },
    },
    config = "require('user.plugins.telescope')",
  }

  -- LSP, Completion and Language
  -- Tree Sitter
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    config = "require('user.plugins.treesitter')",
  }
  use 'nvim-treesitter/nvim-treesitter-textobjects'
  use 'p00f/nvim-ts-rainbow'
  use 'JoosepAlviste/nvim-ts-context-commentstring'
  use {
    'SmiteshP/nvim-navic',
    requires = 'neovim/nvim-lspconfig',
  }
  use {
    'cuducos/yaml.nvim',
    ft = { 'yaml' }, -- optional
    requires = { 'nvim-treesitter/nvim-treesitter' },
  }
  use 'someone-stole-my-name/yaml-companion.nvim'
  use 'nvim-treesitter/nvim-treesitter-context'
  use 'nvim-treesitter/nvim-treesitter-refactor'
  use { 'sam4llis/nvim-lua-gf', ft = { 'lua' } }
  use 'Afourcat/treesitter-terraform-doc.nvim'
  use 'David-Kunz/markid'

  -- LSP
  use 'williamboman/mason.nvim'
  use 'williamboman/mason-lspconfig.nvim'
  use {
    'neovim/nvim-lspconfig',
    config = "require('user.lsp')",
    event = 'UIEnter',
  }
  use {
    'ray-x/lsp_signature.nvim', -- Show function signature when you type
    'lukas-reineke/lsp-format.nvim',
    'jose-elias-alvarez/null-ls.nvim',
    'b0o/SchemaStore.nvim',
    'folke/lsp-colors.nvim',
    'nanotee/nvim-lsp-basics',
    'j-hui/fidget.nvim',
    after = 'nvim-lspconfig',
  }
  use {
    'jayp0521/mason-null-ls.nvim',
    after = {
      'null-ls.nvim',
      'mason.nvim',
    },
  }
  use { 'vim-scripts/groovyindent-unix', ft = { 'groovy', 'Jenkinsfile' } }
  use { 'martinda/Jenkinsfile-vim-syntax', ft = { 'groovy', 'Jenkinsfile' } }
  use { 'chr4/nginx.vim', ft = { 'nginx' } }
  use { 'mosheavni/vim-kubernetes', ft = { 'yaml' } }
  use { 'towolf/vim-helm', ft = { 'yaml', 'yaml.gotexttmpl' } }
  use { 'mogelbrod/vim-jsonpath', ft = { 'json' } }
  use { 'chrisbra/vim-sh-indent', ft = { 'sh', 'bash', 'zsh' } }
  use 'folke/neodev.nvim'
  use 'jose-elias-alvarez/typescript.nvim'
  use {
    'kosayoda/nvim-lightbulb',
    requires = 'antoinemadec/FixCursorHold.nvim',
  }

  -- Completion
  use {
    'hrsh7th/nvim-cmp',
    requires = {
      'rafamadriz/friendly-snippets',
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
      'onsails/lspkind-nvim',
      { 'tzachar/cmp-tabnine', run = './install.sh' },
      { 'hrsh7th/cmp-nvim-lua', ft = { 'lua' } },
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-cmdline',
      'hrsh7th/cmp-nvim-lsp-signature-help',
      'hrsh7th/cmp-nvim-lsp-document-symbol',
      'windwp/nvim-autopairs',
    },
    config = "require('user.plugins.cmpconf')",
  }
  use { 'phenomenes/ansible-snippets', ft = { 'yaml', 'ansible', 'yaml.ansible' } }

  -- Github's suggeetsions engine
  use {
    'github/copilot.vim',
    event = 'InsertEnter',
  }
  use {
    'iamcco/markdown-preview.nvim',
    run = 'cd app && yarn install',
    setup = function()
      vim.g.mkdp_filetypes = { 'markdown' }
    end,
    cmd = 'MarkdownPreview',
    ft = { 'markdown' },
  }

  -- Debug Adapter Protocol (DAP)
  use {
    {
      'mfussenegger/nvim-dap',
      config = "require('user.plugins.dap')",
    },
    'rcarriga/nvim-dap-ui',
    'mfussenegger/nvim-dap-python',
    'nvim-telescope/telescope-dap.nvim',
    -- 'mxsdev/nvim-dap-vscode-js',
    'theHamsta/nvim-dap-virtual-text',
    'Pocco81/dap-buddy.nvim',
  }
  use {
    'rcarriga/cmp-dap',
    after = 'nvim-cmp',
  }

  -- Functionality Tools
  use {
    'gbprod/yanky.nvim',
    config = function()
      require('yanky').setup {
        ring = {
          history_length = 100,
          storage = 'sqlite',
          sync_with_numbered_registers = true,
          cancel_event = 'update',
        },
      }
      vim.keymap.set({ 'n', 'x' }, 'p', '<Plug>(YankyPutAfter)')
      vim.keymap.set({ 'n', 'x' }, 'P', '<Plug>(YankyPutBefore)')
      vim.keymap.set({ 'n', 'x' }, 'gp', '<Plug>(YankyGPutAfter)')
      vim.keymap.set({ 'n', 'x' }, 'gP', '<Plug>(YankyGPutBefore)')
      vim.keymap.set('n', '<c-n>', '<Plug>(YankyCycleForward)')
      vim.keymap.set('n', '<c-m>', '<Plug>(YankyCycleBackward)')
    end,
    requires = { 'kkharji/sqlite.lua' },
  }
  use 'kevinhwang91/nvim-hlslens'
  use {
    'axelvc/template-string.nvim',
    ft = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact', 'python' },
    config = function()
      require('template-string').setup()
    end,
  }
  use 'vim-scripts/ReplaceWithRegister'
  use {
    'kiran94/s3edit.nvim',
    config = function()
      require('s3edit').setup()
    end,
    cmd = 'S3Edit',
  }
  use {
    'voldikss/vim-floaterm',
    keys = {
      'F6',
      'F7',
      'F8',
    },
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
  }
  use { 'mosheavni/vim-dirdiff', cmd = { 'DirDiff' } }
  use {
    'simeji/winresizer',
    keys = {
      '<C-e>',
    },
  }
  use 'tiagovla/scope.nvim'
  use { 'pechorin/any-jump.vim', cmd = { 'AnyJump', 'AnyJumpVisual' } }
  use 'kazhala/close-buffers.nvim'

  use 'folke/which-key.nvim'
  use {
    'sindrets/diffview.nvim',
    requires = 'nvim-lua/plenary.nvim',
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
      require('diffview').setup()
    end,
  }

  -- Quickfix
  use {
    'https://gitlab.com/yorickpeterse/nvim-pqf.git',
    config = "require('pqf').setup()",
  }
  use { 'kevinhwang91/nvim-bqf', ft = 'qf' }
  use { 'tommcdo/vim-lister', ft = 'qf', cmd = { 'Qfilter', 'Qgrep' } } -- Qfilter and Qgrep on Quickfix

  -- Look & Feel
  use 'stevearc/dressing.nvim' -- overrides the default vim input to provide better visuals
  use 'rcarriga/nvim-notify'
  use {
    'lukas-reineke/indent-blankline.nvim',
    config = "require('user.plugins.indentlines')",
  }
  use {
    'akinsho/bufferline.nvim',
    tag = 'v2.*',
    event = 'UIEnter',
    config = "require('user.plugins.bufferline')",
  }
  use 'RRethy/vim-illuminate'
  use {
    'nvim-zh/colorful-winsep.nvim',
    config = function()
      require('colorful-winsep').setup()
    end,
  }

  use {
    'nvim-lualine/lualine.nvim',
    config = "require('user.plugins.lualine')",
  }
  use 'kyazdani42/nvim-web-devicons'
  -- use 'karb94/neoscroll.nvim'
  use 'mhinz/vim-startify'
  use 'vim-scripts/CursorLineCurrentWindow'
  use {
    'norcalli/nvim-colorizer.lua',
    config = "require('user.plugins.colorizer')",
    event = { 'UIEnter' },
  }

  -- Themes
  -- use 'drewtempelmeyer/palenight.vim'
  -- use 'joshdick/onedark.vim'
  -- use 'ghifarit53/tokyonight-vim'
  -- use { 'dracula/vim', as = 'dracula' }
  -- use 'jacoborus/tender.vim'
  -- use 'ellisonleao/gruvbox.nvim'
  -- use 'ellisonleao/gruvbox.nvim'
  -- use 'rafamadriz/neon'
  -- use 'marko-cerovac/material.nvim'
  -- use 'folke/tokyonight.nvim'
  -- use 'cpea2506/one_monokai.nvim'
  -- use 'Mofiqul/vscode.nvim'
  -- use 'cpea2506/one_monokai.nvim'
  use 'navarasu/onedark.nvim'
  -- use 'rebelot/kanagawa.nvim'
  -- use {
  --   'catppuccin/nvim',
  --   as = 'catppuccin',
  -- }
  -- use { 'luisiacc/gruvbox-baby', branch = 'main' }

  -- Text Manipulation
  use 'tpope/vim-repeat'
  use 'tpope/vim-surround'
  use 'numToStr/Comment.nvim'
  use 'junegunn/vim-easy-align'
  use 'AndrewRadev/switch.vim'
  use {
    'ggandor/leap.nvim',
    config = function()
      vim.keymap.set('n', 's', '<Plug>(leap-forward-to)', { silent = true })
      vim.keymap.set('n', 'S', '<Plug>(leap-backward-to)', { silent = true })
    end,
  }
  use { 'alvan/vim-closetag', ft = { 'html', 'javascript' } }
  use 'editorconfig/editorconfig-vim'

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if PACKER_BOOTSTRAP then
    require('packer').sync()
  end
end)
