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
