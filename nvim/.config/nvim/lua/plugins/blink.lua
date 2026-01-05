return {
  'saghen/blink.cmp',
  enabled = true,
  event = { 'InsertEnter', 'CmdlineEnter' },
  dependencies = {
    'rafamadriz/friendly-snippets',
    -- {
    --   'saghen/blink.compat',
    --   version = '*',
    --   lazy = true,
    --   opts = {
    --     debug = true,
    --     impersonate_nvim_cmp = true,
    --   },
    -- },
    {
      'L3MON4D3/LuaSnip',
      version = 'v2.*',
      build = 'make install_jsregexp',
      config = function()
        require('luasnip.loaders.from_vscode').lazy_load { paths = '~/.config/nvim/snippets' }
      end,
    },
  },

  -- use a release tag to download pre-built binaries
  version = '1.*',

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
    -- 'super-tab' for mappings similar to vscode (tab to accept)
    -- 'enter' for enter to accept
    -- 'none' for no mappings
    --
    -- All presets have the following mappings:
    -- C-space: Open menu or open docs if already open
    -- C-n/C-p or Up/Down: Select next/previous item
    -- C-e: Hide menu
    -- C-k: Toggle signature help (if signature.enabled = true)
    --
    -- See :h blink-cmp-config-keymap for defining your own keymap
    keymap = {
      preset = 'default',
      ['<Tab>'] = {
        'select_next',
        function(cmp)
          local line, col = unpack(vim.api.nvim_win_get_cursor(0))
          if col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match '%s' == nil then
            cmp.show()
            return true
          end
        end,
        'fallback', -- Default Tab behavior
      },
      ['<S-Tab>'] = { 'select_prev', 'fallback' },
      ['<C-j>'] = { 'snippet_forward', 'fallback' },
      ['<C-k>'] = { 'snippet_backward', 'fallback' },
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
      documentation = { auto_show = true },
      list = { selection = { preselect = false, auto_insert = true } },
    },

    snippets = { preset = 'luasnip' },

    -- Default list of enabled providers defined so that you can extend it
    -- elsewhere in your config, without redefining it, due to `opts_extend`
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
  },
  opts_extend = { 'sources.default' },
}
