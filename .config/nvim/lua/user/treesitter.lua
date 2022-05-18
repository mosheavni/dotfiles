local status_ok, configs = pcall(require, "nvim-treesitter.configs")
if not status_ok then
  return
end

local ft_to_parser = require"nvim-treesitter.parsers".filetype_to_parsername
ft_to_parser.groovy = "java"

configs.setup {
  ensure_installed = "all",
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "gnn",
      node_incremental = "grn",
      scope_incremental = "grc",
      node_decremental = "grm",
    },
  },
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
  rainbow = {
    enable = true,
    -- disable = { "jsx", "cpp" }, list of languages you want to disable the plugin for
    extended_mode = true, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
    max_file_lines = nil, -- Do not enable for files with more than n lines, int
    -- colors = {}, -- table of hex strings
    -- termcolors = {} -- table of colour name strings
  },
  indent = {
    enable = true
  },
  context_commentstring = {
    enable = true
  },
  matchup = {
    enable = true
  },
  refactor = {
    highlight_current_scope = { enable = true },
    smart_rename = {
      enable = true,
      keymaps = {
        smart_rename = "grr",
      },
    },
    highlight_definitions = {
      enable = true,
      -- Set to false if you have an `updatetime` of ~100.
      clear_on_cursor_move = true,
    },
  },
}

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"

-- Treesitter context
local status_ok_tsc, ts_context = pcall(require, "treesitter-context")
if not status_ok_tsc then
local status_ok, ts_context = pcall(require, "treesitter-context")
if not status_ok then
  return
end

-- Treesitter context
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
  return
end

-- Treesitter context
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
