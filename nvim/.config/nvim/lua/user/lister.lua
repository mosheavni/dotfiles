--- Quickfix list filtering (:Qgrep, :Qfilter).
--- Replaces vim-lister for message and filename narrowing.
local M = {}

local history = {}
local history_labels = {}
local history_index = 0

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
  history_labels = {}
  history_index = 0
  vim.g.qf_search_term = nil
  vim.g.qf_search_term_id = nil
end

---@param list table[]
local function restore_qflist(list)
  vim.fn.setqflist(list, 'r')
end

local function apply_history(idx)
  restore_qflist(history[idx])
  vim.g.qf_search_term = history_labels[idx] or ''
  vim.g.qf_search_term_id = vim.fn.getqflist({ id = 0 }).id
  vim.notify(string.format('quickfix history %d/%d', idx, #history), vim.log.levels.INFO)
end

---@return boolean
function M.undo()
  if history_index <= 1 then
    vim.notify('Already at oldest quickfix state', vim.log.levels.INFO)
    return false
  end
  history_index = history_index - 1
  apply_history(history_index)
  return true
end

---@return boolean
function M.redo()
  if history_index >= #history then
    vim.notify('Already at newest quickfix state', vim.log.levels.INFO)
    return false
  end
  history_index = history_index + 1
  apply_history(history_index)
  return true
end

local function truncate_forward_history()
  for i = #history, history_index + 1, -1 do
    history[i] = nil
    history_labels[i] = nil
  end
end

--- Returns the search term only when it belongs to the current qflist.
local function current_label()
  local id = vim.fn.getqflist({ id = 0 }).id
  if id ~= 0 and vim.g.qf_search_term_id == id then
    return vim.g.qf_search_term or ''
  end
  return ''
end

---@param list table[]
local function record_before_filter(list)
  truncate_forward_history()
  if history_index == 0 then
    history_index = 1
    history[1] = list
    history_labels[1] = current_label()
    return
  end
  if not M.qflist_equal(history[history_index], list) then
    history_index = history_index + 1
    history[history_index] = list
    history_labels[history_index] = current_label()
  end
end

---@param list table[]
---@param label string
local function record_after_filter(list, label)
  history_index = history_index + 1
  history[history_index] = list
  history_labels[history_index] = label
  vim.g.qf_search_term = label
  vim.g.qf_search_term_id = vim.fn.getqflist({ id = 0 }).id
end

--- Case-sensitive Vim regex match (same as =~# / !~# in vim-lister).
---@param haystack string
---@param pattern string
---@param invert boolean
function M.matches(haystack, pattern, invert)
  local ok, re = pcall(vim.regex, '\\C' .. pattern)
  if not ok then
    return false
  end
  local matched = re:match_str(haystack or '') ~= nil
  return invert ~= matched
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

  local ok, re = pcall(vim.regex, '\\C' .. pattern)
  local filtered = vim.tbl_filter(function(item)
    if not ok then
      return false
    end
    local haystack = field == 'text' and (item.text or '') or M.qf_filename(item)
    local matched = re:match_str(haystack) ~= nil
    return invert ~= matched
  end, list)

  local op = (field == 'text' and 'grep' or 'file') .. ': ' .. (invert and '!' or '') .. pattern
  local prev = history_labels[history_index] or ''
  local label
  if prev:sub(-1) == ')' then
    label = prev:sub(1, -2) .. ', ' .. op .. ')'
  elseif prev == '' then
    label = '(' .. op .. ')'
  else
    label = prev .. ' (' .. op .. ')'
  end

  vim.fn.setqflist(filtered)
  record_after_filter(filtered, label)

  vim.api.nvim_echo({
    { tostring(count_before), '' },
    { ' quickfix entries reduced to ', '' },
    { tostring(#filtered), '' },
  }, false, {})

  if #filtered == 0 and count_before > 0 and not invert then
    local hint = field == 'file' and (':Qfilter matches file paths only; use :Qgrep ' .. pattern .. ' to match line text')
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
  vim.keymap.set('n', '<', M.undo, { buffer = true, desc = 'Lister: older quickfix filter state' })
  vim.keymap.set('n', '>', M.redo, { buffer = true, desc = 'Lister: newer quickfix filter state' })
end

function M.setup()
  register('Qgrep', 'text', 'Narrow quickfix to entries whose message matches {pattern}')
  register('Qfilter', 'file', 'Narrow quickfix to entries whose file path matches {pattern}')

  vim.api.nvim_create_autocmd('QuickFixCmdPre', {
    callback = function()
      local list = vim.fn.getqflist()
      if #list > 0 then
        record_before_filter(list)
      end
    end,
    desc = 'Save current quickfix list to history before any quickfix command',
  })

  vim.api.nvim_create_autocmd('QuickFixCmdPost', {
    callback = function()
      vim.schedule(function()
        local list = vim.fn.getqflist()
        if #list == 0 then
          return
        end
        if history_index == 0 or not M.qflist_equal(history[history_index], list) then
          history_index = history_index + 1
          history[history_index] = list
          history_labels[history_index] = current_label()
        end
      end)
    end,
    desc = 'Add new quickfix list to history after any quickfix command',
  })

  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'qf',
    callback = setup_qf_keymaps,
    desc = 'Lister undo/redo in quickfix window',
  })
end

return M
