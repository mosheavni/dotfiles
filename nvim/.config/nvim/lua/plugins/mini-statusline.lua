vim.pack.add { 'https://github.com/nvim-mini/mini.statusline' }

return function()
  if vim.bo.filetype:match '^k8s_.*' then
    return
  end

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

  -- quickfix search term section
  local function section_qf_search()
    if vim.bo.filetype ~= 'qf' then
      return ''
    end
    local term = vim.g.qf_search_term
    local term_id = vim.g.qf_search_term_id
    if not term or term == '' or not term_id then
      return ''
    end
    if vim.fn.getqflist({ id = 0 }).id ~= term_id then
      return ''
    end
    local base, filters = term:match '^(.-)%s+(%b())$'
    if base and filters then
      return '%#MiniStatuslineFilename#' .. base .. ' %#MiniStatuslineDevinfo#' .. filters
    end
    return '%#MiniStatuslineFilename#' .. term
  end

  -- filename section
  local function section_filename()
    if vim.bo.filetype == 'qf' then
      return ''
    end
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

  -- Run-buffer terminals indicator. Shows the file basenames of the live
  -- F3 terminals, sorted by creation order (same order as ]t / [t cycles).
  -- The one tied to the current buffer (or the terminal you're on) is
  -- highlighted so you can tell at a glance which terminal is "yours".
  local function section_run_terminals()
    if statusline.is_truncated(120) then
      return ''
    end
    local ok, rb = pcall(require, 'user.run-buffer')
    if not ok or type(rb.list_terminals) ~= 'function' then
      return ''
    end
    local list = rb.list_terminals()
    if #list == 0 then
      return ''
    end
    local parts = {}
    for _, item in ipairs(list) do
      if item.is_active then
        table.insert(parts, '%#MiniStatuslineFilename#' .. item.basename .. '%#MiniStatuslineDevinfo#')
      else
        table.insert(parts, item.basename)
      end
    end
    return ' ' .. table.concat(parts, ' · ')
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
        local qf_search = section_qf_search()
        local fileformat = section_fileformat()
        local filetype = section_filetype_with_icon()
        local lsp = section_lsp_names()
        local progress = section_progress()
        local location = section_location()
        local yaml_schema = section_yaml_schema()
        local run_terminals = section_run_terminals()
        local search = statusline.section_searchcount { trunc_width = 75 }

        -- Use statusline syntax to include borders without automatic spacing
        local left_border_str = '%#MiniStatuslineBorder#▊'
        local right_border_str = ' %#MiniStatuslineBorder#▊'

        return left_border_str
          .. statusline.combine_groups {
            -- Left section
            { hl = mode_hl, strings = { mode } },
            { hl = 'MiniStatuslineGit', strings = { git } },
            { hl = 'MiniStatuslineDevinfo', strings = { diff, diagnostics, yaml_schema, run_terminals } },
            '%<', -- Truncation point

            -- Center section
            '%=', -- Start center alignment
            { hl = 'MiniStatuslineFilename', strings = { filename } },
            { hl = 'MiniStatuslineDevinfo', strings = { qf_search } },

            -- Right section
            '%=', -- End left alignment, start right alignment
            { hl = 'MiniStatuslineFileinfo', strings = { search, lsp } },
            { strings = { fileformat, filetype } },
            { hl = 'MiniStatuslineProgress', strings = { progress } },
            { hl = mode_hl, strings = { location } },
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
    vim.api.nvim_set_hl(0, 'MiniStatuslineModeNormal', { fg = palette.leaf, bg = palette.base, bold = true })
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
  end
  setup_highlights()
end
