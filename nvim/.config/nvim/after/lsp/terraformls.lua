return {
  on_attach = function()
    require('user.terraform-docs').setup {}
    vim.o.commentstring = '# %s'
  end,
}
