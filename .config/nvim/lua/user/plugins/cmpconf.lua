local cmp = require 'cmp'
local luasnip = require 'luasnip'
local lspkind = require 'lspkind'
local compare = require 'cmp.config.compare'
local tabnine = require 'cmp_tabnine'
local has_words_before = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match '%s' == nil
end

local cmp_mappings = {
  ['<C-Space>'] = cmp.mapping.complete(),
  ['<C-b>'] = cmp.mapping.scroll_docs(-4),
  ['<C-e>'] = cmp.mapping.abort(),
  ['<C-f>'] = cmp.mapping.scroll_docs(4),
  ['<C-j>'] = cmp.mapping(function(fallback)
    if cmp.visible() then
      cmp.select_next_item()
    elseif luasnip.expand_or_jumpable() then
      luasnip.expand_or_jump()
    elseif has_words_before() then
      cmp.complete()
    else
      fallback()
    end
  end, { 'i', 's' }),
  ['<C-k>'] = cmp.mapping(function(fallback)
    if cmp.visible() then
      cmp.select_prev_item()
    elseif luasnip.jumpable(-1) then
      luasnip.jump(-1)
    else
      fallback()
    end
  end, { 'i', 's' }),
  ['<C-y>'] = cmp.mapping.confirm { behavior = cmp.ConfirmBehavior.Insert, select = true },
  ['<CR>'] = cmp.mapping.confirm { select = false },
  ['<Tab>'] = cmp.mapping(function(fallback)
    if cmp.visible() then
      cmp.select_next_item()
      -- elseif luasnip.expand_or_jumpable() then
      --   luasnip.expand_or_jump()
    elseif has_words_before() then
      cmp.complete()
    else
      fallback()
    end
  end, { 'i', 's' }),
  ['<S-Tab>'] = cmp.mapping(function(fallback)
    if cmp.visible() then
      cmp.select_prev_item()
    elseif luasnip.jumpable(-1) then
      luasnip.jump(-1)
    else
      fallback()
    end
  end, { 'i', 's' }),
}

local source_mapping = {
  nvim_lsp = '[LSP]',
  luasnip = '[Snpt]',
  treesitter = '[TS]',
  cmp_tabnine = '[TN]',
  nvim_lua = '[Vim]',
  path = '[Path]',
  buffer = '[Buffer]',
  copilot = '[CP]',
}

local config = {
  native_menu = false,
  formatting = {
    format = lspkind.cmp_format {
      mode = 'symbol_text', -- options: 'text', 'text_symbol', 'symbol_text', 'symbol'
      preset = 'codicons',
      maxwidth = 40, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)

      -- The function below will be called before any actual modifications from lspkind
      -- so that you can provide more controls on popup customization. (See [#30](https://github.com/onsails/lspkind-nvim/pull/30))
      before = function(entry, vim_item)
        vim_item.kind = lspkind.presets.default[vim_item.kind]

        local menu = source_mapping[entry.source.name]
        if entry.source.name == 'cmp_tabnine' then
          if entry.completion_item.data ~= nil and entry.completion_item.data.detail ~= nil then
            menu = entry.completion_item.data.detail .. ' ' .. menu
          end
          vim_item.kind = ''
        end

        vim_item.menu = menu

        return vim_item
      end,
    },
  },
  mapping = cmp.mapping.preset.insert(cmp_mappings),
  sorting = {
    priority_weight = 2,
    comparators = {
      require 'cmp_tabnine.compare',
      compare.offset,
      compare.exact,
      compare.score,
      compare.recently_used,
      compare.kind,
      compare.sort_text,
      compare.length,
      compare.order,
    },
  },
  sources = cmp.config.sources {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'cmp_tabnine', priority = 80 },
    { name = 'path' },
    { name = 'nvim_lsp_signature_help' },
    { name = 'nvim_lsp_document_symbol' },
    { name = 'buffer', keyword_length = 4 },
  },
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body) -- For `luasnip` users.
    end,
  },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
}

tabnine:setup {
  max_lines = 500,
  max_num_results = 5,
  sort = true,
}

cmp.setup(config)
cmp.setup.filetype({ 'dap-repl', 'dapui_watches' }, {
  sources = {
    { name = 'dap' },
  },
})

-- -- `/` cmdline setup.
-- cmp.setup.cmdline('/', {
--   mapping = cmp.mapping.preset.cmdline(),
--   sources = {
--     { name = 'buffer' },
--   },
-- })
--
-- -- `:` cmdline setup.
-- cmp.setup.cmdline(':', {
--   mapping = cmp.mapping.preset.cmdline(),
--   sources = cmp.config.sources({
--     { name = 'path' },
--   }, {
--     { name = 'cmdline' },
--   }),
-- })

require('nvim-autopairs').setup {
  check_ts = true, -- treesitter integration
  disable_in_macro = true,
  disable_filetype = { 'TelescopePrompt', 'guihua', 'guihua_rust', 'clap_input' },
}
-- If you want insert `(` after select function or method item
local cmp_autopairs = require 'nvim-autopairs.completion.cmp'
cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done { map_char = { tex = '' } })

require('luasnip.loaders.from_vscode').lazy_load()
require('luasnip.loaders.from_snipmate').lazy_load()
