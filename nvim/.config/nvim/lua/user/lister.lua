--- Quickfix list filtering (:Qgrep, :Qfilter).
--- Replaces vim-lister for message and filename narrowing.
local M = {}

local history = {}
local history_index = 0

---@param list table[]
---@return table[]
local function copy_qflist(list)
  return vim.deepcopy(list)
end

---@param a table
---@param b table
---@return boolean
local function qf_entry_equal(a, b)
  return (a.text or '') == (b.text or '')
    and (a.filename or '') == (b.filename or '')
    and (a.lnum or 0) == (b.lnum or 0)
    and (a.col or 0) == (b.col or 0)
    and (a.bufnr or 0) == (b.bufnr or 0)
end

---@param a table[]
---@param b table[]
---@return boolean
function M.qflist_equal(a, b)
  if #a ~= #b then
    return false
  end
  for i = 1, #a do
    if not qf_entry_equal(a[i], b[i]) then
      return false
    end
  end
  return true
end

function M.reset_history()
  history = {}
  history_index = 0
end

---@param list table[]
local function restore_qflist(list)
  vim.fn.setqflist(copy_qflist(list), 'r')
end

local function history_status_message()
  if history_index == 0 then
    return nil
  end
  return string.format('quickfix history %d/%d', history_index, #history)
end

---@param notify_when_empty boolean
---@return boolean
local function history_back(notify_when_empty)
  if history_index <= 1 then
    if notify_when_empty then
      vim.notify('Already at oldest quickfix state', vim.log.levels.INFO)
    end
    return false
  end
  history_index = history_index - 1
  restore_qflist(history[history_index])
  local msg = history_status_message()
  if msg then
    vim.notify(msg, vim.log.levels.INFO)
  end
  return true
end

---@param notify_when_empty boolean
---@return boolean
local function history_forward(notify_when_empty)
  if history_index >= #history then
    if notify_when_empty then
      vim.notify('Already at newest quickfix state', vim.log.levels.INFO)
    end
    return false
  end
  history_index = history_index + 1
  restore_qflist(history[history_index])
  local msg = history_status_message()
  if msg then
    vim.notify(msg, vim.log.levels.INFO)
  end
  return true
end

function M.undo()
  return history_back(true)
end

function M.redo()
  return history_forward(true)
end

---@return number
function M.history_index()
  return history_index
end

---@return number
function M.history_size()
  return #history
end

local function truncate_forward_history()
  for i = #history, history_index + 1, -1 do
    history[i] = nil
  end
end

---@param list table[]
local function record_before_filter(list)
  truncate_forward_history()
  if history_index == 0 then
    history_index = 1
    history[1] = copy_qflist(list)
    return
  end
  if not M.qflist_equal(history[history_index], list) then
    history_index = history_index + 1
    history[history_index] = copy_qflist(list)
  end
end

---@param list table[]
local function record_after_filter(list)
  history_index = history_index + 1
  history[history_index] = copy_qflist(list)
end

--- Case-sensitive Vim regex match (same as =~# / !~# in vim-lister).
---@param haystack string
---@param pattern string
---@param invert boolean
function M.matches(haystack, pattern, invert)
  local escaped_hay = vim.fn.escape(haystack or '', '"\\')
  local escaped_pat = vim.fn.escape(pattern, '"\\')
  local op = invert and '!~#' or '=~#'
  local expr = string.format('"%s" %s "%s"', escaped_hay, op, escaped_pat)
  return vim.fn.eval(expr) == 1
end

--- File path for a quickfix entry (same source as vim-lister: bufname).
---@param item table
---@return string
function M.qf_filename(item)
  if item.bufnr and item.bufnr > 0 and vim.api.nvim_buf_is_valid(item.bufnr) then
    local name = vim.fn.bufname(item.bufnr)
    if name ~= '' then
      return name
    end
  end
  if item.filename and item.filename ~= '' then
    return item.filename
  end
  return ''
end

---@param pattern string
---@param field 'text'|'file'
---@param invert boolean
function M.filter(pattern, field, invert)
  local list = vim.fn.getqflist()
  local count_before = #list
  record_before_filter(list)

  local filtered = vim.tbl_filter(function(item)
    local haystack = field == 'text' and (item.text or '') or M.qf_filename(item)
    return M.matches(haystack, pattern, invert)
  end, list)

  vim.fn.setqflist(filtered)
  record_after_filter(filtered)

  vim.api.nvim_echo({
    { tostring(count_before), '' },
    { ' quickfix entries reduced to ', '' },
    { tostring(#filtered), '' },
  }, false, {})

  if #filtered == 0 and count_before > 0 and not invert then
    local hint = field == 'file'
        and (':Qfilter matches file paths only; use :Qgrep ' .. pattern .. ' to match line text')
      or (':Qgrep matches line text only; use :Qfilter ' .. pattern .. ' to match file paths')
    vim.notify(hint, vim.log.levels.INFO)
  end
end

local function register(name, field, desc)
  vim.api.nvim_create_user_command(name, function(opts)
    if opts.args == '' then
      vim.notify(name .. ': pattern required', vim.log.levels.ERROR)
      return
    end
    M.filter(opts.args, field, opts.bang)
  end, { nargs = 1, bang = true, desc = desc })
end

local function setup_qf_keymaps()
  vim.keymap.set('n', '<', function()
    M.undo()
  end, { buffer = true, desc = 'Lister: older quickfix filter state' })

  vim.keymap.set('n', '>', function()
    M.redo()
  end, { buffer = true, desc = 'Lister: newer quickfix filter state' })
end

function M.setup()
  register('Qgrep', 'text', 'Narrow quickfix to entries whose message matches {pattern}')
  register('Qfilter', 'file', 'Narrow quickfix to entries whose file path matches {pattern}')

  vim.api.nvim_create_autocmd('QuickFixCmdPost', {
    callback = M.reset_history,
    desc = 'Reset lister quickfix filter history on new quickfix commands',
  })

  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'qf',
    callback = setup_qf_keymaps,
    desc = 'Lister undo/redo in quickfix window',
  })
end

return M
