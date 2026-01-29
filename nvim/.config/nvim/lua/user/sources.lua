--- Interactive floating window to manage LSPs, Linters, and Formatters
--- Provides toggleable checkboxes using virtual text for each source
local M = {}

local Float = require 'user.float'
local ns_id = vim.api.nvim_create_namespace 'sources_float'

-- State tracking for disabled sources
-- Note: linter state is stored in require('lint')._disabled_linters
local state = {
  disabled_lsp = {}, -- name -> true (for tracking disabled LSPs)
  disabled_formatters = {}, -- ft -> { formatter_name = true }
}

-- Float instance
local sources_float = Float.new()

-- Line types for cursor navigation
local LINE_TYPE = {
  HEADER = 'header',
  ITEM = 'item',
  EMPTY = 'empty',
  HINTS = 'hints',
}

-- Forward declaration
local setup_keymaps

---@class SourceItem
---@field type 'lsp'|'linter'|'formatter'
---@field name string
---@field enabled boolean
---@field client? vim.lsp.Client

---@class LineMapping
---@field line_type string
---@field item? SourceItem

-- Check if an LSP is enabled (not disabled via :lsp disable)
---@param name string
---@return boolean
local function is_lsp_enabled(name)
  return not state.disabled_lsp[name]
end

-- Check if a linter is enabled
---@param linter_name string
---@return boolean
function M.is_linter_enabled(linter_name)
  local lint_ok, lint = pcall(require, 'lint')
  if not lint_ok or not lint._disabled_linters then
    return true
  end
  return not lint._disabled_linters[linter_name]
end

-- Check if a formatter is enabled for the current filetype
---@param formatter_name string
---@param ft string
---@return boolean
function M.is_formatter_enabled(formatter_name, ft)
  if not state.disabled_formatters[ft] then
    return true
  end
  return not state.disabled_formatters[ft][formatter_name]
end

-- Toggle LSP using native :lsp enable/disable
---@param item SourceItem
---@return boolean new_state (true = enabled)
local function toggle_lsp(item)
  local name = item.name
  if is_lsp_enabled(name) then
    -- Disable LSP for current and future buffers
    vim.cmd('lsp disable ' .. name)
    state.disabled_lsp[name] = true
    return false
  else
    -- Enable LSP for current and future buffers
    vim.cmd('lsp enable ' .. name)
    state.disabled_lsp[name] = nil
    return true
  end
end

-- Toggle linter (works for both ft-specific and global linters)
---@param linter_name string
---@return boolean new_state (true = enabled)
function M.toggle_linter(linter_name)
  local lint = require 'lint'

  if not lint._disabled_linters then
    lint._disabled_linters = {}
  end

  if M.is_linter_enabled(linter_name) then
    -- Disable linter
    lint._disabled_linters[linter_name] = true
    -- Clear diagnostics for this linter
    local ns = vim.api.nvim_create_namespace(linter_name)
    vim.diagnostic.reset(ns)
    return false
  else
    -- Enable linter
    lint._disabled_linters[linter_name] = nil
    return true
  end
end

-- Toggle formatter for current filetype
---@param formatter_name string
---@param ft string
---@return boolean new_state (true = enabled)
function M.toggle_formatter(formatter_name, ft)
  local conform = require 'conform'

  if not state.disabled_formatters[ft] then
    state.disabled_formatters[ft] = {}
  end

  if M.is_formatter_enabled(formatter_name, ft) then
    -- Disable: remove from formatters_by_ft
    state.disabled_formatters[ft][formatter_name] = true
    local formatters = conform.formatters_by_ft[ft]
    if type(formatters) == 'table' then
      conform.formatters_by_ft[ft] = vim.tbl_filter(function(f)
        return f ~= formatter_name
      end, formatters)
    end
    return false
  else
    -- Enable: add back to formatters_by_ft
    state.disabled_formatters[ft][formatter_name] = nil
    local formatters = conform.formatters_by_ft[ft] or {}
    if type(formatters) == 'table' then
      table.insert(formatters, formatter_name)
      conform.formatters_by_ft[ft] = formatters
    end
    return true
  end
