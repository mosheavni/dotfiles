---@class Present
---Minimal presentation plugin for markdown slides
local M = {}

local Float = require 'user.float'

---@class PresentState
---@field active boolean
---@field slides string[]
---@field current integer
---@field saved table
---@field float FloatInstance?
---@field backdrop_buf integer?
---@field backdrop_win integer?
M.state = {
  active = false,
  slides = {},
  current = 1,
  saved = {},
  float = nil,
  backdrop_buf = nil,
  backdrop_win = nil,
}

---Discover markdown slides in a directory
---@param dir string Directory path
---@return string[] Sorted list of slide paths
local function discover_slides(dir)
  local files = vim.fn.glob(dir .. '/*.md', false, true)
  table.sort(files)
  return files
end

---Get centered float window config
---@return vim.api.keyset.win_config
local function get_float_config()
  local width = math.floor(vim.o.columns * 0.95)
  local height = math.floor(vim.o.lines * 0.92)
  return {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = 'minimal',
    border = 'rounded',
  }
end

---Get a solid background color from colorscheme
local function get_solid_bg()
  local normal = vim.api.nvim_get_hl(0, { name = 'Normal' })
  -- Use Normal bg if it exists, otherwise fallback to a dark color
  return normal.bg or 0x1a1a2e
end

---Create highlight group with solid background
local function setup_highlights()
  local bg = get_solid_bg()
  vim.api.nvim_set_hl(0, 'PresentNormal', { bg = bg, fg = vim.api.nvim_get_hl(0, { name = 'Normal' }).fg })
  vim.api.nvim_set_hl(0, 'PresentBorder', { bg = bg, fg = vim.api.nvim_get_hl(0, { name = 'FloatBorder' }).fg })
end

---Create a full-screen backdrop to hide the main buffer
local function create_backdrop()
  setup_highlights()

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'

  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'editor',
    width = vim.o.columns,
    height = vim.o.lines,
    col = 0,
    row = 0,
    style = 'minimal',
    focusable = false,
    zindex = 1,
  })

  -- Solid background, no transparency
  vim.api.nvim_set_option_value('winblend', 0, { win = win })
  vim.api.nvim_set_option_value('winhighlight', 'Normal:PresentNormal', { win = win })

  M.state.backdrop_buf = buf
  M.state.backdrop_win = win
end

---Close the backdrop
local function close_backdrop()
  if M.state.backdrop_win and vim.api.nvim_win_is_valid(M.state.backdrop_win) then
    vim.api.nvim_win_close(M.state.backdrop_win, true)
  end
  M.state.backdrop_win = nil
  M.state.backdrop_buf = nil
end

---Save current UI state
local function save_ui_state()
  M.state.saved = {
    number = vim.wo.number,
    relativenumber = vim.wo.relativenumber,
    signcolumn = vim.wo.signcolumn,
    laststatus = vim.o.laststatus,
    showtabline = vim.o.showtabline,
    statusline = vim.wo.statusline,
  }
end

---Restore saved UI state
local function restore_ui_state()
  vim.wo.number = M.state.saved.number
  vim.wo.relativenumber = M.state.saved.relativenumber
  vim.wo.signcolumn = M.state.saved.signcolumn
  vim.o.laststatus = M.state.saved.laststatus
  vim.o.showtabline = M.state.saved.showtabline
  vim.wo.statusline = M.state.saved.statusline
end

---Apply presentation UI settings
local function apply_presentation_ui()
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = 'no'
  vim.o.laststatus = 2 -- Show statusline (needed for slide progress)
  vim.o.showtabline = 0
end

---Setup buffer-local keymaps
---@param buf integer
local function setup_keymaps(buf)
  local opts = { buffer = buf, silent = true }
  vim.keymap.set('n', ']]', M.next, opts)
  vim.keymap.set('n', '[[', M.prev, opts)
  vim.keymap.set('n', '<Esc>', M.stop, opts)
end

