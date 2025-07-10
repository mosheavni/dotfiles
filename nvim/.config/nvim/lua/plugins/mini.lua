local the_king = 'echasnovski/mini.'
local M = {
  {
    the_king .. 'indentscope',
    version = false,
    event = 'BufReadPost',
    opts = {
      symbol = '│',
      options = { try_as_border = true },
    },
    config = function(_, opts)
      require('mini.indentscope').setup(opts)
      vim.cmd 'highlight! MiniIndentscopeSymbol ctermfg=109 guifg=#76D1A3'
    end,
    init = function()
      vim.api.nvim_create_autocmd('FileType', {
        pattern = {
          'help',
          'fugitive',
          'dashboard',
          'Trouble',
          'trouble',
          'lazy',
          'mason',
          'notify',
          'floaterm',
          'lazyterm',
        },
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })

      vim.api.nvim_create_autocmd('TermOpen', {
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })
    end,
  },
  {
    the_king .. 'cursorword',
    version = false,
    event = 'BufReadPost',
    config = function()
      require('mini.cursorword').setup {}
      vim.cmd [[
        highlight clear CursorWord
        highlight CurrentWord gui=underline,bold cterm=underline,bold
      ]]
    end,
  },
  {
    the_king .. 'hipatterns',
    version = false,
    event = { 'BufNewFile', 'BufReadPre', 'VeryLazy' },
    config = function()
      local hipatterns = require 'mini.hipatterns'
      hipatterns.setup {
        highlighters = {
          -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
          hiri = { pattern = '%f[%w]()hiri()%f[%W]', group = 'MiniHipatternsFixme' },
          todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsNote' },

          -- Highlight hex color strings (`#rrggbb`) using that color
          hex_color = hipatterns.gen_highlighter.hex_color(),
        },
      }
    end,
  },
  {
    the_king .. 'notify',
    version = false,
    lazy = false,
    keys = {
      { '<leader>x', '<cmd>lua require("mini.notify").clear()<cr>', { silent = true, desc = 'Dismiss all notifications' } },
      { '<leader>n', '<cmd>tabnew|lua require("mini.notify").show_history()<cr>', { silent = true, desc = 'Show notifications history' } },
    },
    init = function()
      local mnotify = require 'mini.notify'
      mnotify.setup {
        lsp_progress = { enable = false },
      }
      vim.notify = mnotify.make_notify()
    end,
  },
  {
    the_king .. 'splitjoin',
    version = false,
    opts = {},
    keys = { 'gS' },
  },
  {
    the_king .. 'surround',
    version = false,
    keys = {
      { 'S', '<cmd>lua MiniSurround.add("visual")<CR>', mode = 'v' },
      { 'yss' },
      { 'ys' },
      { 'ds' },
      { 'cs' },
    },
    opts = {
      mappings = {
        add = 'ys',
        delete = 'ds',
        find = '',
        find_left = '',
        highlight = '',
        replace = 'cs',
        update_n_lines = '',

        -- Add this only if you don't want to use extended mappings
        suffix_last = '',
        suffix_next = '',
      },
      search_method = 'cover_or_next',
    },
    config = function(_, opts)
      require('mini.surround').setup(opts)
      -- Remap adding surrounding to Visual mode selection
      vim.keymap.del('x', 'ys')
      vim.keymap.set('x', 'S', [[:<C-u>lua MiniSurround.add('visual')<CR>]], { silent = true })

      -- Make special mapping for "add surrounding for line"
      vim.keymap.set('n', 'yss', 'ys_', { remap = true })
    end,
  },
  {
    the_king .. 'ai',
    version = false,
    event = 'VeryLazy',
    config = function()
      local gen_spec = require('mini.ai').gen_spec
      require('mini.ai').setup {
        custom_textobjects = {
          -- Function definition (needs treesitter queries with these captures)
          F = gen_spec.treesitter { a = '@function.outer', i = '@function.inner' },
          c = gen_spec.treesitter { a = '@comment.outer', i = '@comment.inner' },
        },
      }
    end,
  },
  {
    the_king .. 'pairs',
    version = false,
    enabled = false, -- use nvim-autopairs instead
    event = 'InsertEnter',
    opts = {
      mappings = {
        ['`'] = { action = 'closeopen', pair = '``', neigh_pattern = '[^\\`].', register = { cr = false } },
      },
    },
  },
  {
    the_king .. 'operators',
    version = false,
    event = 'VeryLazy',
    opts = {
      -- g= Evaluate text and replace with output
      -- gx Exchange text regions
      -- gm Multiply (duplicate) text
      -- gr Replace text with register
      -- gs Sort text
      exchange = {
        prefix = 'ge',
      },
      sort = {
        prefix = '<leader>so',
        func = function(content)
          local lines_extended = vim.tbl_map(function(l)
            local line = l or ''
            local lower = string.lower(line)
            -- Convert number strings to actual numbers for proper sorting
            local num = tonumber(line)
            return { line, num or lower }
          end, content.lines)
          table.sort(lines_extended, function(a, b)
            return a[2] < b[2]
          end)
          return vim.tbl_map(function(x)
            return x[1]
          end, lines_extended)
        end,
      },
    },
  },
}
return M
