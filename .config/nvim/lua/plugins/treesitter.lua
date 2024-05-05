local actions = function()
  return {
    ['Incremental Selection (vn)'] = function()
      vim.fn.feedkeys 'vn'
    end,

    ['Smart Rename Symbol (grr)'] = function()
      vim.fn.feedkeys 'grr'
    end,
  }
end
local M = {
  'nvim-treesitter/nvim-treesitter',
  build = function()
    pcall(require('nvim-treesitter.install').update { with_sync = true })
  end,
  dependencies = {
    'Afourcat/treesitter-terraform-doc.nvim',
    'nvim-treesitter/nvim-treesitter-context',
    'nvim-treesitter/nvim-treesitter-refactor',
    'nvim-treesitter/nvim-treesitter-textobjects',
    {
      'windwp/nvim-ts-autotag',
      ft = { 'html', 'javascript', 'jsx', 'markdown', 'typescript', 'xml' },
    },
    'RRethy/nvim-treesitter-endwise',
  },
  event = 'BufReadPost',
}

M.opts = {
  ensure_installed = {
    'awk',
    'bash',
    'comment',
    'dockerfile',
    'embedded_template',
    'git_config',
    'gitcommit',
    'gitignore',
    'go',
    'graphql',
    'groovy',
    'hcl',
    'hjson',
    'html',
    'http',
    'java',
    'javascript',
    'json',
    'jsonc',
    'lua',
    'make',
    'markdown',
    'markdown_inline',
    'python',
    'query',
    'regex',
    'scss',
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
  endwise = {
    enable = true,
  },
  autotag = {
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
  textobjects = {
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ['ab'] = '@block.outer',
        ['ib'] = '@block.inner',
        ['ac'] = '@class.outer',
        ['ic'] = '@class.inner',
        ['af'] = '@function.outer',
        ['if'] = '@function.inner',
        ['ao'] = '@object.outer',
        ['io'] = '@object.inner',
      },
    },
    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
      goto_next_start = {
        [']m'] = '@function.outer',
        [']]'] = '@block.outer',
      },
      goto_next_end = {
        [']M'] = '@function.outer',
        [']['] = '@block.outer',
      },
      goto_previous_start = {
        ['[m'] = '@function.outer',
        ['[['] = '@class.outer',
      },
      goto_previous_end = {
        ['[M'] = '@function.outer',
        ['[]'] = '@block.outer',
      },
    },
  },
  refactor = {
    highlight_current_scope = { enable = false },
    smart_rename = {
      enable = true,
      keymaps = {
        smart_rename = 'grr',
      },
    },
    highlight_definitions = {
      enable = true,
      clear_on_cursor_move = true,
    },
  },
}

M.config = function(_, opts)
  require('user.menu').add_actions('TreeSitter', actions())
  local parser_config = require('nvim-treesitter.parsers').get_parser_configs()
  ---@diagnostic disable-next-line: inject-field
  parser_config.gotmpl = {
    install_info = {
      url = 'https://github.com/ngalaiko/tree-sitter-go-template',
      files = { 'src/parser.c' },
    },
    filetype = 'gotmpl',
    used_by = { 'gohtmltmpl', 'gotexttmpl', 'gotmpl' },
  }

  ---@diagnostic disable-next-line: missing-fields
  require('nvim-treesitter.configs').setup(opts)

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
