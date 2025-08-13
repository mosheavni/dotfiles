---@diagnostic disable: missing-fields
local M = {
  'hrsh7th/nvim-cmp',
  version = false, -- last release is way too old
  event = { 'InsertEnter', 'CmdlineEnter' },
  dependencies = {
    'rafamadriz/friendly-snippets',
    { 'L3MON4D3/LuaSnip', build = 'make install_jsregexp' },
    'saadparwaiz1/cmp_luasnip',
    'onsails/lspkind-nvim',
    { 'tzachar/cmp-tabnine', build = './install.sh' },
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-calc',
    'hrsh7th/cmp-cmdline',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-path',
    'petertriho/cmp-git',
    'hrsh7th/cmp-nvim-lsp-signature-help',
  },
}

M.config = function()
  local cmp = require 'cmp'
  local luasnip = require 'luasnip'
  local compare = require 'cmp.config.compare'
  local tabnine = require 'cmp_tabnine.config'
  local has_words_before = function()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match '%s' == nil
  end

  local source_mapping = {
    buffer = '[Buffer]',
    cmdline = '[Cmd]',
    cmp_tabnine = '[TN]',
    copilot = '[CP]',
    git = '[Git]',
    luasnip = '[Snpt]',
    nvim_lsp = '[LSP]',
    path = '[Path]',
    calc = '[Calc]',
    ['vim-dadbod-completion'] = '[DB]',
  }
  local custom_kinds = {
    TabNine = '',
  }

  -- custom highlights
  local custom_kinds_hl = {}
  vim.api.nvim_set_hl(0, 'CmpItemKindTabNine', { link = 'Green' })
  cmp.setup {
    enabled = function()
      local ft = vim.api.nvim_get_option_value('filetype', { buf = 0 })
      if string.find(ft, 'k8s_') then
        return false
      end
      return true
    end,
    native_menu = false,
    view = {
      entries = {
        follow_cursor = true,
      },
    },
    formatting = {
      fields = { 'kind', 'abbr', 'menu' },
      format = function(entry, vim_item)
        local lspkind = require 'lspkind'
        local mode = 'symbol'
        local preset = 'default'
        lspkind.symbol_map = vim.tbl_extend('force', lspkind.presets[preset], custom_kinds)
        if custom_kinds_hl[vim_item.kind] then
          vim_item.kind_hl_group = custom_kinds_hl[vim_item.kind]
        end
        vim_item.kind = lspkind.symbolic(vim_item.kind, { mode = mode })
        vim_item.menu = source_mapping[entry.source.name]
        if entry.source.name == 'cmp_tabnine' then
          local detail = (entry.completion_item.labelDetails or {}).detail
          if detail and detail:find '.*%%.*' then
            vim_item.menu = vim_item.menu .. ' ' .. detail
          end

          if (entry.completion_item.data or {}).multiline then
            vim_item.kind = vim_item.kind .. ' ' .. '[ML]'
          end
        end
        return vim_item
      end,
    },
    mapping = cmp.mapping.preset.insert {
      [vim.env.CMP_COMPLETION or '<M-Space>'] = cmp.mapping.complete(),
      ['<C-d>'] = cmp.mapping.scroll_docs(4),
      ['<C-u>'] = cmp.mapping.scroll_docs(-4),
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
      ['<CR>'] = cmp.mapping.confirm { behavior = cmp.ConfirmBehavior.Replace, select = false },
      ['<Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
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
      ['<C-/>'] = cmp.mapping.abort(),
      ['<C-e>'] = cmp.mapping(function(fallback)
        if luasnip.choice_active() then
          luasnip.change_choice(1)
        else
          fallback()
        end
      end, { 'i', 's' }),
    },
    sorting = {
      priority_weight = 2,
      comparators = {
        compare.offset,
        compare.exact,
        compare.score,
        compare.recently_used,
        compare.kind,
        compare.sort_text,
        compare.length,
        compare.order,
        require 'cmp_tabnine.compare',
      },
    },
    sources = cmp.config.sources {
      { name = 'nvim_lsp_signature_help', priority = 101 },
      { name = 'nvim_lsp', priority = 100 },
      { name = 'luasnip' },
      {
        name = 'lazydev',
        group_index = 0, -- set group index to 0 to skip loading LuaLS completions
      },
      { name = 'cmp_tabnine' },
      { name = 'path' },
      { name = 'buffer', keyword_length = 4 },
      { name = 'calc' },
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

  cmp.setup.filetype({ 'gitcommit', 'octo' }, {
    sources = cmp.config.sources({
      { name = 'git' },
    }, {
      { name = 'buffer' },
    }),
  })
  require('cmp_git').setup()

  local db_fts = { 'sql', 'mysql', 'plsql' }
  for _, ft in ipairs(db_fts) do
    cmp.setup.filetype(ft, {
      sources = cmp.config.sources {
        {
          name = 'vim-dadbod-completion',
          trigger_character = { '.', '"', '`', '[' },
        },
      },
    })
  end

  tabnine:setup {
    max_lines = 500,
    max_num_results = 5,
    sort = true,
  }

  -- `/` cmdline setup.
  cmp.setup.cmdline('/', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = 'buffer' },
    },
  })

  -- `:` cmdline setup.
  cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = 'path' },
    }, {
      { name = 'cmdline' },
    }),
  })

  local cmp_autopairs = require 'nvim-autopairs.completion.cmp'
  cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())

  require('luasnip.loaders.from_vscode').lazy_load()
  require('luasnip.loaders.from_vscode').lazy_load { paths = '~/.config/nvim/snippets' }
end

return M
