vim.pack.add { 'https://github.com/mfussenegger/nvim-lint' }

return function()
  require('user.lint').setup()
end