end

-- Build content lines and line mappings
---@param bufnr integer
---@return string[] lines
---@return LineMapping[] mappings
function M.build_content(bufnr)
  local lines = {}
  local mappings = {}
  local ft = vim.bo[bufnr].filetype

  -- Hints line
  table.insert(lines, '<Tab> toggle  i inspect  r restart  R refresh  q quit')
  table.insert(mappings, { line_type = LINE_TYPE.HINTS })

  table.insert(lines, '')
  table.insert(mappings, { line_type = LINE_TYPE.EMPTY })

  -- LSPs section
  table.insert(lines, 'LSPs:')
  table.insert(mappings, { line_type = LINE_TYPE.HEADER })

  local clients = vim.lsp.get_clients { bufnr = bufnr }
  local seen_lsps = {}

  -- Active clients are enabled
  for _, client in ipairs(clients) do
    seen_lsps[client.name] = true
    table.insert(lines, '    ' .. client.name)
    table.insert(mappings, {
      line_type = LINE_TYPE.ITEM,
      item = { type = 'lsp', name = client.name, enabled = true, client = client },
    })
  end

  -- Include disabled LSPs
  for name, _ in pairs(state.disabled_lsp) do
    if not seen_lsps[name] then
      table.insert(lines, '    ' .. name)
      table.insert(mappings, {
        line_type = LINE_TYPE.ITEM,
        item = { type = 'lsp', name = name, enabled = false },
      })
    end
  end

  if #clients == 0 and vim.tbl_isempty(state.disabled_lsp) then
    table.insert(lines, '  (none)')
    table.insert(mappings, { line_type = LINE_TYPE.EMPTY })
  end

  table.insert(lines, '')
  table.insert(mappings, { line_type = LINE_TYPE.EMPTY })

  -- Linters section
  table.insert(lines, 'Linters:')
  table.insert(mappings, { line_type = LINE_TYPE.HEADER })

  local lint_ok, lint = pcall(require, 'lint')
  local linters = {}
  local seen_linters = {}

  -- Filetype-specific linters
  if lint_ok and lint.linters_by_ft[ft] then
    for _, linter_name in ipairs(lint.linters_by_ft[ft]) do
      if not seen_linters[linter_name] then
        seen_linters[linter_name] = true
        table.insert(linters, { name = linter_name, global = false })
      end
    end
  end

  -- Global linters (codespell, gitleaks, trivy)
  if lint_ok and lint._global_linter_names then
    for _, linter_name in ipairs(lint._global_linter_names) do
      if not seen_linters[linter_name] then
        seen_linters[linter_name] = true
        table.insert(linters, { name = linter_name, global = true })
      end
    end
  end

  if #linters == 0 then
    table.insert(lines, '  (none)')
    table.insert(mappings, { line_type = LINE_TYPE.EMPTY })
  else
    for _, linter in ipairs(linters) do
      local enabled = M.is_linter_enabled(linter.name)
      local suffix = linter.global and ' (global)' or ''
      table.insert(lines, '    ' .. linter.name .. suffix)
      table.insert(mappings, {
        line_type = LINE_TYPE.ITEM,
        item = { type = 'linter', name = linter.name, enabled = enabled },
      })
    end
  end

  table.insert(lines, '')
  table.insert(mappings, { line_type = LINE_TYPE.EMPTY })

  -- Formatters section
  table.insert(lines, 'Formatters:')
  table.insert(mappings, { line_type = LINE_TYPE.HEADER })

  local conform_ok, conform = pcall(require, 'conform')
  local formatters = {}
  if conform_ok then
    local fmt_config = conform.formatters_by_ft[ft]
    if type(fmt_config) == 'function' then
      fmt_config = fmt_config(bufnr)
    end
    if type(fmt_config) == 'table' then
      formatters = vim.deepcopy(fmt_config)
    end
  end

  -- Also include disabled formatters that were originally configured
  if state.disabled_formatters[ft] then
    for formatter_name, _ in pairs(state.disabled_formatters[ft]) do
      if not vim.tbl_contains(formatters, formatter_name) then
        table.insert(formatters, formatter_name)
      end
    end
  end

  if #formatters == 0 then
    table.insert(lines, '  (none)')
    table.insert(mappings, { line_type = LINE_TYPE.EMPTY })
  else
    for _, formatter_name in ipairs(formatters) do
      local enabled = M.is_formatter_enabled(formatter_name, ft)
      table.insert(lines, '    ' .. formatter_name)
      table.insert(mappings, {
        line_type = LINE_TYPE.ITEM,
        item = { type = 'formatter', name = formatter_name, enabled = enabled },
      })
    end
  end

  return lines, mappings
