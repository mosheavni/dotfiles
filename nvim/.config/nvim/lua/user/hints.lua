--- Generic hints module for displaying floating keymap hints
---@class Hints
local M = {}

--- Create a new hints instance
---@param title string The title for the hints window
---@param hints_config table[] Array of {key: string, desc: string} tables
---@return table Instance with show/close/toggle methods
function M.new(title, hints_config)
  local float = require('user.float').new()

  -- Format the hint lines for display
  local function format_hints()
    local lines = { ' ' .. title .. ' ', '' }
    local max_key_len = 0

    -- Find the longest key for alignment
    for _, hint in ipairs(hints_config) do
      max_key_len = math.max(max_key_len, #hint.key)
    end

    -- Format each hint line
    for _, hint in ipairs(hints_config) do
      local padding = string.rep(' ', max_key_len - #hint.key)
      table.insert(lines, string.format('  %s%s  →  %s', hint.key, padding, hint.desc))
    end

    table.insert(lines, '')
    return lines
  end

  -- Compute window configuration
  local function compute_config(buf_id)
    local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)

    -- Calculate window size
    local width = 0
    for _, line in ipairs(lines) do
      width = math.max(width, vim.fn.strdisplaywidth(line))
    end
    local height = #lines

    -- Calculate position (top-right corner with some padding)
    local ui = vim.api.nvim_list_uis()[1]
    local win_width = ui.width

    return {
      relative = 'editor',
      width = width + 2,
      height = height,
      col = win_width - width - 4,
      row = 1,
      style = 'minimal',
      border = 'rounded',
      focusable = false,
      zindex = 50,
    }
  end

  -- Window options
  local function window_opts()
    return {
      winblend = 10,
      winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
    }
  end

  -- Public API
  return {
    show = function()
      float.refresh(format_hints, compute_config, window_opts)
    end,
    close = function()
      float.close()
    end,
    toggle = function()
      float.toggle(format_hints, compute_config, window_opts)
    end,
  }
end

return M
