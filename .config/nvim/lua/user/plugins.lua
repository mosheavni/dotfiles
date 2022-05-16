return require('packer').startup(function(use)
  -- Infrastructure
  use 'wbthomason/packer.nvim'
  use 'lewis6991/impatient.nvim'
  use 'nvim-lua/plenary.nvim'

  -- Project Drawer
  use { 'preservim/nerdtree', cmd = { 'NERDTreeToggle' } }
  use { 'Xuyuanp/nerdtree-git-plugin', cmd = { 'NERDTreeToggle' } }

  -- Git Related
  use {
    'lewis6991/gitsigns.nvim',
    tag = 'release' -- To use the latest release
  }
  use { 'tpope/vim-fugitive' }
  use { 'mosheavni/vim-to-github', cmd = { 'ToGithub' } }
  use { 'rhysd/conflict-marker.vim' }
  use { 'tveskag/nvim-blame-line' }

  -- Documents
  use 'nanotee/luv-vimdocs'
  use 'milisims/nvim-luaref'

  -- Fuzzy Search
  -- use {
  --   'junegunn/fzf',
  --   dir = '~/.fzf', run = './install --all'
  -- }
  -- use { 'junegunn/fzf.vim' }
  use {
    'nvim-telescope/telescope.nvim',
    requires = {
      { 'nvim-lua/plenary.nvim' },
      { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }
    }
  }

  -- LSP, Completion and Language
  -- Tree Sitter
  use {
    "nvim-treesitter/nvim-treesitter",
    run = ":TSUpdate",
  }
  use {
    "SmiteshP/nvim-gps",
    requires = "nvim-treesitter/nvim-treesitter"
  }
  use {
    "cuducos/yaml.nvim",
    ft = { "yaml" }, -- optional
    requires = {
      "nvim-treesitter/nvim-treesitter",
    },
  }
  use 'lewis6991/nvim-treesitter-context'
  use 'nvim-treesitter/nvim-treesitter-refactor'
  -- LSP
  use {
    "neovim/nvim-lspconfig",
    "williamboman/nvim-lsp-installer",
    "ray-x/lsp_signature.nvim",
    "jose-elias-alvarez/null-ls.nvim",
    "b0o/SchemaStore.nvim",
    'onsails/lspkind-nvim', -- show pictograms in the auto complete popup
    'folke/lsp-colors.nvim',
    'nvim-lua/lsp-status.nvim',
    'j-hui/fidget.nvim',
    'nanotee/nvim-lsp-basics',
    {
      'kosayoda/nvim-lightbulb',
      setup = function()
        vim.cmd [[autocmd CursorHold,CursorHoldI * lua require'nvim-lightbulb'.update_lightbulb()]]
      end
    },
  }
  use({
    'hrsh7th/nvim-cmp', -- auto completion
    requires = {
      'hrsh7th/cmp-nvim-lsp',
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-nvim-lua',
      'hrsh7th/cmp-cmdline',
      { 'tzachar/cmp-tabnine', run = './install.sh' },
      'windwp/nvim-autopairs',
      { 'Saecki/crates.nvim', requires = { 'nvim-lua/plenary.nvim' }, branch = 'main' },
      'hrsh7th/cmp-nvim-lsp-document-symbol',
    },
  })
  use({
    "iamcco/markdown-preview.nvim",
    run = "cd app && yarn install",
    setup = function() vim.g.mkdp_filetypes = { "markdown" } end,
    cmd = 'MarkdownPreview',
    ft = { "markdown" },
  })
  use { 'vim-scripts/groovyindent-unix', ft = { 'groovy', 'Jenkinsfile' } }
  use { 'martinda/Jenkinsfile-vim-syntax', ft = { 'Jenkinsfile', 'groovy' } }
  use { 'chr4/nginx.vim', ft = { 'nginx' } }
  use { 'rayburgemeestre/phpfolding.vim', ft = { 'php' } }
  use { 'andrewstuart/vim-kubernetes', ft = { 'yaml' } }
  use { 'towolf/vim-helm', ft = { 'yaml', 'yaml.gotexttmpl' } }
  use { 'mogelbrod/vim-jsonpath', ft = { 'json' } }
  use { 'chrisbra/vim-sh-indent', ft = { 'sh', 'bash', 'zsh' } }
  use { 'hashivim/vim-terraform', ft = { 'terraform' } }
  use { 'phenomenes/ansible-snippets', ft = { 'yaml' } }
  use('rafamadriz/friendly-snippets') -- snippets for many languages

  -- Functionality Tools
  use 'christoomey/vim-system-copy'
  use 'danro/rename.vim'
  use 'voldikss/vim-floaterm'
  use { 'mosheavni/vim-dirdiff', cmd = { 'DirDiff' } }
  use 'simeji/winresizer'
  use {
    "dstein64/vim-startuptime",
    cmd = "StartupTime",
  }
  use { 'pechorin/any-jump.vim', cmd = { "AnyJump", "AnyJumpVisual" } }
  -- Find and replace
  use "windwp/nvim-spectre"

  -- Look & Feel
  use { 'stevearc/dressing.nvim' } -- overrides the default vim input to provide better visuals
  use 'rcarriga/nvim-notify'

  use {
    'nvim-lualine/lualine.nvim',
    requires = {
      { 'kyazdani42/nvim-web-devicons', opt = true }
    }
  }
  use 'kyazdani42/nvim-web-devicons'
  use 'romgrk/barbar.nvim'
  use 'karb94/neoscroll.nvim'
  use 'machakann/vim-highlightedyank'
  use 'mhinz/vim-startify'
  use 'vim-scripts/CursorLineCurrentWindow'
  use 'p00f/nvim-ts-rainbow'

  -- Themes
  -- use 'drewtempelmeyer/palenight.vim'
  -- use 'joshdick/onedark.vim'
  -- use 'ghifarit53/tokyonight-vim'
  -- use { 'dracula/vim', as = 'dracula' }
  -- use 'jacoborus/tender.vim'
  -- use 'ellisonleao/gruvbox.nvim'
  use 'ellisonleao/gruvbox.nvim'
  -- use { 'luisiacc/gruvbox-baby', branch = 'main' }


  -- Text Manipulation
  use 'tpope/vim-repeat'
  use 'tpope/vim-surround'
  use 'tpope/vim-commentary'
  use 'JoosepAlviste/nvim-ts-context-commentstring'
  use 'junegunn/vim-easy-align'
  use 'AndrewRadev/switch.vim'
  use 'justinmk/vim-sneak'
  use 'tommcdo/vim-lister' -- Qfilter and Qgrep on Quickfix
  use { 'alvan/vim-closetag', ft = { "html", "javascript" } }
  use 'editorconfig/editorconfig-vim'

  -- Devicons is last so it can support all of the other plugins
  use 'ryanoasis/vim-devicons'

end)
