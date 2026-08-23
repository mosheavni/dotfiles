vim.pack.add {
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
        k8s_aliases = { 'lsp' },
        k8s_contexts = { 'lsp' },
        k8s_filter = { 'lsp', 'buffer' },
        k8s_namespaces = { 'lsp' },
        lua = { inherit_defaults = true, 'lazydev' },
      },
      providers = {
        lazydev = { name = 'LazyDev', module = 'lazydev.integrations.blink' },
        cmdline = {
          -- For :find/:sfind/:tabfind, blink's completion_type detection comes back
          -- '' (Neovim stops exposing it once a custom 'findfunc' is active -- verified:
          -- identical typing reports 'file_in_path' with findfunc unset, '' with it set).
          -- blink's own item-builder falls back to `newText = current_arg_prefix ..
          -- completion` in that case -- i.e. it literally concatenates instead of
          -- replacing. The insert/replace *ranges* it computes are correct (they span
          -- the whole typed argument); only newText is wrong. Fix newText using the
          -- exact candidate list user/options.lua's findfunc just returned, matched by
          -- index (transform_items runs before blink's own client-side re-fuzzy/re-sort,
          -- so item order still matches getcompletion()).
          --
          -- NB: can't validate the cache by comparing its query text against the typed
          -- argument -- blink constructs the query from its OWN (also '.'-truncated)
          -- keyword-boundary logic, so it calls getcompletion()/findfunc with e.g.
          -- "init." instead of the real "init.lua" (verified live). The candidate list
          -- itself is still correct (fd/matchfuzzy tolerate the truncated query fine);
          -- only the item count need line up, as a staleness guard.
          --
          -- Second, separate bug: AFTER transform_items, blink re-scores/re-sorts every
          -- item itself (completion/list.lua fuzzy()), against a "keyword" extracted the
          -- same '.'-blind way -- for "init.lua" that keyword is just "lua", so the
          -- popup order becomes near-random garbage (verified live: an unrelated
          -- LaunchAgents plist outranked the real init.lua files). A large, rank-derived
          -- score_offset overrides that broken score entirely (verified live: restores
          -- our fd/matchfuzzy order), since blink's Rust scorer adds it on top rather
          -- than gating inclusion by it.
          transform_items = function(ctx, items)
            local cmd = ctx.line:match '^%s*(%a+)'
            if cmd ~= 'find' and cmd ~= 'sfind' and cmd ~= 'tabfind' then
              return items
            end
            local cache = _G.__native_find_cache
            if not cache.result or #cache.result ~= #items then
              return items
            end
            for i, item in ipairs(items) do
              local correct = cache.result[i]
              if correct and item.textEdit then
                item.textEdit.newText = correct
                item.label = correct
                item.filterText = correct
                item.score_offset = (#items - i) * 1000000
              end
            end
            return items
          end,
        },
      },
    },
    fuzzy = { implementation = 'prefer_rust_with_warning' },
  }
end
