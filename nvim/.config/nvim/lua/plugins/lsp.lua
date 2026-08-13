vim.pack.add {
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/j-hui/fidget.nvim',
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
end
