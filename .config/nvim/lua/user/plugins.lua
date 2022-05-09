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

  -- Fuzzy Search
  -- use {
  --   'junegunn/fzf',
  --   dir = '~/.fzf', run = './install --all'
  -- }
  -- use { 'junegunn/fzf.vim' }
  use {
    'nvim-telescope/telescope.nvim',
    requires = { { 'nvim-lua/plenary.nvim' } }
  }
  use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }


  -- LSP, Completion and Language
  -- Tree Sitter
  use {
    "nvim-treesitter/nvim-treesitter",
    run = ":TSUpdate",
  }
  use {
    "cuducos/yaml.nvim",
    ft = { "yaml" }, -- optional
    requires = {
      "nvim-treesitter/nvim-treesitter",
    },
  }
  use 'lewis6991/nvim-treesitter-context'
  use { 'neoclide/coc.nvim', branch = 'release' }
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
  -- use { 'mosheavni/yaml-revealer', ft = { 'yaml' } }
  use { 'mogelbrod/vim-jsonpath', ft = { 'json' } }
  use { 'chrisbra/vim-sh-indent', ft = { 'sh', 'bash', 'zsh' } }
  use { 'hashivim/vim-terraform', ft = { 'terraform' } }
  use 'honza/vim-snippets'
  use { 'phenomenes/ansible-snippets', ft = { 'yaml' } }

  -- Functionality Tools
  use 'christoomey/vim-system-copy'
  use 'danro/rename.vim'
  use 'voldikss/vim-floaterm'
  use { 'mosheavni/vim-dirdiff', cmd = { 'DirDiff' } }
  use 'simeji/winresizer'

  -- Look & Feel
  use { 'stevearc/dressing.nvim' } -- overrides the default vim input to provide better visuals

  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'kyazdani42/nvim-web-devicons', opt = true }
  }
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
  use 'ellisonleao/gruvbox.nvim'

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

  -- Custom Text Objects
  use 'kana/vim-textobj-user'
  use 'mattn/vim-textobj-url'
  use 'bps/vim-textobj-python'
  use 'rhysd/vim-textobj-anyblock'
  use 'kana/vim-textobj-entire'

  -- Devicons is last so it can support all of the other plugins
  use 'ryanoasis/vim-devicons'

end)