vim.pack.add {
  { src = 'https://github.com/rose-pine/neovim', name = 'rose-pine' },
  'https://github.com/nvim-tree/nvim-web-devicons',
  'https://github.com/eero-lehtinen/oklch-color-picker.nvim',
  'https://github.com/luukvbaal/statuscol.nvim',
  'https://github.com/kevinhwang91/promise-async',
  'https://github.com/kevinhwang91/nvim-ufo',
  'https://github.com/MeanderingProgrammer/render-markdown.nvim',
}

local M = {}

function M.eager()
  require('rose-pine').setup {
    variant = 'moon',
    styles = {
      bold = true,
      italic = true,
      transparency = true,
    },
    highlight_groups = {
      StatusLine = { fg = 'love', bg = 'love', blend = 10 },
      StatusLineNC = { fg = 'subtle', bg = 'surface' },
    },
  }
  vim.cmd [[colorscheme rose-pine]]
end

function M.deferred()
  require('nvim-web-devicons').setup {
    override_by_extension = {
      hcl = {
        icon = '',
        color = '#7182D0',
        name = 'HCL',
      },
    },
  }
  require('nvim-web-devicons').set_icon_by_filetype { fugitive = 'git' }

  require('oklch-color-picker').setup {
    highlight = { enabled = true },
  }
  vim.keymap.set('n', '<Leader>pc', function()
    require('oklch-color-picker').pick_under_cursor()
  end, { desc = 'Pick color under cursor' })

  local builtin = require 'statuscol.builtin'
  require('statuscol').setup {
    relculright = true,
    segments = {
      { text = { builtin.foldfunc }, click = 'v:lua.ScFa' },
      { text = { '%s' }, click = 'v:lua.ScSa' },
      {
        text = { builtin.lnumfunc, ' ' },
        condition = { true, builtin.not_empty },
        click = 'v:lua.ScLa',
      },
    },
  }

  vim.o.foldcolumn = '1'
  vim.o.foldlevel = 99
  vim.o.foldlevelstart = 99
  vim.o.foldenable = true
  vim.o.foldtext = 'v:lua.vim.lsp.foldtext()'

  require('ufo').setup { open_fold_hl_timeout = 0 }
  vim.keymap.set('n', '<leader>fo', function()
    require('ufo').openAllFolds()
  end, { desc = 'Open all folds' })
  vim.keymap.set('n', '<leader>fc', function()
    require('ufo').closeAllFolds()
  end, { desc = 'Close all folds' })
  vim.keymap.set('n', '<leader>fp', function()
    require('ufo').peekFoldedLinesUnderCursor()
  end, { desc = 'Peek folded lines' })

  require('render-markdown').setup {
    file_types = { 'markdown', 'Avante', 'AgenticChat' },
  }
end

return M
