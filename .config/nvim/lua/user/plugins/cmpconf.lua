local cmp = require 'cmp'
local luasnip = require 'luasnip'
local lspkind = require 'lspkind'
local compare = require 'cmp.config.compare'
local tabnine = require 'cmp_tabnine.config'
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
    if luasnip.expand_or_jumpable() then
      luasnip.expand_or_jump()
    elseif cmp.visible() then
      cmp.select_next_item()
    elseif has_words_before() then
      cmp.complete()
    else
      fallback()
    end
  end, { 'i', 's' }),
  ['<C-k>'] = cmp.mapping(function(fallback)
    if luasnip.jumpable(-1) then
      luasnip.jump(-1)
    elseif cmp.visible() then
      cmp.select_prev_item()
    else
      fallback()
    end
  end, { 'i', 's' }),
  ['<C-y>'] = cmp.mapping.confirm { behavior = cmp.ConfirmBehavior.Insert, select = true },
  ['<CR>'] = cmp.mapping.confirm {
    behavior = cmp.ConfirmBehavior.Replace,
    select = true,
  },
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
  git = '[Git]',
}

cmp.setup {
  -- enabled = function()
  --   return vim.api.nvim_buf_get_option(0, 'buftype') ~= 'prompt' or require('cmp_dap').is_dap_buffer()
  -- end,
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
        vim_item.menu = source_mapping[entry.source.name]
        if entry.source.name == 'cmp_tabnine' then
          local detail = (entry.completion_item.data or {}).detail
          vim_item.kind = ''
          if detail and detail:find '.*%%.*' then
            vim_item.kind = vim_item.kind .. ' ' .. detail
          end

          if (entry.completion_item.data or {}).multiline then
            vim_item.kind = vim_item.kind .. ' ' .. '[ML]'
          end
        end

        local maxwidth = 80
        vim_item.abbr = string.sub(vim_item.abbr, 1, maxwidth)
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
      luasnip.lsp_expand(args.body)
    end,
  },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
}

cmp.setup.filetype('gitcommit', {
  sources = cmp.config.sources({
    { name = 'git' },
  }, {
    { name = 'buffer' },
  }),
})
require('cmp_git').setup()

tabnine:setup {
  max_lines = 500,
  max_num_results = 5,
  sort = true,
}

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
  enable_check_bracket_line = false,
  disable_in_macro = true,
  disable_filetype = { 'TelescopePrompt', 'guihua', 'guihua_rust', 'clap_input' },
}
-- If you want insert `(` after select function or method item
local cmp_autopairs = require 'nvim-autopairs.completion.cmp'
cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done { map_char = { tex = '' } })

require('luasnip.loaders.from_vscode').lazy_load()
require('luasnip.loaders.from_snipmate').lazy_load()
