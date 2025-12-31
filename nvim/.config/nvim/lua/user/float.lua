--- Generic floating window module (inspired by mini.notify architecture)
--- Provides a reusable floating window implementation with proper event handling,
--- buffer/window caching, and immediate display via forced redraw.
---
--- # Examples ~
---
--- Basic usage:
--- >lua
---   local Float = require('user.float')
---   local my_float = Float.new()
---
---   -- Simple content function that returns lines to display
---   local content_fn = function()
---     return { 'Hello, World!', 'This is a floating window' }
---   end
---
---   -- Config function that returns window configuration
---   local config_fn = function(buf_id)
---     return {
---       relative = 'editor',
---       width = 40,
---       height = 2,
---       col = vim.o.columns - 42,
---       row = 1,
---       anchor = 'NE',
---       style = 'minimal',
---       border = 'rounded',
---     }
---   end
---
---   -- Show the float
---   my_float.refresh(content_fn, config_fn)
---
---   -- Close it later
---   vim.defer_fn(function() my_float.close() end, 3000)
--- <
---
--- With custom window options and highlights:
--- >lua
---   local Float = require('user.float')
---   local my_float = Float.new()
---
---   local content_fn = function()
---     return { 'Error: Something went wrong!', 'Please check your config' }
---   end
---
---   local config_fn = function(buf_id)
---     return {
---       relative = 'editor',
---       width = 50,
---       height = 2,
---       col = math.floor((vim.o.columns - 50) / 2),
---       row = math.floor(vim.o.lines / 2),
---       anchor = 'NW',
---       style = 'minimal',
---       border = 'single',
---     }
---   end
---
---   -- Optional: Apply window options
---   local opts_fn = function()
---     return {
---       winblend = 10,
---       winhighlight = 'NormalFloat:ErrorFloat,FloatBorder:ErrorBorder',
---     }
---   end
---
---   -- Optional: Apply highlights to specific lines
---   local highlights_fn = function(buf_id, lines)
---     local ns_id = vim.api.nvim_create_namespace('my_float_highlights')
---     -- Highlight first line with Error
---     vim.api.nvim_buf_add_highlight(buf_id, ns_id, 'ErrorMsg', 0, 0, -1)
---     -- Highlight second line with Warning
---     vim.api.nvim_buf_add_highlight(buf_id, ns_id, 'WarningMsg', 1, 0, -1)
---   end
---
---   my_float.refresh(content_fn, config_fn, opts_fn, highlights_fn)
--- <
---
--- Auto-sizing with utility functions:
--- >lua
---   local Float = require('user.float')
---   local my_float = Float.new()
---
---   local content_fn = function()
---     return {
---       'This is a longer line that might need wrapping',
---       'Short line',
---       'Another line with some content',
---     }
---   end
---
---   -- Use buffer_default_dimensions to auto-size the window
---   local config_fn = function(buf_id)
---     local width, height = my_float.buffer_default_dimensions(buf_id, 0.4)
---     return {
---       relative = 'editor',
---       width = width,
---       height = height,
---       col = vim.o.columns,
---       row = 0,
---       anchor = 'NE',
---       style = 'minimal',
---       border = 'rounded',
---     }
---   end
---
---   my_float.refresh(content_fn, config_fn)
--- <
---
--- Toggle functionality:
--- >lua
---   local Float = require('user.float')
---   local my_float = Float.new()
---
---   local content_fn = function()
---     return { 'Press <leader>t to toggle this float' }
---   end
---
---   local config_fn = function(buf_id)
---     return {
---       relative = 'editor',
---       width = 35,
---       height = 1,
---       col = vim.o.columns - 37,
---       row = 1,
---       anchor = 'NE',
---       style = 'minimal',
---       border = 'single',
---     }
---   end
---
---   -- Map a key to toggle the float
---   vim.keymap.set('n', '<leader>t', function()
---     my_float.toggle(content_fn, config_fn)
---   end, { desc = 'Toggle float' })
--- <
---
--- Real-world example - Git status float:
--- >lua
---   local Float = require('user.float')
---   local git_float = Float.new()
---
---   local function show_git_status()
---     local content_fn = function()
---       -- Run git status and capture output
---       local handle = io.popen('git status --short 2>&1')
---       if not handle then return { 'Error: Could not run git status' } end
---
---       local result = handle:read('*a')
---       handle:close()
---
---       if result == '' then
---         return { 'Git: Working tree clean' }
---       end
---
---       local lines = vim.split(result, '\n', { trimempty = true })
---       table.insert(lines, 1, 'Git Status:')
---       return lines
---     end
---
---     local config_fn = function(buf_id)
---       local width, height = git_float.buffer_default_dimensions(buf_id, 0.3)
---       -- Add some padding for border
---       height = math.min(height, 15)
---
---       return {
---         relative = 'editor',
---         width = width,
---         height = height,
---         col = vim.o.columns,
---         row = 0,
---         anchor = 'NE',
---         style = 'minimal',
---         border = 'rounded',
---         title = ' Git Status ',
---       }
---     end
---
---     local opts_fn = function()
---       return { winblend = 15 }
---     end
---
---     git_float.refresh(content_fn, config_fn, opts_fn)
---   end
---
---   vim.keymap.set('n', '<leader>gs', show_git_status, { desc = 'Show Git Status' })
--- <
---
---@class Float
local M = {}

