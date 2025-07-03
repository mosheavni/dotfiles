local actions = function()
  return {
    ['Incremental Selection (vn)'] = function()
      vim.fn.feedkeys 'vn'
    end,
  }
end

local M = {
  'nvim-treesitter/nvim-treesitter',
  build = function()
    pcall(require('nvim-treesitter.install').update { with_sync = true })
  end,
  dependencies = {
    'OXY2DEV/markview.nvim',
    'nvim-treesitter/nvim-treesitter-textobjects',
    { 'Afourcat/treesitter-terraform-doc.nvim', ft = 'terraform', cmd = 'OpenDoc' },
    'nvim-treesitter/nvim-treesitter-context',
    { 'folke/ts-comments.nvim', opts = {} },
    {
      'windwp/nvim-ts-autotag',
      ft = { 'html', 'javascript', 'jsx', 'markdown', 'typescript', 'xml', 'markdown' },
      opts = {},
    },
    {
      'atusy/treemonkey.nvim',
      keys = {
        {
          'm',
          function()
            require 'nvim-treesitter.configs'
            ---@diagnostic disable-next-line: missing-fields
            require('treemonkey').select {
              ignore_injections = false,
              action = require('treemonkey.actions').unite_selection,
            }
          end,
          mode = { 'x', 'o' },
        },
      },
    },
  },
  event = 'BufReadPost',
}

M.opts = {
  ensure_installed = {
    'awk',
    'bash',
    'comment',
    'csv',
    'diff',
    'dockerfile',
    'embedded_template',
    'git_config',
    'gitcommit',
    'gitignore',
    'go',
    'gomod',
    'gosum',
    'gotmpl',
    'gowork',
    'graphql',
    'groovy',
    'hcl',
    'helm',
    'hjson',
    'html',
    'http',
    'java',
    'javascript',
    'json',
    'jsonc',
    'lua',
    'luadoc',
    'make',
    'markdown',
    'markdown_inline',
    'python',
    'query',
    'regex',
    'scss',
    'sql',
    'ssh_config',
    'terraform',
    'toml',
    'tsx',
    'typescript',
    'vim',
    'vimdoc',
    'xml',
    'yaml',
  },

  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = 'vn',
      node_incremental = '<CR>',
      scope_incremental = '<S-CR>',
      node_decremental = '<BS>',
    },
  },
  matchup = {
    enable = true,
  },
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
  indent = {
    enable = true,
    disable = { 'yaml' },
  },
}

M.config = function(_, opts)
  require('user.menu').add_actions('TreeSitter', actions())

  ---@diagnostic disable-next-line: missing-fields
  require('nvim-treesitter.configs').setup(opts)
  vim.treesitter.language.register('markdown', 'octo')

  vim.opt.foldmethod = 'expr'
  vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
  local function get_custom_foldtxt_suffix(foldstart)
    local fold_suffix_str = string.format('  %s [%s lines]', '⋯', vim.v.foldend - foldstart + 1)

    return { fold_suffix_str, 'Folded' }
  end

  local function get_custom_foldtext(foldtxt_suffix, foldstart)
    local line = vim.api.nvim_buf_get_lines(0, foldstart - 1, foldstart, false)[1]

    return {
      { line, 'Normal' },
      foldtxt_suffix,
    }
  end

  _G.get_foldtext = function()
    local foldstart = vim.v.foldstart
    local ts_foldtxt = vim.treesitter.foldtext()
    local foldtxt_suffix = get_custom_foldtxt_suffix(foldstart)

    if type(ts_foldtxt) == 'string' then
      return get_custom_foldtext(foldtxt_suffix, foldstart)
    else
      table.insert(ts_foldtxt, foldtxt_suffix)
      return ts_foldtxt
    end
  end

  vim.opt.foldtext = 'v:lua.get_foldtext()'
  -- vim.opt.foldtext = 'v:lua.vim.treesitter.foldtext()'

  -- Treesitter context
  local ts_context = require 'treesitter-context'

  ts_context.setup {
    enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
    throttle = true, -- Throttles plugin updates (may improve performance)
    max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
    patterns = {
      -- Match patterns for TS nodes. These get wrapped to match at word boundaries.
      default = {
        'class',
        'function',
        'method',
        'for', -- These won't appear in the context
        'while',
        'if',
        'def',
        'switch',
        'case',
      },
    },
  }
end

return M
