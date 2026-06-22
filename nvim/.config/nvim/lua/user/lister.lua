--- Quickfix list filtering (:Qgrep, :Qfilter).
--- Replaces vim-lister for message and filename narrowing.
local M = {}

function M.reset_search_label()
  vim.g.qf_search_term = nil
  vim.g.qf_search_term_id = nil
end

--- Returns the search term only when it belongs to the current qflist.
local function current_label()
  local id = vim.fn.getqflist({ id = 0 }).id
  if id ~= 0 and vim.g.qf_search_term_id == id then
    return vim.g.qf_search_term or ''
  end
  return ''
end

local function set_search_label(label)
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
  local prev = current_label()
  local label
  if prev:sub(-1) == ')' then
    label = prev:sub(1, -2) .. ', ' .. op .. ')'
  elseif prev == '' then
    label = '(' .. op .. ')'
  else
    label = prev .. ' (' .. op .. ')'
  end

  vim.fn.setqflist(filtered)
  set_search_label(label)

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

function M.setup()
  register('Qgrep', 'text', 'Narrow quickfix to entries whose message matches {pattern}')
  register('Qfilter', 'file', 'Narrow quickfix to entries whose file path matches {pattern}')

  require('user.menu').add_actions('Quickfix', {
    ['Narrow quickfix by message (:Qgrep)'] = function()
      vim.ui.input({ prompt = 'Qgrep message pattern❯ ' }, function(pattern)
        if pattern and pattern ~= '' then
          vim.cmd('Qgrep ' .. pattern)
        end
      end)
    end,
    ['Narrow quickfix by file path (:Qfilter)'] = function()
      vim.ui.input({ prompt = 'Qfilter file pattern❯ ' }, function(pattern)
        if pattern and pattern ~= '' then
          vim.cmd('Qfilter ' .. pattern)
        end
      end)
    end,
  })
end

return M
