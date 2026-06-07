local utils = require 'user.utils'

local M = {}
local esc = vim.keycode '<Esc>'

---@param pattern string
---@param line string
---@return boolean
function M.line_matches(pattern, line)
  return pattern ~= '' and vim.fn.match(line, '\\V' .. vim.fn.escape(pattern, '\\')) ~= -1
end

---@param lines string[]
---@param pattern string
---@param matching boolean
---@return string[]
function M.select_lines(lines, pattern, matching)
  local result = {}
  for _, line in ipairs(lines) do
    if M.line_matches(pattern, line) == matching then
      result[#result + 1] = line
    end
  end
  return result
end

---@return { pattern: string, lines: string[] }?
local function visual_context()
  local pattern = table.concat(utils.get_visual_selection_stay_in_visual(), '\n')
  vim.api.nvim_feedkeys(esc, 'n', false)
  if pattern == '' then
    return
  end
  return { pattern = pattern, lines = vim.api.nvim_buf_get_lines(0, 0, -1, false) }
end

---@param matching boolean
function M.delete(matching)
  local ctx = visual_context()
  if not ctx then
    return
  end
  local saved = vim.fn.getreg '"'
  vim.api.nvim_buf_set_lines(0, 0, -1, false, M.select_lines(ctx.lines, ctx.pattern, matching))
  vim.fn.setreg('"', saved)
  vim.cmd.noh()
end

---@param matching boolean
function M.yank(matching)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local ctx = visual_context()
  if not ctx then
    return
  end
  local saved = vim.fn.getreg '"'
  vim.fn.setreg('E', table.concat(M.select_lines(ctx.lines, ctx.pattern, matching), '\n'), 'l')
  vim.fn.setreg('"', saved)
  vim.api.nvim_win_set_cursor(0, cursor)
  vim.cmd.noh()
end

return M
