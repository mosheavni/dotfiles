vim.pack.add {
  'https://github.com/folke/lazydev.nvim',
  'https://github.com/DrKJeff16/wezterm-types',
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

return {
  root_markers = {
    '.git',
    '.luacheckrc',
    '.stylua.toml',
    'stylua.toml',
    'selene.toml',
  },
}
