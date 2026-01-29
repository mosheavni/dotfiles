return {
  cmd = {
    'java',
    '-jar',
    vim.fs.joinpath(vim.fn.stdpath 'data', 'mason', 'packages', 'groovy-language-server', 'build', 'libs', 'groovy-language-server-all.jar'),
  },
}