end

-- Get item at cursor position
---@param mappings LineMapping[]
---@param cursor_line integer (1-indexed)
---@return SourceItem?
function M.get_item_at_cursor(mappings, cursor_line)
  local mapping = mappings[cursor_line]
  if mapping and mapping.line_type == LINE_TYPE.ITEM then
    return mapping.item
  end
  return nil
end

-- Find next/previous item line
---@param mappings LineMapping[]
---@param current_line integer (1-indexed)
---@param direction integer (1 for next, -1 for previous)
---@return integer new_line (1-indexed)
local function find_item_line(mappings, current_line, direction)
  local line = current_line + direction
  while line >= 1 and line <= #mappings do
    if mappings[line].line_type == LINE_TYPE.ITEM then
      return line
    end
    line = line + direction
  end
  return current_line
end

-- Apply virtual text checkboxes to buffer
---@param buf_id integer
---@param mappings LineMapping[]
local function apply_checkboxes(buf_id, mappings)
  vim.api.nvim_buf_clear_namespace(buf_id, ns_id, 0, -1)

  for i, mapping in ipairs(mappings) do
    local line = i - 1 -- 0-indexed for extmarks

    if mapping.line_type == LINE_TYPE.HINTS then
      vim.api.nvim_buf_add_highlight(buf_id, ns_id, 'Comment', line, 0, -1)
    elseif mapping.line_type == LINE_TYPE.HEADER then
      vim.api.nvim_buf_add_highlight(buf_id, ns_id, 'Title', line, 0, -1)
    elseif mapping.line_type == LINE_TYPE.ITEM and mapping.item then
      local enabled = mapping.item.enabled
      local checkbox = enabled and '[x] ' or '[ ] '
      local hl = enabled and 'DiagnosticOk' or 'Comment'

      vim.api.nvim_buf_set_extmark(buf_id, ns_id, line, 0, {
        virt_text = { { checkbox, hl } },
        virt_text_pos = 'inline',
      })
    end
  end
end

-- Current state for the float
local current_bufnr = nil
local current_mappings = {}

-- Show the sources float
function M.show()
  current_bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[current_bufnr].filetype

  local function content_fn()
    local lines, mappings = M.build_content(current_bufnr)
    current_mappings = mappings
    return lines
  end

  local function config_fn(buf_id)
    local width, height = sources_float.buffer_default_dimensions(buf_id, 0.5)
    width = math.max(width, 50)
    height = math.min(height + 2, 20)

    return {
      relative = 'editor',
      width = width,
      height = height,
      col = math.floor((vim.o.columns - width) / 2),
      row = math.floor((vim.o.lines - height) / 2),
      anchor = 'NW',
      style = 'minimal',
      border = 'rounded',
      title = ' Sources (' .. ft .. ') ',
      title_pos = 'center',
    }
  end

  local function highlights_fn(buf_id, _)
    apply_checkboxes(buf_id, current_mappings)
  end

  sources_float.refresh(content_fn, config_fn, nil, highlights_fn)

  -- Enter the window and set up keymaps
  local win_id = sources_float.cache.win_id
  local buf_id = sources_float.cache.buf_id
  if win_id and buf_id then
    vim.api.nvim_set_current_win(win_id)
    vim.bo[buf_id].filetype = 'sources'
    setup_keymaps(buf_id)

    -- Move cursor to first item line
    for i, mapping in ipairs(current_mappings) do
      if mapping.line_type == LINE_TYPE.ITEM then
        vim.api.nvim_win_set_cursor(win_id, { i, 0 })
        break
      end
    end
  end
