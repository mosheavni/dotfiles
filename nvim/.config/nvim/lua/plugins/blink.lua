---@diagnostic disable: missing-fields
return {
  {
    'saghen/blink.cmp',
    enabled = false,
    build = 'cargo build --release',
    dependencies = {
      {
        'saghen/blink.compat',
        version = '*',
        lazy = true,
        opts = {},
      },
      {
        'onsails/lspkind-nvim',
        config = function()
          require('lspkind').init {}
        end,
      },
      'rafamadriz/friendly-snippets',
      {
        'tzachar/cmp-tabnine',
        build = './install.sh',
        config = function()
          local tabnine = require 'cmp_tabnine.config'
          tabnine:setup {
            max_lines = 1000,
            max_num_results = 5,
            sort = true,
          }
        end,
      },
      { 'L3MON4D3/LuaSnip', version = 'v2.*', build = 'make install_jsregexp' },
      'hrsh7th/cmp-nvim-lua',
      {
        'zbirenbaum/copilot.lua',
        config = function()
          vim.schedule(function()
            require('copilot').setup {
              copilot_node_command = '/usr/local/bin/node',
              filetypes = { ['*'] = true },
              panel = {
                enabled = true,
                auto_refresh = false,
                keymap = {
                  jump_prev = '[[',
                  jump_next = ']]',
                  accept = '<CR>',
                  refresh = 'gr',
                  open = '<M-l>',
                },
              },
              suggestion = {
                auto_trigger = true,
                keymap = {
                  accept = '<M-Enter>',
                },
              },
            }
          end)
        end,
      },
    },
    event = 'InsertEnter',

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      fuzzy = {
        sorts = {
          'score',
          function()
            require 'cmp_tabnine.compare'
          end,
          'sort_text',
        },
      },

      appearance = {
        use_nvim_cmp_as_default = false,
        nerd_font_variant = 'normal',
      },

      sources = {
        -- adding any nvim-cmp sources here will enable them
        default = { 'cmp_tabnine', 'lsp', 'luasnip', 'path', 'buffer', 'lazydev' },
        -- cmdline = {},
        providers = {
          lsp = { fallbacks = { 'lazydev' } },
          lazydev = { name = 'LazyDev', module = 'lazydev.integrations.blink' },
          nvim_lua = {
            name = 'nvim_lua',
            module = 'blink.compat.source',
          },
          cmp_tabnine = {
            name = 'cmp_tabnine',
            module = 'blink.compat.source',
          },
        },
      },

      completion = {
        accept = {
          -- experimental auto-brackets support
          auto_brackets = { enabled = true },
        },
        ghost_text = { enabled = false },
        menu = {
          draw = {
            treesitter = { 'lsp' },
            columns = { { 'kind_icon', gap = 1, 'label', 'label_description' }, { 'source_name' } },
            components = {
              kind_icon = {
                ellipsis = false,
                text = function(ctx)
                  return require('lspkind').symbolic(ctx.kind, {
                    mode = 'symbol',
                  })
                end,
              },
            },
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
        },
      },

      -- experimental signature help support
      signature = { enabled = true },

      snippets = {
        expand = function(snippet)
          require('luasnip').lsp_expand(snippet)
        end,
        active = function(filter)
          if filter and filter.direction then
            return require('luasnip').jumpable(filter.direction)
          end
          return require('luasnip').in_snippet()
        end,
        jump = function(direction)
          require('luasnip').jump(direction)
        end,
      },

      keymap = {
        preset = 'default',
        ['<CR>'] = { 'select_and_accept', 'fallback' },
        ['<Tab>'] = { 'snippet_forward', 'show', 'select_next', 'fallback' },
        ['<S-Tab>'] = { 'snippet_backward', 'show', 'select_prev', 'fallback' },
        ['<C-y>'] = { 'select_and_accept' },
        ['<C-u>'] = { 'scroll_documentation_up', 'fallback' },
        ['<C-d>'] = { 'scroll_documentation_down', 'fallback' },
        ['<C-/>'] = { 'hide' },
      },
    },
  },
}
