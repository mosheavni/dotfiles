local pack = require 'user.pack.add'
pack.add {
  'https://github.com/saghen/blink.download',
  { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range '1.x' },
  'https://github.com/L3MON4D3/LuaSnip',
  'https://github.com/rafamadriz/friendly-snippets',
}

return function()
  require('luasnip.loaders.from_vscode').lazy_load()
  require('luasnip.loaders.from_vscode').lazy_load { paths = '~/.config/nvim/snippets' }

  require('blink.cmp').setup {
    keymap = {
      preset = 'default',
      [vim.env.CMP_COMPLETION or '<M-Space>'] = { 'show', 'show_documentation', 'hide_documentation' },
      ['<Tab>'] = {
        'select_next',
        function(cmp)
          local line, col = unpack(vim.api.nvim_win_get_cursor(0))
          if col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match '%s' == nil then
            cmp.show()
            return true
          end
        end,
        'fallback',
      },
      ['<S-Tab>'] = { 'select_prev', 'fallback' },
      ['<C-j>'] = { 'snippet_forward', 'fallback' },
      ['<C-k>'] = { 'snippet_backward', 'show_signature', 'hide_signature', 'fallback' },
      ['<CR>'] = { 'accept', 'fallback' },
      ['<C-u>'] = { 'scroll_signature_up', 'fallback' },
      ['<C-d>'] = { 'scroll_signature_down', 'fallback' },
    },
    cmdline = {
      completion = {
        menu = { auto_show = true },
        list = { selection = { preselect = false } },
      },
    },
    signature = { enabled = true },
    appearance = { nerd_font_variant = 'normal' },
    completion = {
      menu = {
        draw = {
          columns = { { 'kind_icon' }, { 'label', 'label_description', gap = 1 }, { 'source_name' } },
        },
      },
      accept = { auto_brackets = { enabled = true } },
      documentation = { auto_show = true },
      list = { selection = { preselect = false, auto_insert = true } },
    },
    snippets = { preset = 'luasnip' },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
      per_filetype = {
        lua = { inherit_defaults = true, 'lazydev' },
      },
      providers = {
        lazydev = { name = 'LazyDev', module = 'lazydev.integrations.blink' },
      },
    },
    fuzzy = { implementation = 'prefer_rust_with_warning' },
  }
end
