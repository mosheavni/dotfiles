-- nvim-lint linter: brew bundle check --verbose
local M = {}

local ENTRY_PATTERN = '^(%w+)%s+["\']([^"\']+)["\']'
local VALID_KINDS = { tap = true, brew = true, cask = true }
local MISSING_PATTERN = '^→ (%u%l+) ([^ ]+) needs to be installed or updated%.$'
local INVALID_BREWFILE_PATTERN = '^Error: Invalid Brewfile: (.+)$'
local UNDEFINED_NAME_PATTERN = '[\'"]([^\'"]+)[\'"] for an instance of'
local BREWFILE_LINE_PATTERN = 'Brewfile:(%d+):'

--- Return 1-based line number for a tap/brew/cask entry matching `name`.
---@param bufnr integer
---@param name string
---@return integer|nil lnum
function M.find_entry_line(bufnr, name)
  for lnum, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    local kind, entry_name = line:match(ENTRY_PATTERN)
    if kind and VALID_KINDS[kind] and entry_name and (entry_name == name or entry_name:match('/' .. vim.pesc(name) .. '$')) then
      return lnum
    end
  end
  return nil
end

--- Return 1-based line number where `token` appears as a word.
---@param bufnr integer
---@param token string
---@return integer|nil lnum
function M.find_token_line(bufnr, token)
  local pattern = '%f[%w_]' .. vim.pesc(token) .. '%f[%W_]'
  for lnum, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    if line:find(pattern) then
      return lnum
    end
  end
  return nil
end

--- First 1-based Brewfile line from a Ruby-style backtrace, if present.
---@param output string
---@return integer|nil lnum
function M.parse_brewfile_backtrace_line(output)
  for line in (output .. '\n'):gmatch '(.-)\n' do
    local lnum = line:match(BREWFILE_LINE_PATTERN)
    if lnum then
      return tonumber(lnum)
    end
  end
  return nil
end

--- Parse `brew bundle check --verbose` output into diagnostics.
---@param output string
---@param bufnr integer
---@return vim.Diagnostic[]
function M.parse_output(output, bufnr)
  local diagnostics = {}
  local backtrace_line_1 = M.parse_brewfile_backtrace_line(output)

  for line in (output .. '\n'):gmatch '(.-)\n' do
    local _, name = line:match(MISSING_PATTERN)
    if name then
      local line_1 = M.find_entry_line(bufnr, name)
      if line_1 then
        table.insert(diagnostics, {
          lnum = line_1 - 1,
          col = 0,
          message = line,
          severity = vim.diagnostic.severity.WARN,
          source = 'brew-bundle',
        })
      end
    end

    local invalid_msg = line:match(INVALID_BREWFILE_PATTERN)
    if invalid_msg then
      local line_1 = backtrace_line_1
      if not line_1 then
        local token = invalid_msg:match(UNDEFINED_NAME_PATTERN)
        if token then
          line_1 = M.find_token_line(bufnr, token)
        end
      end
      table.insert(diagnostics, {
        lnum = (line_1 or 1) - 1,
        col = 0,
        message = invalid_msg,
        severity = vim.diagnostic.severity.ERROR,
        source = 'brew-bundle',
      })
    end
  end

  return diagnostics
end

M.linter = {
  cmd = 'brew',
  args = {
    'bundle',
    'check',
    '--verbose',
    '--file',
  },
  stdin = false,
  stream = 'both',
  ignore_exitcode = true,
  parser = function(output, bufnr)
    return M.parse_output(output, bufnr)
  end,
}

return M
