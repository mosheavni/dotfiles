local function get_dropdown(opts)
  opts = opts or {}

  local borders = {
    first = { '─', '│', '─', '│', '╭', '╮', '╯', '╰' },
  }

  local theme_opts = {
    theme = 'dropdown',

    results_title = false,

    sorting_strategy = 'ascending',
    layout_strategy = 'center',
    layout_config = {
      preview_cutoff = 1, -- Preview should always show (unless previewer = false)

      width = function(_, max_columns, _)
        return math.min(max_columns, 80)
      end,

      height = function(_, _, max_lines)
        return math.min(max_lines, 15)
      end,
    },

    border = true,
    borderchars = {
      prompt = { '─', '│', ' ', '│', '╭', '╮', '│', '│' },
      results = { '─', '│', '─', '│', '├', '┤', '╯', '╰' },
      preview = borders.first,
    },
  }
  if opts.layout_config and opts.layout_config.prompt_position == 'bottom' then
    theme_opts.borderchars = {
      prompt = borders.first,
      results = { '─', '│', '─', '│', '╭', '╮', '┤', '├' },
      preview = borders.first,
    }
  end

  return vim.tbl_deep_extend('force', theme_opts, opts)
end

local M = {
  'stevearc/dressing.nvim',
  config = function()
    require('dressing').setup {
      input = {
        enabled = true,
        relative = 'editor',
      },
    }
    vim.cmd [[hi link FloatTitle Normal]]
  end,
  event = 'VeryLazy',
}
return M
