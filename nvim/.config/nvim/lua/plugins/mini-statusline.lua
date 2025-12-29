local M = {
  'nvim-mini/mini.statusline',
  version = false,
  event = 'VeryLazy',
  enabled = true,
}

M.config = function()
  local statusline = require 'mini.statusline'

  -- Get rose-pine colors
  local palette = require 'rose-pine.palette'

  ---------------------
  -- Custom Sections --
  ---------------------
  -- Custom mode section that shows single character with icon
  local function section_mode_short()
    local mode, mode_hl = statusline.section_mode { trunc_width = 1000 }
    return ' ' .. mode, mode_hl
  end

  -- Custom diff section with icons and highlights
  local function section_diff()
    if statusline.is_truncated(150) then
      return ''
    end
    local diff = vim.b.gitsigns_status_dict

    if not diff then
      return ''
    end

    local icons = { added = '', changed = '', removed = '' }

    local added = diff.added and diff.added > 0 and (string.format('%%#MiniStatuslineDiffAdd#%s %s', icons.added, diff.added)) or ''
    local changed = diff.changed and diff.changed > 0 and (string.format(' %%#MiniStatuslineDiffChange#%s %s', icons.changed, diff.changed)) or ''
    local removed = diff.removed and diff.removed > 0 and (string.format(' %%#MiniStatuslineDiffRemove#%s %s', icons.removed, diff.removed)) or ''
    local end_hl = (#added + #changed + #removed) > 0 and '%#MiniStatuslineDevinfo#' or ''

    return table.concat({ added, changed, removed }, '') .. end_hl
  end

  -- Custom diagnostics section with per-severity coloring
  local function section_diagnostics_colored()
    if statusline.is_truncated(100) then
      return ''
    end

    local diagnostics = vim.diagnostic.get(0)
    local counts = { ERROR = 0, WARN = 0, INFO = 0, HINT = 0 }

    for _, diagnostic in ipairs(diagnostics) do
      local severity = vim.diagnostic.severity[diagnostic.severity]
      counts[severity] = counts[severity] + 1
    end

    local result = {}
    local signs = { ERROR = '', WARN = '', INFO = '', HINT = '󰌶' }

    local hls = {
      ERROR = 'DiagnosticError',
      WARN = 'DiagnosticWarn',
      INFO = 'DiagnosticInfo',
      HINT = 'DiagnosticHint',
    }

    for _, severity in ipairs { 'ERROR', 'WARN', 'INFO', 'HINT' } do
      if counts[severity] > 0 then
        table.insert(result, string.format('%%#%s#%s %d', hls[severity], signs[severity], counts[severity]))
      end
    end

    if #result > 0 then
      return table.concat(result, ' ') .. '%#MiniStatuslineDevinfo#'
    end
    return ''
  end

  -- Custom LSP section that shows server names
  local function section_lsp_names()
    local lsp_icon = ' '
    if statusline.is_truncated(160) then
      return ''
    end
    local clients = vim.b.attached_lsp or {}
    -- Icon with green/pine highlight, then reset to fileinfo color
    local icon = string.format('%%#MiniStatuslineLSPIcon#%s%%#MiniStatuslineFileinfo# ', lsp_icon)
    if not next(clients) then
      return icon .. 'No Active LSP'
    end
    return icon .. 'LSP: ' .. table.concat(clients, ', ')
  end

  -- Custom line:col section
  local function section_location()
    return '%l:%v'
  end

  -- Custom progress section
  local function section_progress()
    if statusline.is_truncated(100) then
      return ''
    end
    return '%2p%%'
  end

  -- filename section
  local function section_filename()
    -- In terminal always use plain name
    if vim.bo.buftype == 'terminal' then
      return '%t'
    elseif statusline.is_truncated(110) then
      -- File name with 'truncate', 'modified', 'readonly' flags
      -- Use relative path if truncated
      return '%t%m%r'
    else
      return '%f%m%r'
    end
  end

  -- get file format
  local function section_fileformat()
    local format_symbols = {
      unix = '', -- e712
      dos = '', -- e70f
      mac = '', -- e711
    }
    local format = vim.bo.fileformat
    return string.format('%%#MiniStatuslineFormatIcon#%s ', format_symbols[format] or format), 'MiniStatuslineDevinfo'
  end

  -- get filetype icon and name
  local function section_filetype_with_icon()
    local filetype = vim.bo.filetype
    if not filetype or filetype == '' then
      return ''
    end

    if statusline.is_truncated(120) then
      return filetype
    end

    local ok, devicons = pcall(require, 'nvim-web-devicons')
    if not ok then
      return filetype
    end

    local icon = devicons.get_icon(vim.fn.expand '%:t', nil, { strict = true, default = false })
    if not icon then
      icon = devicons.get_icon_by_filetype(filetype, { strict = true, default = true })
    end

    -- Icon with pine/blue highlight, then reset to fileinfo color for filetype name
    return string.format('%%#MiniStatuslineLSPIcon#%s %%#MiniStatuslineFileinfo#%s', icon, filetype)
  end

  -- Startup time section with color coding
  local function section_startup_time()
    if statusline.is_truncated(75) then
      return '', 'MiniStatuslineFileinfo'
    end

    local ok, lazy = pcall(require, 'lazy')
    if not ok then
      return '', 'MiniStatuslineFileinfo'
    end

    local time = lazy.stats().startuptime
    local hl = 'MiniStatuslineStartupGreen'

    if time > 120 then
      hl = 'MiniStatuslineStartupRed'
    elseif time > 90 then
      hl = 'MiniStatuslineStartupOrange'
    elseif time > 60 then
      hl = 'MiniStatuslineStartupYellow'
    end

    return string.format('%.2f', time), hl
  end

  -- YAML schema section (only for YAML files)
  local function section_yaml_schema()
    local ft = vim.bo.filetype or ''
    if not ft:match '^yaml' then
      return ''
    end

    local ok, yaml_companion = pcall(require, 'yaml-companion')
    if not ok then
      return ''
    end

    local ok_schema, schema = pcall(yaml_companion.get_buf_schema, 0)
    if ok_schema and schema and schema.result and schema.result[1] then
      return ' Schema: ' .. schema.result[1].name
    end

    return ''
  end

  ----------------
  -- Statusline --
  ----------------
  statusline.setup {
    use_icons = true,
    content = {
      active = function()
        local mode, mode_hl = section_mode_short()
        local git = statusline.section_git { trunc_width = 40, icon = '' }
        local diff = section_diff()
        local diagnostics = section_diagnostics_colored()
        local filename = section_filename()
        local fileformat = section_fileformat()
        local filetype = section_filetype_with_icon()
        local lsp = section_lsp_names()
        local progress = section_progress()
        local location = section_location()
        local startup_time, startup_hl = section_startup_time()
        local yaml_schema = section_yaml_schema()

        -- Use statusline syntax to include borders without automatic spacing
        local left_border_str = '%#MiniStatuslineBorder#▊'
        local right_border_str = ' %#MiniStatuslineBorder#▊'

        return left_border_str
          .. statusline.combine_groups {
            -- Left section
            { hl = mode_hl, strings = { mode } },
            { hl = 'MiniStatuslineGit', strings = { git } },
            { hl = 'MiniStatuslineDevinfo', strings = { diff, diagnostics, yaml_schema } },
            '%<', -- Truncation point

            -- Center section
            '%=', -- Start center alignment
            { hl = 'MiniStatuslineFilename', strings = { filename } },

            -- Right section
            '%=', -- End left alignment, start right alignment
            { hl = 'MiniStatuslineFileinfo', strings = { lsp } },
            { strings = { fileformat, filetype } },
            { hl = 'MiniStatuslineProgress', strings = { progress } },
            { hl = mode_hl, strings = { location } },
            { hl = startup_hl, strings = { startup_time } },
          }
          .. right_border_str
      end,
    },
  }

  ----------------
  -- Highlights --
  ----------------
  local function setup_highlights()
    -- Customize mode colors to match lualine rose-pine theme
    -- Text color = mode color, background = base (neutral)
    vim.api.nvim_set_hl(0, 'MiniStatuslineModeNormal', { fg = palette.rose, bg = palette.base, bold = true })
    vim.api.nvim_set_hl(0, 'MiniStatuslineModeInsert', { fg = palette.pine, bg = palette.base, bold = true })
    vim.api.nvim_set_hl(0, 'MiniStatuslineModeVisual', { fg = palette.foam, bg = palette.base, bold = true })
    vim.api.nvim_set_hl(0, 'MiniStatuslineModeReplace', { fg = palette.iris, bg = palette.base, bold = true })
    vim.api.nvim_set_hl(0, 'MiniStatuslineModeCommand', { fg = palette.love, bg = palette.base, bold = true })
    vim.api.nvim_set_hl(0, 'MiniStatuslineModeOther', { fg = palette.gold, bg = palette.base, bold = true })

    -- Diff section colors
    vim.api.nvim_set_hl(0, 'MiniStatuslineDiffAdd', { fg = palette.pine, bg = palette.base })
    vim.api.nvim_set_hl(0, 'MiniStatuslineDiffChange', { fg = palette.iris, bg = palette.base })
    vim.api.nvim_set_hl(0, 'MiniStatuslineDiffRemove', { fg = palette.love, bg = palette.base })

    -- Customize other section colors
    vim.api.nvim_set_hl(0, 'MiniStatuslineDevinfo', { fg = palette.text, bg = palette.base })
    vim.api.nvim_set_hl(0, 'MiniStatuslineGit', { fg = palette.rose, bg = palette.base, bold = true })
    vim.api.nvim_set_hl(0, 'MiniStatuslineFilename', { fg = palette.love, bg = palette.base, bold = true })
    vim.api.nvim_set_hl(0, 'MiniStatuslineFileinfo', { fg = palette.text, bg = palette.base })
    vim.api.nvim_set_hl(0, 'MiniStatuslineProgress', { fg = palette.text, bg = palette.base, bold = true })
    vim.api.nvim_set_hl(0, 'MiniStatuslineBorder', { fg = palette.foam, bg = palette.base })
    vim.api.nvim_set_hl(0, 'MiniStatuslineLSPIcon', { fg = palette.pine, bg = palette.base })
    vim.api.nvim_set_hl(0, 'MiniStatuslineFormatIcon', { fg = palette.rose, bg = palette.base, bold = true })

    -- Startup time colors (color-coded by performance)
    vim.api.nvim_set_hl(0, 'MiniStatuslineStartupGreen', { fg = palette.pine, bg = palette.base })
    vim.api.nvim_set_hl(0, 'MiniStatuslineStartupYellow', { fg = palette.gold, bg = palette.base })
    vim.api.nvim_set_hl(0, 'MiniStatuslineStartupOrange', { fg = palette.iris, bg = palette.base })
    vim.api.nvim_set_hl(0, 'MiniStatuslineStartupRed', { fg = palette.love, bg = palette.base })
  end
  setup_highlights()
end

return M
