local M = {
  'nvim-treesitter/nvim-treesitter',
  build = function()
    pcall(require('nvim-treesitter.install').update { with_sync = true })
  end,
  dependencies = {
    'nvim-treesitter/nvim-treesitter-textobjects',
    'nvim-treesitter/nvim-treesitter-context',
    'nvim-treesitter/nvim-treesitter-refactor',
    'nvim-treesitter/playground',
    'Afourcat/treesitter-terraform-doc.nvim',
    { 'cuducos/yaml.nvim', ft = 'yaml' },
    {
      'ckolkey/ts-node-action',
      config = function()
        vim.keymap.set({ 'n', 'v' }, 'gs', require('ts-node-action').node_action, { desc = 'Trigger Node Action' })
      end,
    },
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
      'terraform',
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
        node_incremental = '<CR>',
        scope_incremental = '<S-CR>',
        node_decremental = '<BS>',
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
    playground = {
      enable = true,
      disable = {},
      updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
      persist_queries = false, -- Whether the query persists across vim sessions
      keybindings = {
        toggle_query_editor = 'o',
        toggle_hl_groups = 'i',
        toggle_injected_languages = 't',
        toggle_anonymous_nodes = 'a',
        toggle_language_display = 'I',
        focus_language = 'f',
        unfocus_language = 'F',
        update = 'R',
        goto_node = '<cr>',
        show_help = '?',
      },
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
