-- ShellCheck code actions for the user LSP server
-- Adapted from none-ls-shellcheck.nvim

local api = vim.api

local M = {}

-- Regex patterns
local blank_or_comment_line_regex = vim.regex [[^\s*\(#.*\)\?$]]
local shebang_regex = vim.regex [[^#!]]
local multiline_command_regex = vim.regex [[^.*\\$]]
local shellcheck_disable_regex = vim.regex [[^\s*#\s*shellcheck\s\+disable=\(\(SC\)\?\d\+\)\([,-]\(SC\)\?\d\+\)*\s*$]]
local shellcheck_disable_pattern = '^%s*#%s*shellcheck%s+disable=([^%s]*)%s*$'

--- Search a region of the buffer for a regex match
---@param bufnr number
---@param regex any
---@param row_start number
---@param row_end number
---@param continue_regex any|nil
---@param invert boolean|nil
---@return string|nil, number|nil
local function search_region(bufnr, regex, row_start, row_end, continue_regex, invert)
  invert = invert ~= nil and invert or false
  local region_start, region_end
  local idx_start, idx_end, step

  if row_start > row_end then
    region_start = row_end
    region_end = row_start
    idx_start = row_start - row_end
    idx_end = 1
    step = -1
  else
    region_start = row_start
    region_end = row_end
    idx_start = 1
    idx_end = row_end - row_start
    step = 1
  end

  local lines = api.nvim_buf_get_lines(bufnr, region_start, region_end, false)
  for i = idx_start, idx_end, step do
    local line = lines[i]
    if line == nil then
      return nil, nil
    end
    local match = regex:match_str(line) ~= nil
    if match == not invert then
      return line, i + (step == 1 and row_start or row_end)
    end
    if continue_regex and not continue_regex:match_str(line) then
      return nil, nil
    end
  end
  return nil, nil
end

local function get_first_non_shebang_row(bufnr)
  return shebang_regex:match_line(bufnr, 0) and 1 or 0
end

local function get_first_non_comment_row(bufnr, row)
  local first_non_shebang_row = get_first_non_shebang_row(bufnr)
  local _, match_row = search_region(bufnr, blank_or_comment_line_regex, first_non_shebang_row, row, nil, true)
  return match_row
end

local function find_disable_directive(bufnr, row_start, row_end)
  local line, row = search_region(bufnr, shellcheck_disable_regex, row_start, row_end, blank_or_comment_line_regex)
  if line then
    return {
      codes = line:match(shellcheck_disable_pattern),
      row = row,
    }
  end
  return nil
end

local function get_file_directive(bufnr)
  local row_start = get_first_non_shebang_row(bufnr)
  local row_end = api.nvim_buf_line_count(bufnr)
  return find_disable_directive(bufnr, row_start, row_end)
end

local function get_line_directive(bufnr, row)
  local file_directive = get_file_directive(bufnr)
  local row_start = row - 1
  local row_end = file_directive and file_directive.row or get_first_non_shebang_row(bufnr)
  return find_disable_directive(bufnr, row_start, row_end)
end

local function disable_action(bufnr, existing_directive, default_line, code, indentation)
  local codes = code
  local row_start = default_line - 1
  local row_end = default_line - 1

  if existing_directive then
    codes = existing_directive.codes .. ',' .. codes
    row_start = existing_directive.row - 1
    row_end = existing_directive.row
  end

  local directive = indentation .. '# shellcheck disable=' .. codes
  api.nvim_buf_set_lines(bufnr, row_start, row_end, false, { directive })
end

local function generate_file_disable_action(bufnr, code)
  return {
    title = 'Disable ShellCheck rule ' .. code .. ' for the entire file',
    kind = 'quickfix',
    action = function()
      disable_action(bufnr, get_file_directive(bufnr), get_first_non_shebang_row(bufnr) + 1, code, '')
    end,
  }
end

local function generate_line_disable_action(bufnr, row, code)
  if get_first_non_comment_row(bufnr, row) == row then
    return nil
  end

  local _, match_row = search_region(bufnr, multiline_command_regex, row - 1, 0, nil, true)
  if match_row == nil then
    return nil
  end

  row = match_row + 1
  local line = api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
  local indentation = line:match '^%s+' or ''

  return {
    title = 'Disable ShellCheck rule ' .. code .. ' for this line',
    kind = 'quickfix',
    action = function()
      disable_action(bufnr, get_line_directive(bufnr, row), row, code, indentation)
    end,
  }
end

--- Run shellcheck and parse output
---@param bufnr number
---@return table[] comments
local function run_shellcheck(bufnr)
  local content = table.concat(api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n')
  local result = vim
    .system({ 'shellcheck', '--format', 'json1', '--source-path=SCRIPTDIR', '--external-sources', '-' }, {
      stdin = content,
    })
    :wait()

  if result.code > 1 then
    return {}
  end

  local ok, parsed = pcall(vim.json.decode, result.stdout)
  if not ok or not parsed or not parsed.comments then
    return {}
  end

  return parsed.comments
end

--- Get shellcheck code actions for the given context
---@param context table
---@return table[] actions
function M.get_actions(context)
  if context.filetype ~= 'sh' and context.filetype ~= 'bash' then
    return {}
  end

  local bufnr = context.bufnr
  local row = context.range.row

  -- Run shellcheck to get comments
  local comments = run_shellcheck(bufnr)
  if #comments == 0 then
    return {}
  end

  local actions = {}
  local seen_codes = {}

  for _, comment in ipairs(comments) do
    if comment.line == row then
      local code = 'SC' .. comment.code
      if not seen_codes[code] then
        seen_codes[code] = true

        -- File-level disable action
        table.insert(actions, generate_file_disable_action(bufnr, code))

        -- Line-level disable action
        local line_action = generate_line_disable_action(bufnr, row, code)
        if line_action then
          table.insert(actions, line_action)
        end
      end
    end
  end

  return actions
end

return M
