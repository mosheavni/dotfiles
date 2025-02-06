---@diagnostic disable: missing-fields
vim.g.mapleader = ' '
local temp_dir = vim.uv.os_getenv 'TEMP' or '/tmp'
local package_root = vim.fs.joinpath(temp_dir, 'nvim', 'site', 'lazy')
local lazypath = vim.fs.joinpath(temp_dir, 'nvim', 'site') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  vim
    .system({
      'git',
      'clone',
      '--filter=blob:none',
      '--single-branch',
      'https://github.com/folke/lazy.nvim.git',
      lazypath,
    }, { text = true })
    :wait()
end
vim.opt.runtimepath:prepend(lazypath)

_G.load_config = function()
  vim.lsp.set_log_level 'trace'
  require('vim.lsp.log').set_format_func(vim.inspect)
  local nvim_lsp = require 'lspconfig'

  local on_attach_aug = vim.api.nvim_create_augroup('UserLspAttach', { clear = true })
  vim.api.nvim_create_autocmd('LspAttach', {
    group = on_attach_aug,
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      local bufnr = ev.buf
      print('On Attach ' .. client.name)

      if client:supports_method 'textDocument/completion' then
        -- Enable auto-completion
        vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
      end
    end,
  })

  -- load treesitter
  require('nvim-treesitter.configs').setup {
    highlight = { enable = true },
  }

  nvim_lsp['terraformls'].setup {}
  nvim_lsp['lua_ls'].setup {}

  print [[You can find your log at $HOME/.cache/nvim/lsp.log. Please paste in a github issue under a details tag as described in the issue template.]]
end

require('lazy').setup({
  'habamax/vim-habamax',
  'neovim/nvim-lspconfig',
  {
    'nvim-treesitter/nvim-treesitter',
    config = function()
      local configs = require 'nvim-treesitter.configs'
      configs.setup {
        ensure_installed = {
          'bash',
          'comment',
          'diff',
          'embedded_template',
          'javascript',
          'json',
          'lua',
          'luadoc',
          'markdown',
          'markdown_inline',
          'python',
          'query',
          'regex',
          'terraform',
          'tsx',
          'typescript',
          'vim',
          'vimdoc',
          'xml',
          'yaml',
        },
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
      }
    end,
  },
  {
    'ibhagwan/fzf-lua',
    keys = {
      { '<c-p>', ':FzfLua files<cr>', silent = true },
      { '<c-b>', ':FzfLua buffers<cr>', silent = true },
      { '<leader>ee', ':FzfLua builtin<cr>', silent = true },
      { '<leader>hh', ':FzfLua help_tags<cr>', silent = true },
      { '<leader>i', ':FzfLua oldfiles<cr>', silent = true },
      {
        '<leader>/',
        function()
          require('fzf-lua').live_grep {
            multiprocess = true,
            rg_opts = [=[--column --line-number --hidden --no-heading --color=always --smart-case --max-columns=4096 -g '!.git' -e]=],
          }
        end,
      },
    },
    opts = {

      'default-title',
      files = { git_icons = true },
      oldfiles = { cwd_only = true, include_current_session = true },
      grep = { hidden = true },
      keymap = { fzf = { ['ctrl-q'] = 'select-all+accept' } },
    },
  },
}, {
  root = package_root,
})
_G.load_config()

vim.cmd [[colorscheme habamax]]
