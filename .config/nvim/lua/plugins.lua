return require('packer').startup(function(use)
  -- Infrastructure
  use 'wbthomason/packer.nvim'
  use 'lewis6991/impatient.nvim'
  use 'nvim-lua/plenary.nvim'

  -- Project Drawer
  use { 'preservim/nerdtree', cmd = { 'NERDTreeToggle' } }
  use { 'Xuyuanp/nerdtree-git-plugin', cmd = { 'NERDTreeToggle' } }

  -- Git Related
  use { 'airblade/vim-gitgutter' }
  use { 'tpope/vim-fugitive' }
  use { 'mosheavni/vim-to-github', cmd = { 'ToGithub' } }
  use { 'rhysd/conflict-marker.vim' }
  use { 'tveskag/nvim-blame-line' }

  -- Fuzzy Search
  use {
    'junegunn/fzf',
    dir = '~/.fzf', run = './install --all'
  }
  use { 'junegunn/fzf.vim' }

  -- LSP, Completion and Language
  use 'sheerun/vim-polyglot'
  use { 'neoclide/coc.nvim', branch = 'release' }
  use({
    "iamcco/markdown-preview.nvim",
    run = "cd app && yarn install",
    setup = function() vim.g.mkdp_filetypes = { "markdown" } end,
    cmd = 'MarkdownPreview',
    ft = { "markdown" },
  })
  use { 'vim-scripts/groovyindent-unix', ft = { 'groovy', 'Jenkinsfile' } }
  use { 'chr4/nginx.vim', ft = { 'nginx' } }
  use { 'rayburgemeestre/phpfolding.vim', ft = { 'php' } }
  use { 'andrewstuart/vim-kubernetes', ft = { 'yaml' } }
  use { 'towolf/vim-helm', ft = { 'yaml', 'yaml.gotexttmpl' } }
  use { 'mosheavni/yaml-revealer', ft = { 'yaml' } }
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

  -- Themes
  -- use 'drewtempelmeyer/palenight.vim'
  -- use 'joshdick/onedark.vim'
  -- use 'ghifarit53/tokyonight-vim'
  -- use 'dracula/vim'
  -- use 'jacoborus/tender.vim'
  use 'ellisonleao/gruvbox.nvim'

  -- Text Manipulation
  use 'tpope/vim-repeat'
  use 'tpope/vim-surround'
  use 'tpope/vim-commentary'
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


  -- -- Simple plugins can be specified as strings
  -- use '9mm/vim-closer'

  -- -- Lazy loading:
  -- -- Load on specific commands
  -- use { 'tpope/vim-dispatch', opt = true, cmd = { 'Dispatch', 'Make', 'Focus', 'Start' } }

  -- -- Load on an autocommand event
  -- use { 'andymass/vim-matchup', event = 'VimEnter' }

  -- -- Load on a combination of conditions: specific filetypes or commands
  -- -- Also run code after load (see the "config" key)
  -- use {
  --   'w0rp/ale',
  --   ft = { 'sh', 'zsh', 'bash', 'c', 'cpp', 'cmake', 'html', 'markdown', 'racket', 'vim', 'tex' },
  --   cmd = 'ALEEnable',
  --   config = 'vim.cmd[[ALEEnable]]'
  -- }

  -- -- Plugins can have dependencies on other plugins
  -- use {
  --   'haorenW1025/completion-nvim',
  --   opt = true,
  --   requires = { { 'hrsh7th/vim-vsnip', opt = true }, { 'hrsh7th/vim-vsnip-integ', opt = true } }
  -- }

  -- -- Plugins can also depend on rocks from luarocks.org:
  -- use {
  --   'my/supercoolplugin',
  --   rocks = { 'lpeg', { 'lua-cjson', version = '2.1.0' } }
  -- }

  -- -- You can specify rocks in isolation
  -- use_rocks 'penlight'
  -- use_rocks { 'lua-resty-http', 'lpeg' }

  -- -- Local plugins can be included
  -- use '~/projects/personal/hover.nvim'

  -- -- Plugins can have post-install/update hooks
  -- use { 'iamcco/markdown-preview.nvim', run = 'cd app && yarn install', cmd = 'MarkdownPreview' }

  -- -- Post-install/update hook with neovim command
  -- use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }

  -- -- Post-install/update hook with call of vimscript function with argument
  -- use { 'glacambre/firenvim', run = function() vim.fn['firenvim#install'](0) end }

  -- -- Use specific branch, dependency and run lua file after load
  -- use {
  --   'glepnir/galaxyline.nvim', branch = 'main', config = function() require 'statusline' end,
  --   requires = { 'kyazdani42/nvim-web-devicons' }
  -- }

  -- -- Use dependency and run lua function after load
  -- use {
  --   'lewis6991/gitsigns.nvim', requires = { 'nvim-lua/plenary.nvim' },
  --   config = function() require('gitsigns').setup() end
  -- }

  -- -- You can specify multiple plugins in a single call
  -- use { 'tjdevries/colorbuddy.vim', { 'nvim-treesitter/nvim-treesitter', opt = true } }

  -- -- You can alias plugin names
  -- use { 'dracula/vim', as = 'dracula' }
end)
