--- Generic floating window module (inspired by mini.notify architecture)
--- Provides a reusable floating window implementation with proper event handling,
--- buffer/window caching, and immediate display via forced redraw.
---@class Float
local M = {}

---@class FloatInstance
---@field cache FloatCache
---@field refresh fun(content_fn: ContentFunction, config_fn: ConfigFunction, opts_fn?: OptsFunction)
---@field close fun()
---@field is_shown fun(): boolean
---@field toggle fun(content_fn: ContentFunction, config_fn: ConfigFunction, opts_fn?: OptsFunction)

---@class FloatCache
---@field buf_id integer? Buffer ID (nil if not created)
---@field win_id integer? Window ID (nil if not created)

---@alias ContentFunction fun(): string[] Function that returns lines to display
---@alias ConfigFunction fun(buf_id: integer): table Function that returns window config
---@alias OptsFunction fun(): table<string, any> Function that returns window options

--- Create a new float instance
---@return FloatInstance
function M.new()
  local instance = {
    cache = {
      buf_id = nil,
      win_id = nil,
    },
  }

  --- Check if buffer is valid
  ---@param buf_id integer?
  ---@return boolean
  local function is_valid_buf(buf_id)
    return buf_id ~= nil and vim.api.nvim_buf_is_valid(buf_id)
  end

  --- Check if window is valid
  ---@param win_id integer?
  ---@return boolean
  local function is_valid_win(win_id)
    return win_id ~= nil and vim.api.nvim_win_is_valid(win_id)
  end

  --- Check if window is in current tabpage
  ---@param win_id integer
  ---@return boolean
  local function is_win_in_tabpage(win_id)
    local tabpage_wins = vim.api.nvim_tabpage_list_wins(0)
    return vim.tbl_contains(tabpage_wins, win_id)
  end

  --- Create a new buffer for the float
  ---@return integer buf_id The created buffer ID
  local function buffer_create()
    local buf_id = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf_id })
    return buf_id
  end

  --- Refresh buffer content with new lines
  ---@param buf_id integer Buffer ID to refresh
  ---@param lines string[] Lines to set in buffer
  local function buffer_refresh(buf_id, lines)
    vim.api.nvim_set_option_value('modifiable', true, { buf = buf_id })
    vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
    vim.api.nvim_set_option_value('modifiable', false, { buf = buf_id })
  end

  --- Open a new floating window
  ---@param buf_id integer Buffer to display in window
  ---@param win_config table Window configuration (see :h nvim_open_win)
  ---@return integer win_id The created window ID
  local function window_open(buf_id, win_config)
    local win_id = vim.api.nvim_open_win(buf_id, false, win_config)
    return win_id
  end

  --- Apply options to window
  ---@param win_id integer Window ID
  ---@param win_opts table<string, any>? Window options to apply
  local function window_apply_options(win_id, win_opts)
    if not win_opts then
      return
    end
    for opt, value in pairs(win_opts) do
      vim.api.nvim_set_option_value(opt, value, { win = win_id })
    end
  end

  --- Close the floating window
  local function window_close()
    if is_valid_win(instance.cache.win_id) then
      vim.api.nvim_win_close(instance.cache.win_id, true)
      instance.cache.win_id = nil
    end
  end

  --- Main refresh function (follows mini.notify pattern)
  --- Shows or updates the floating window with new content
  ---@param content_fn ContentFunction Function that returns lines to display
  ---@param config_fn ConfigFunction Function that returns window config
  ---@param opts_fn OptsFunction? Optional function that returns window options
  function instance.refresh(content_fn, config_fn, opts_fn)
    -- Reschedule if in fast event (CRUCIAL - same as mini.notify)
    if vim.in_fast_event() then
      return vim.schedule(function()
        instance.refresh(content_fn, config_fn, opts_fn)
      end)
    end

    -- Get content lines
    local lines = content_fn()
    if not lines or #lines == 0 then
      return instance.close()
    end

    -- Refresh buffer
    local buf_id = instance.cache.buf_id
    if not is_valid_buf(buf_id) then
      buf_id = buffer_create()
    end
    ---@cast buf_id integer
    buffer_refresh(buf_id, lines)

    -- Refresh window
    local win_id = instance.cache.win_id
    if not (is_valid_win(win_id) and is_win_in_tabpage(win_id)) then
      window_close()
      local win_config = config_fn(buf_id)
      win_id = window_open(buf_id, win_config)
      if opts_fn then
        window_apply_options(win_id, opts_fn())
      end
    else
      local new_config = config_fn(buf_id)
      ---@cast win_id integer
      vim.api.nvim_win_set_config(win_id, new_config)
    end

    -- CRUCIAL: Force redraw (same as mini.notify)
    vim.cmd('redraw')

    -- Update cache
    instance.cache.buf_id = buf_id
    instance.cache.win_id = win_id
  end

  --- Close and cleanup the floating window and buffer
  function instance.close()
    window_close()
    if is_valid_buf(instance.cache.buf_id) then
      vim.api.nvim_buf_delete(instance.cache.buf_id, { force = true })
      instance.cache.buf_id = nil
    end
  end

  --- Check if the floating window is currently shown
  ---@return boolean
  function instance.is_shown()
    return is_valid_win(instance.cache.win_id) and is_win_in_tabpage(instance.cache.win_id)
  end

  --- Toggle the floating window visibility
  ---@param content_fn ContentFunction Function that returns lines to display
  ---@param config_fn ConfigFunction Function that returns window config
  ---@param opts_fn OptsFunction? Optional function that returns window options
  function instance.toggle(content_fn, config_fn, opts_fn)
    if instance.is_shown() then
      instance.close()
    else
      instance.refresh(content_fn, config_fn, opts_fn)
    end
  end

  return instance
end

return M
