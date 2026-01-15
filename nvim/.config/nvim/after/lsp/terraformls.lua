return {
  cmd = { '/Users/Moshe.Avni/.asdf/installs/golang/1.23.2/bin/terraform-ls', 'serve' },
  on_attach = function()
    require('user.terraform-docs').setup {}
    vim.o.commentstring = '# %s'
  end,
}