---@class FloatInstance
---@field cache FloatCache
---@field refresh fun(content_fn: ContentFunction, config_fn: ConfigFunction, opts_fn?: OptsFunction, highlights_fn?: HighlightsFunction)
---@field close fun()
---@field is_shown fun(): boolean
---@field toggle fun(content_fn: ContentFunction, config_fn: ConfigFunction, opts_fn?: OptsFunction, highlights_fn?: HighlightsFunction)
---@field buffer_default_dimensions fun(buf_id: integer, max_width_share: number): integer, integer
---@field fit_to_width fun(text: string, width: number): string
---@field set_buf_name fun(buf_id: integer, name: string)

---@class FloatCache
---@field buf_id integer? Buffer ID (nil if not created)
---@field win_id integer? Window ID (nil if not created)

---@alias ContentFunction fun(): string[]  Function that returns lines to display
---@alias ConfigFunction fun(buf_id: integer): vim.api.keyset.win_config Function that returns window config
---@alias OptsFunction fun(): table<string, any> Function that returns window options
---@alias HighlightsFunction fun(buf_id: integer, lines: string[]) Function that applies highlights synchronously

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
    return vim.api.nvim_win_get_tabpage(win_id) == vim.api.nvim_get_current_tabpage()
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

  --- Compute buffer dimensions based on content (following mini.notify)
  ---@param buf_id integer Buffer ID to compute dimensions for
  ---@param max_width_share number Maximum width as share of columns (0-1)
  ---@return integer width Computed width
  ---@return integer height Computed height
  local function buffer_default_dimensions(buf_id, max_width_share)
    local line_widths = vim.tbl_map(vim.fn.strdisplaywidth, vim.api.nvim_buf_get_lines(buf_id, 0, -1, true))

    -- Compute width to fit all lines
    local width = 1
    for _, l_w in ipairs(line_widths) do
      width = math.max(width, l_w)
    end

    -- Limit from above for better visuals
    max_width_share = math.min(math.max(max_width_share, 0), 1)
    local max_width = math.max(math.floor(max_width_share * vim.o.columns), 1)
    width = math.min(width, max_width)

    -- Compute height based on width to fit all lines with 'wrap' enabled
    local height = 0
    for _, l_w in ipairs(line_widths) do
      height = height + math.floor(math.max(l_w - 1, 0) / width) + 1
    end

    return width, height
  end

  --- Fit text to width with ellipsis (following mini.notify)
  ---@param text string Text to fit
  ---@param width number Maximum width
  ---@return string Fitted text with ellipsis if truncated
  local function fit_to_width(text, width)
    local t_width = vim.fn.strchars(text)
    return t_width <= width and text or ('…' .. vim.fn.strcharpart(text, t_width - width + 1, width - 1))
  end

  --- Set buffer name with pattern (following mini.notify)
  ---@param buf_id integer Buffer ID
  ---@param name string Name suffix
  local function set_buf_name(buf_id, name)
    vim.api.nvim_buf_set_name(buf_id, 'float://' .. buf_id .. '/' .. name)
  end

  --- Main refresh function (follows mini.notify pattern)
  --- Shows or updates the floating window with new content
  ---@param content_fn ContentFunction Function that returns lines to display
  ---@param config_fn ConfigFunction Function that returns window config
  ---@param opts_fn OptsFunction? Optional function that returns window options
  ---@param highlights_fn HighlightsFunction? Optional function that applies highlights synchronously
  function instance.refresh(content_fn, config_fn, opts_fn, highlights_fn)
    -- Reschedule if in fast event (CRUCIAL - same as mini.notify)
    local in_fast = vim.in_fast_event()
    if in_fast then
      return vim.schedule(function()
        instance.refresh(content_fn, config_fn, opts_fn, highlights_fn)
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

    -- Apply highlights synchronously (mini.notify pattern)
    if highlights_fn then
      highlights_fn(buf_id, lines)
    end

    -- Refresh window
    local win_id = instance.cache.win_id
    if not (is_valid_win(win_id) and is_win_in_tabpage(win_id --[[@as integer]])) then
      window_close()
      local win_config = config_fn(buf_id)
      win_id = window_open(buf_id, win_config)
      if opts_fn then
        window_apply_options(win_id, opts_fn())
      end
    else
      ---@cast win_id integer
      local new_config = config_fn(buf_id)
      vim.api.nvim_win_set_config(win_id, new_config)
    end

    -- CRUCIAL: Force redraw (same as mini.notify)
    vim.cmd 'redraw'

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
  ---@param highlights_fn HighlightsFunction? Optional function that applies highlights synchronously
  function instance.toggle(content_fn, config_fn, opts_fn, highlights_fn)
    if instance.is_shown() then
      instance.close()
    else
      instance.refresh(content_fn, config_fn, opts_fn, highlights_fn)
    end
  end

  --- Utility: Compute buffer dimensions based on content
  ---@param buf_id integer Buffer ID to compute dimensions for
  ---@param max_width_share number Maximum width as share of columns (0-1)
  ---@return integer width Computed width
  ---@return integer height Computed height
  function instance.buffer_default_dimensions(buf_id, max_width_share)
    return buffer_default_dimensions(buf_id, max_width_share)
  end

  --- Utility: Fit text to width with ellipsis
  ---@param text string Text to fit
  ---@param width number Maximum width
  ---@return string Fitted text with ellipsis if truncated
  function instance.fit_to_width(text, width)
    return fit_to_width(text, width)
  end

  --- Utility: Set buffer name with pattern
  ---@param buf_id integer Buffer ID
  ---@param name string Name suffix
  function instance.set_buf_name(buf_id, name)
    set_buf_name(buf_id, name)
  end

  return instance
end

return M
