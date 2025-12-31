--- Generic hints module for displaying floating keymap hints
---@class Hints
local M = {}

--- Create a new hints instance
---@param title string The title for the hints window
---@param hints_config table[] Array of {key: string, desc: string} tables
---@return table Instance with show/close/toggle methods
function M.new(title, hints_config)
  local float = require('user.float').new()
  local ns_id = vim.api.nvim_create_namespace('hints_highlight')

  -- Format the hint lines for display
  ---@return string[]
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
  ---@cast format_hints ContentFunction

  -- Apply extmarks to colorize the hints
  ---@param buf_id integer
  ---@param lines string[]
  local function apply_highlights(buf_id, lines)
    for line_idx, line in ipairs(lines) do
      -- Skip title and empty lines
      if line_idx > 2 and line ~= '' then
        local arrow_pos = line:find('→')
        if arrow_pos then
          -- Highlight the key (from start to before arrow, trimmed)
          -- arrow_pos is 1-indexed, extmarks use 0-indexed columns
          local key_start = 2 -- accounting for leading spaces
          local key_end = arrow_pos - 3 -- before the spaces and arrow
          vim.api.nvim_buf_set_extmark(buf_id, ns_id, line_idx - 1, key_start, {
            end_col = key_end,
            hl_group = 'Special',
          })

          -- Highlight the arrow + spaces: "→  "
          -- Arrow is 3 bytes (UTF-8), followed by 2 spaces
          vim.api.nvim_buf_set_extmark(buf_id, ns_id, line_idx - 1, arrow_pos - 1, {
            end_col = arrow_pos + 4, -- arrow (3 bytes) + 2 spaces
            hl_group = 'Comment',
          })

          -- Highlight the description
          -- Starts after arrow (3 bytes) + 2 spaces
          vim.api.nvim_buf_set_extmark(buf_id, ns_id, line_idx - 1, arrow_pos + 4, {
            end_col = #line,
            hl_group = 'Function',
          })
        end
      end
    end
  end
  ---@cast apply_highlights HighlightsFunction

  -- Compute window configuration
  ---@param buf_id integer
  ---@return vim.api.keyset.win_config
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
  ---@cast compute_config ConfigFunction

  -- Window options
  ---@return table<string, any>
  local function window_opts()
    return {
      winblend = 10,
      winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
    }
  end
  ---@cast window_opts OptsFunction

  -- Public API
  return {
    show = function()
      float.refresh(format_hints, compute_config, window_opts, apply_highlights)
    end,
    close = function()
      float.close()
    end,
    toggle = function()
      float.toggle(format_hints, compute_config, window_opts, apply_highlights)
    end,
  }
end

return M
