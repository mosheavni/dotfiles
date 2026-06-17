vim.pack.add {
  'https://github.com/nvim-mini/mini.notify',
  'https://github.com/nvim-mini/mini.indentscope',
  'https://github.com/nvim-mini/mini.cursorword',
  'https://github.com/nvim-mini/mini.hipatterns',
  'https://github.com/nvim-mini/mini.splitjoin',
  'https://github.com/nvim-mini/mini.surround',
  'https://github.com/nvim-mini/mini.ai',
  'https://github.com/nvim-mini/mini.operators',
}

local M = {}

function M.eager()
  require('mini.notify').setup { lsp_progress = { enable = false } }
  vim.keymap.set('n', '<leader>x', function()
    require('mini.notify').clear()
  end, { silent = true, desc = 'Dismiss all notifications' })
  vim.keymap.set('n', '<leader>n', function()
    vim.cmd 'tabnew'
    require('mini.notify').show_history()
  end, { silent = true, desc = 'Show notifications history' })
end

function M.deferred()
  vim.api.nvim_create_autocmd('FileType', {
    pattern = {
      'Trouble',
      'dashboard',
      'floaterm',
      'fugitive',
      'help',
      'input',
      'mason',
      'notify',
      'pack-float',
      'trouble',
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

  require('mini.indentscope').setup {
    symbol = '│',
    options = { try_as_border = true },
  }
  vim.api.nvim_set_hl(0, 'MiniIndentscopeSymbol', { fg = '#76D1A3' })

  require('mini.cursorword').setup {}
  vim.cmd [[
    highlight clear CursorWord
    highlight CurrentWord gui=underline,bold cterm=underline,bold
  ]]

  local hipatterns = require 'mini.hipatterns'
  hipatterns.setup {
    highlighters = {
      hiri = { pattern = '%f[%w]()hiri()%f[%W]', group = 'MiniHipatternsFixme' },
      todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsNote' },
      hex_color = hipatterns.gen_highlighter.hex_color(),
    },
  }

  require('mini.splitjoin').setup {}

  require('mini.surround').setup {
    mappings = {
      add = 'ys',
      delete = 'ds',
      find = '',
      find_left = '',
      highlight = '',
      replace = 'cs',
      suffix_last = '',
      suffix_next = '',
    },
    search_method = 'cover_or_next',
  }
  vim.keymap.del('x', 'ys')
  vim.keymap.set('x', 'S', [[:<C-u>lua MiniSurround.add('visual')<CR>]], { silent = true, desc = 'Add surrounding in visual mode' })
  vim.keymap.set('n', 'yss', 'ys_', { remap = true, desc = 'Add surrounding to line' })

  local gen_spec = require('mini.ai').gen_spec
  require('mini.ai').setup {
    n_lines = 100,
    mappings = { around_next = '', inside_next = '' },
    custom_textobjects = {
      F = gen_spec.treesitter { a = '@function.outer', i = '@function.inner' },
      c = gen_spec.treesitter { a = '@comment.outer', i = '@comment.inner' },
    },
  }

  require('mini.operators').setup {
    exchange = { prefix = 'ge' },
    sort = { prefix = '' },
  }
end

return M
