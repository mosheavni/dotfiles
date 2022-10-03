local status_ok, configs = pcall(require, 'nvim-treesitter.configs')
if not status_ok then
  return
end
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
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = 'gnn',
      node_incremental = 'grn',
      scope_incremental = 'grc',
      node_decremental = 'grm',
    },
  },
  markid = { enable = true },
  highlight = {
    enable = true,
    disable = {
      'yaml',
    },
    additional_vim_regex_highlighting = false,
  },
  indent = {
    enable = true,
  },
  context_commentstring = {
    enable = true,
  },
  matchup = {
    enable = true,
  },
  rainbow = {
    enable = true,
    extended_mode = true, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
    max_file_lines = nil, -- Do not enable for files with more than n lines, int
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
local status_ok_tsc, ts_context = pcall(require, 'treesitter-context')
if not status_ok_tsc then
  return
end

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