---Center content within the window dimensions
---@param lines string[] Original content lines
---@param win_width integer Window width
---@param win_height integer Window height
---@return string[] Centered lines with padding
local function center_content(lines, win_width, win_height)
  -- Find the longest line for horizontal centering
  local max_line_width = 0
  for _, line in ipairs(lines) do
    local width = vim.fn.strdisplaywidth(line)
    if width > max_line_width then
      max_line_width = width
    end
  end

  -- Calculate horizontal padding (account for border)
  local content_width = win_width - 2
  local left_pad = math.max(0, math.floor((content_width - max_line_width) / 2))
  local padding = string.rep(' ', left_pad)

  -- Add horizontal padding to each line
  local padded_lines = {}
  for _, line in ipairs(lines) do
    table.insert(padded_lines, padding .. line)
  end

  -- Calculate vertical padding (account for border and statusline)
  local content_height = win_height - 3
  local top_pad = math.max(0, math.floor((content_height - #lines) / 2))

  -- Add empty lines at the top
  local centered = {}
  for _ = 1, top_pad do
    table.insert(centered, '')
  end
  for _, line in ipairs(padded_lines) do
    table.insert(centered, line)
  end

  return centered
end

---Show the current slide
function M.show_slide()
  if not M.state.active or #M.state.slides == 0 then
    return
  end

  local slide_path = M.state.slides[M.state.current]
  local lines = vim.fn.readfile(slide_path)
  local win_config = get_float_config()

  -- Center the content within the window
  local centered_lines = center_content(lines, win_config.width, win_config.height)

  local content_fn = function()
    return centered_lines
  end

  local config_fn = function()
    return win_config
  end

  local opts_fn = function()
    return {
      winblend = 0, -- Solid background, no transparency
      winhighlight = 'Normal:PresentNormal,FloatBorder:PresentBorder',
    }
  end

  M.state.float.refresh(content_fn, config_fn, opts_fn)

  -- Setup buffer and enter window after refresh
  local buf = M.state.float.cache.buf_id
  local win = M.state.float.cache.win_id
  if buf then
    vim.bo[buf].filetype = 'markdown'
    setup_keymaps(buf)
  end
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
    -- Set statusline on the float window
    vim.wo[win].statusline = string.format(' Slide %d/%d ', M.state.current, #M.state.slides)
  end

  vim.diagnostic.enable(false)
end

---Go to next slide (wraps around)
function M.next()
  M.state.current = M.state.current % #M.state.slides + 1
  M.show_slide()
end

---Go to previous slide (wraps around)
function M.prev()
  M.state.current = (M.state.current - 2) % #M.state.slides + 1
  M.show_slide()
end

---Start presentation from a directory
---@param dir string Directory containing slides
function M.start(dir)
  local slides = discover_slides(dir)
  if #slides == 0 then
    vim.notify('No markdown slides found in: ' .. dir, vim.log.levels.WARN)
    return
  end

  M.state.active = true
  M.state.slides = slides
  M.state.current = 1
  M.state.float = Float.new()

  save_ui_state()
  apply_presentation_ui()
  create_backdrop()
  M.show_slide()
end

---Stop presentation and restore state
function M.stop()
  if not M.state.active then
    return
  end

  M.state.active = false
  if M.state.float then
    M.state.float.close()
    M.state.float = nil
  end
  close_backdrop()

  restore_ui_state()
  vim.diagnostic.enable(true)
end

---Toggle presentation mode
---@param dir? string Directory containing slides (defaults to current file's directory)
function M.toggle(dir)
  if M.state.active then
    M.stop()
  else
    dir = dir or vim.fn.expand '%:p:h'
    M.start(dir)
  end
end

-- Expose for testing
M._discover_slides = discover_slides

-- User command
vim.api.nvim_create_user_command('Present', function(opts)
  M.toggle(opts.args ~= '' and opts.args or nil)
end, { nargs = '?', complete = 'dir', desc = 'Toggle presentation mode' })

return M
