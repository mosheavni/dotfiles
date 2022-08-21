-- Install packer
local install_path = vim.fn.stdpath 'data' .. '/site/pack/packer/start/packer.nvim'

if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  vim.fn.execute('!git clone https://github.com/wbthomason/packer.nvim ' .. install_path)
end
local packer = require 'packer'
packer.init {
  max_jobs = 10,
}
return packer.startup(function(use)
  -- Infrastructure
  use 'wbthomason/packer.nvim'
  use 'lewis6991/impatient.nvim'
  use 'nvim-lua/plenary.nvim'

  -- Project Drawer
  -- use { 'preservim/nerdtree', cmd = { 'NERDTreeToggle' } }
  -- use { 'Xuyuanp/nerdtree-git-plugin', cmd = { 'NERDTreeToggle' } }
  use {
    'kyazdani42/nvim-tree.lua',
    requires = {
      'kyazdani42/nvim-web-devicons', -- optional, for file icon
    },
    tag = 'nightly', -- optional, updated every week. (see issue #1193)
  }

  -- Git Related
  use {
    'lewis6991/gitsigns.nvim',
    tag = 'release', -- To use the latest release
  }
  use { 'mosheavni/vim-to-github', cmd = { 'ToGithub' } }
  use 'tpope/vim-fugitive'
  use { 'akinsho/git-conflict.nvim' }
  use { 'tpope/vim-rhubarb' }

  -- Documents
  use 'nanotee/luv-vimdocs'
  use 'milisims/nvim-luaref'

  -- Fuzzy Search
  use {
    'nvim-telescope/telescope.nvim',
    requires = {
      { 'nvim-lua/plenary.nvim' },
      { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
      { 'nvim-telescope/telescope-project.nvim' },
    },
  }

  -- LSP, Completion and Language
  -- Tree Sitter
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
  }
  use 'p00f/nvim-ts-rainbow'
  use 'JoosepAlviste/nvim-ts-context-commentstring'
  use {
    'SmiteshP/nvim-navic',
    requires = 'neovim/nvim-lspconfig',
  }
  use {
    'cuducos/yaml.nvim',
    ft = { 'yaml' }, -- optional
    requires = {
      'nvim-treesitter/nvim-treesitter',
    },
  }
  use 'lewis6991/nvim-treesitter-context'
  use 'nvim-treesitter/nvim-treesitter-refactor'
  -- LSP
  use {
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',
    'neovim/nvim-lspconfig',
  }
  use {
    'ray-x/lsp_signature.nvim', -- Show function signature when you type
    'lukas-reineke/lsp-format.nvim',
    'jose-elias-alvarez/null-ls.nvim',
    { 'b0o/SchemaStore.nvim' },
    'folke/lsp-colors.nvim',
    'nvim-lua/lsp-status.nvim',
    'j-hui/fidget.nvim',
    'nanotee/nvim-lsp-basics',
  }
  use {
    'kosayoda/nvim-lightbulb',
    requires = 'antoinemadec/FixCursorHold.nvim',
  }
  use {
    'folke/trouble.nvim',
    requires = 'kyazdani42/nvim-web-devicons',
  }
  use {
    'ray-x/navigator.lua',
    requires = {
      { 'ray-x/guihua.lua', run = 'cd lua/fzy && make' },
      { 'neovim/nvim-lspconfig' },
    },
  }
  use {
    'hrsh7th/nvim-cmp', -- auto completion
    requires = {
      'hrsh7th/cmp-nvim-lsp',
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      { 'hrsh7th/cmp-nvim-lua', ft = { 'lua' } },
      'hrsh7th/cmp-cmdline',
      'onsails/lspkind-nvim', -- show pictograms in the auto complete popup
      { 'tzachar/cmp-tabnine', run = './install.sh' },
      'windwp/nvim-autopairs',
      'hrsh7th/cmp-nvim-lsp-document-symbol',
      'vappolinario/cmp-clippy',
    },
  }
  -- Github's suggeetsions engine
  use {
    'github/copilot.vim', -- for initial login
    -- {
    --   'zbirenbaum/copilot.lua',
    --   event = { 'VimEnter' },
    --   config = function()
    --     vim.defer_fn(function()
    --       require('copilot').setup()
    --     end, 100)
    --   end,
    -- },
    -- { 'zbirenbaum/copilot-cmp', after = { 'copilot.lua', 'nvim-cmp' } },
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
  use { 'jose-elias-alvarez/nvim-lsp-ts-utils' }
  use { 'vim-scripts/groovyindent-unix', ft = { 'groovy', 'Jenkinsfile' } }
  use { 'martinda/Jenkinsfile-vim-syntax', ft = { 'groovy', 'Jenkinsfile' } }
  use { 'chr4/nginx.vim', ft = { 'nginx' } }
  use { 'mosheavni/vim-kubernetes', ft = { 'yaml' } }
  use { 'towolf/vim-helm', ft = { 'yaml', 'yaml.gotexttmpl' } }
  use { 'mogelbrod/vim-jsonpath', ft = { 'json' } }
  use { 'chrisbra/vim-sh-indent', ft = { 'sh', 'bash', 'zsh' } }
  use { 'phenomenes/ansible-snippets', ft = { 'yaml' } }
  use { 'rafamadriz/friendly-snippets' } -- snippets for many languages
  use { 'folke/lua-dev.nvim' }

  -- Debug Adapter Protocol (DAP)
  use {
    'mfussenegger/nvim-dap',
    'rcarriga/nvim-dap-ui',
    'mfussenegger/nvim-dap-python',
    'nvim-telescope/telescope-dap.nvim',
    'mxsdev/nvim-dap-vscode-js',
    'theHamsta/nvim-dap-virtual-text',
    'rcarriga/cmp-dap',
    'Pocco81/dap-buddy.nvim',
  }
  use 'andrewferrier/debugprint.nvim'

  -- Functionality Tools
  use 'christoomey/vim-system-copy'
  use 'danro/rename.vim'
  use 'voldikss/vim-floaterm'
  use { 'mosheavni/vim-dirdiff', cmd = { 'DirDiff' } }
  use 'simeji/winresizer'
  use 'tiagovla/scope.nvim'
  use {
    'dstein64/vim-startuptime',
    cmd = 'StartupTime',
  }
  use { 'pechorin/any-jump.vim', cmd = { 'AnyJump', 'AnyJumpVisual' } }
  use {
    'anuvyklack/fold-preview.nvim',
    requires = 'anuvyklack/keymap-amend.nvim',
  }
  use 'kazhala/close-buffers.nvim'

  -- Find and replace
  use 'windwp/nvim-spectre'
  use { 'folke/which-key.nvim' }
  use { 'sindrets/diffview.nvim', requires = 'nvim-lua/plenary.nvim' }

  -- Look & Feel
  use { 'stevearc/dressing.nvim' } -- overrides the default vim input to provide better visuals
  use 'rcarriga/nvim-notify'
  use 'lukas-reineke/indent-blankline.nvim'
  use { 'akinsho/bufferline.nvim', tag = 'v2.*', requires = 'kyazdani42/nvim-web-devicons' }
  use 'https://gitlab.com/yorickpeterse/nvim-pqf.git'
  use 'RRethy/vim-illuminate'

  use {
    'nvim-lualine/lualine.nvim',
    requires = {
      { 'kyazdani42/nvim-web-devicons', opt = true },
    },
  }
  use 'kyazdani42/nvim-web-devicons'
  use 'karb94/neoscroll.nvim'
  use 'machakann/vim-highlightedyank'
  use 'mhinz/vim-startify'
  use 'vim-scripts/CursorLineCurrentWindow'
  use 'norcalli/nvim-colorizer.lua'

  -- Themes
  -- use 'drewtempelmeyer/palenight.vim'
  -- use 'joshdick/onedark.vim'
  -- use 'ghifarit53/tokyonight-vim'
  -- use { 'dracula/vim', as = 'dracula' }
  -- use 'jacoborus/tender.vim'
  -- use 'ellisonleao/gruvbox.nvim'
  use 'ellisonleao/gruvbox.nvim'
  use 'rafamadriz/neon'
  use 'marko-cerovac/material.nvim'
  use 'folke/tokyonight.nvim'
  -- use { 'luisiacc/gruvbox-baby', branch = 'main' }

  -- Text Manipulation
  use 'tpope/vim-repeat'
  use 'tpope/vim-surround'
  use { 'numToStr/Comment.nvim' }
  use 'junegunn/vim-easy-align'
  use 'AndrewRadev/switch.vim'
  use 'justinmk/vim-sneak'
  use 'tommcdo/vim-lister' -- Qfilter and Qgrep on Quickfix
  use { 'alvan/vim-closetag', ft = { 'html', 'javascript' } }
  use 'editorconfig/editorconfig-vim'

  -- Devicons is last so it can support all of the other plugins
  use 'ryanoasis/vim-devicons'

  local custom_settings_ok, custom_settings = pcall(require, 'user.custom-settings')
  if custom_settings_ok then
    custom_settings.plugins(use)
  end
end)