end

-- Refresh the float content
local function refresh()
  if not sources_float.is_shown() then
    return
  end

  local ft = vim.bo[current_bufnr].filetype

  local function content_fn()
    local lines, mappings = M.build_content(current_bufnr)
    current_mappings = mappings
    return lines
  end

  local function config_fn(buf_id)
    local width, height = sources_float.buffer_default_dimensions(buf_id, 0.5)
    width = math.max(width, 50)
    height = math.min(height + 2, 20)

    return {
      relative = 'editor',
      width = width,
      height = height,
      col = math.floor((vim.o.columns - width) / 2),
      row = math.floor((vim.o.lines - height) / 2),
      anchor = 'NW',
      style = 'minimal',
      border = 'rounded',
      title = ' Sources (' .. ft .. ') ',
      title_pos = 'center',
    }
  end

  local function highlights_fn(buf_id, _)
    apply_checkboxes(buf_id, current_mappings)
  end

  sources_float.refresh(content_fn, config_fn, nil, highlights_fn)
end

-- Set up buffer-local keymaps
---@param buf_id integer
setup_keymaps = function(buf_id)
  local opts = { buffer = buf_id, nowait = true }

  -- Close
  vim.keymap.set('n', 'q', function()
    sources_float.close()
  end, opts)
  vim.keymap.set('n', '<Esc>', function()
    sources_float.close()
  end, opts)

  -- Toggle
  vim.keymap.set('n', '<Tab>', function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local item = M.get_item_at_cursor(current_mappings, cursor[1])
    if not item then
      return
    end

    local ft = vim.bo[current_bufnr].filetype

    if item.type == 'lsp' then
      toggle_lsp(item)
    elseif item.type == 'linter' then
      M.toggle_linter(item.name)
    elseif item.type == 'formatter' then
      M.toggle_formatter(item.name, ft)
    end

    refresh()
  end, opts)

  -- Inspect LSP
  vim.keymap.set('n', 'i', function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local item = M.get_item_at_cursor(current_mappings, cursor[1])
    if not item or item.type ~= 'lsp' then
      vim.notify('Inspect only available for LSP items', vim.log.levels.WARN)
      return
    end

    sources_float.close()
    require('user.lsp.inspect').select_client()
  end, opts)

  -- Restart LSP
  vim.keymap.set('n', 'r', function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local item = M.get_item_at_cursor(current_mappings, cursor[1])
    if not item or item.type ~= 'lsp' then
      vim.notify('Restart only available for LSP items', vim.log.levels.WARN)
      return
    end

    vim.cmd('lsp restart ' .. item.name)
    vim.defer_fn(refresh, 200)
  end, opts)

  -- Refresh
  vim.keymap.set('n', 'R', refresh, opts)

  -- Custom j/k to skip non-item lines
  vim.keymap.set('n', 'j', function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local new_line = find_item_line(current_mappings, cursor[1], 1)
    vim.api.nvim_win_set_cursor(0, { new_line, 0 })
  end, opts)

  vim.keymap.set('n', 'k', function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local new_line = find_item_line(current_mappings, cursor[1], -1)
    vim.api.nvim_win_set_cursor(0, { new_line, 0 })
  end, opts)
end

function M.setup()
  vim.api.nvim_create_user_command('Sources', M.show, {
    desc = 'Toggle sources float (LSPs, Linters, Formatters)',
  })

  require('user.menu').add_actions('LSP', {
    ['Sources Toggle'] = M.show,
  })
end

return M
