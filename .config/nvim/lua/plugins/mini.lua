local M = {
  {
    'echasnovski/mini.indentscope',
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
          'NvimTree',
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
    'echasnovski/mini.cursorword',
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
    'echasnovski/mini.icons',
    lazy = true,
    opts = {},
    init = function()
      package.preload['nvim-web-devicons'] = function()
        require('mini.icons').mock_nvim_web_devicons()
        return package.loaded['nvim-web-devicons']
      end
    end,
  },
  {
    'echasnovski/mini.hipatterns',
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
    'echasnovski/mini.notify',
    version = false,
    lazy = false,
    keys = {
      { '<leader>x', '<cmd>lua require("mini.notify").clear()<cr>', { silent = true, desc = 'Dismiss all notifications' } },
      { '<leader>n', '<cmd>lua require("mini.notify").show_history()<cr>', { silent = true, desc = 'Show notifications history' } },
    },
    init = function()
      local mnotify = require 'mini.notify'
      mnotify.setup()
      vim.notify = mnotify.make_notify()
    end,
  },
  {
    'echasnovski/mini.splitjoin',
    version = false,
    opts = {},
    keys = { 'gS' },
  },
  {
    'echasnovski/mini.ai',
    version = false,
    config = function()
      local gen_spec = require('mini.ai').gen_spec
      require('mini.ai').setup {
        custom_textobjects = {
          -- Function definition (needs treesitter queries with these captures)
          F = gen_spec.treesitter { a = '@function.outer', i = '@function.inner' },
        },
      }
    end,
  },
  {
    'echasnovski/mini.operators',
    version = false,
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
