vim.pack.add {
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/j-hui/fidget.nvim',
  'https://github.com/folke/lazydev.nvim',
  'https://github.com/DrKJeff16/wezterm-types',
}

return function()
  require('user.lsp.config').setup()

  require('fidget').setup {
    progress = {
      display = {
        progress_icon = { pattern = 'moon', period = 1 },
      },
    },
  }

  require('lazydev').setup {
    library = {
      { path = 'wezterm-types', mods = { 'wezterm' } },
      { path = 'plenary.nvim', words = { 'describe', 'assert' } },
      { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      { path = '${3rd}/busted/library', words = { 'describe', 'it', 'assert' } },
      { path = '${3rd}/luassert/library', words = { 'assert' } },
    },
  }
end
