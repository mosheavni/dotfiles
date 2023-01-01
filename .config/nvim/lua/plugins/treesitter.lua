local M = {
  'nvim-treesitter/nvim-treesitter',
  build = function()
    pcall(require('nvim-treesitter.install').update { with_sync = true })
  end,
  dependencies = {
    'nvim-treesitter/nvim-treesitter-textobjects',
    'nvim-treesitter/nvim-treesitter-context',
    'nvim-treesitter/nvim-treesitter-refactor',
    'Afourcat/treesitter-terraform-doc.nvim',
    'p00f/nvim-ts-rainbow',
    { 'cuducos/yaml.nvim', ft = 'yaml' },
  },
  event = 'BufReadPost',
}

M.config = function()
  local configs = require 'nvim-treesitter.configs'
  local ts_parsers = require 'nvim-treesitter.parsers'

  -- unknown filetypes
  local ft_to_parser = ts_parsers.filetype_to_parsername
  ft_to_parser.groovy = 'java'
  local ft_to_lang = ts_parsers.ft_to_lang
  ts_parsers.ft_to_lang = function(ft)
    if ft == 'zsh' then
      return 'bash'
    end
    if ft == 'groovy' then
      return 'java'
    end
    return ft_to_lang(ft)
  end

  configs.setup {
    ensure_installed = {
      'awk',
      'bash',
      'comment',
      'dockerfile',
      'embedded_template',
      'go',
      'hcl',
      'help',
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
      'toml',
      'tsx',
      'typescript',
      'vim',
      'yaml',
    },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = 'gnn',
        scope_incremental = '<CR>',
        -- node_incremental = '<TAB>',
        -- node_decremental = '<S-TAB>',
      },
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
    rainbow = {
      enable = false,
      extended_mode = true, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
      max_file_lines = nil, -- Do not enable for files with more than n lines, int
    },
    textobjects = {
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ['af'] = '@function.outer',
          ['if'] = '@function.inner',
          ['ac'] = '@class.outer',
          ['ic'] = { query = '@class.inner', desc = 'Select inner part of a class region' },
        },
      },
      move = {
        enable = true,
        set_jumps = true, -- whether to set jumps in the jumplist
        goto_next_start = {
          [']m'] = '@function.outer',
          [']]'] = '@class.outer',
        },
        goto_next_end = {
          [']M'] = '@function.outer',
          [']['] = '@class.outer',
        },
        goto_previous_start = {
          ['[m'] = '@function.outer',
          ['[['] = '@class.outer',
        },
        goto_previous_end = {
          ['[M'] = '@function.outer',
          ['[]'] = '@class.outer',
        },
      },
    },
    refactor = {
      highlight_current_scope = { enable = true },
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

  vim.opt.foldmethod = 'expr'
  vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'

  -- Treesitter context
  local ts_context = require 'treesitter-context'

  ts_context.setup {
    enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
    throttle = true, -- Throttles plugin updates (may improve performance)
    max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
    patterns = { -- Match patterns for TS nodes. These get wrapped to match at word boundaries.
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
