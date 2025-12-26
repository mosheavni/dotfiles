local M = {}

---@type integer
local EASYMOTION_NS = vim.api.nvim_create_namespace 'EASYMOTION_NS'
---@type string[]
local EM_CHARS = vim.split('fjdkslgha;rueiwotyqpvbcnxmzFJDKSLGHARUEIWOTYQPVBCNXMZ', '')

--- Jump to a location by typing 2 characters
--- If only one match is found, jumps automatically
--- If multiple matches are found, shows overlay characters to select from
function M.easy_motion()
  ---@type string
  local char1 = vim.fn.nr2char(vim.fn.getchar() --[[@as number]])
  ---@type string
  local char2 = vim.fn.nr2char(vim.fn.getchar() --[[@as number]])
  ---@type integer, integer
  local line_idx_start, line_idx_end = vim.fn.line 'w0', vim.fn.line 'w$'
  ---@type integer
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, EASYMOTION_NS, 0, -1)

  ---@type integer
  local char_idx = 1
  ---@type table<string, {line: integer, col: integer, id: integer}>
  local extmarks = {}
  ---@type string[]
  local lines = vim.api.nvim_buf_get_lines(bufnr, line_idx_start - 1, line_idx_end, false)
  ---@type string
  local needle = char1 .. char2

  ---@type boolean
  local is_case_sensitive = needle ~= string.lower(needle)

  ---@type boolean
  local done = false
  for lines_i, line_text in ipairs(lines) do
    if done then
      break
    end
    if not is_case_sensitive then
      line_text = string.lower(line_text)
    end
    ---@type integer
    local line_idx = lines_i + line_idx_start - 1
    -- skip folded lines
    if vim.fn.foldclosed(line_idx) == -1 then
      for i = 1, #line_text do
        if line_text:sub(i, i + 1) == needle and char_idx <= #EM_CHARS then
          ---@type string
          local overlay_char = EM_CHARS[char_idx]
          ---@type integer
          local linenr = line_idx_start + lines_i - 2
          ---@type integer
          local col = i - 1
          ---@type integer
          local id = vim.api.nvim_buf_set_extmark(bufnr, EASYMOTION_NS, linenr, col + 2, {
            virt_text = { { overlay_char, 'CurSearch' } },
            virt_text_pos = 'overlay',
            hl_mode = 'replace',
          })
          extmarks[overlay_char] = { line = linenr, col = col, id = id }
          char_idx = char_idx + 1
          if char_idx > #EM_CHARS then
            done = true
            break
          end
        end
      end
    end
  end

  -- If no matches found, just return
  if char_idx == 1 then
    return
  end

  -- If only one match, jump directly without waiting for input
  if char_idx == 2 then
    ---@type string
    local first_char = EM_CHARS[1]
    ---@type {line: integer, col: integer, id: integer}
    local pos = extmarks[first_char]
    vim.cmd "normal! m'"
    vim.api.nvim_win_set_cursor(0, { pos.line + 1, pos.col })
    vim.api.nvim_buf_clear_namespace(bufnr, EASYMOTION_NS, 0, -1)
    return
  end

  -- Multiple matches: wait for user to select which one
  -- otherwise setting extmarks and waiting for next char is on the same frame
  vim.schedule(function()
    ---@type string
    local next_char = vim.fn.nr2char(vim.fn.getchar() --[[@as number]])
    if extmarks[next_char] then
      ---@type {line: integer, col: integer, id: integer}
      local pos = extmarks[next_char]
      -- to make <C-o> work
      vim.cmd "normal! m'"
      vim.api.nvim_win_set_cursor(0, { pos.line + 1, pos.col })
    end
    -- clear extmarks
    vim.api.nvim_buf_clear_namespace(0, EASYMOTION_NS, 0, -1)
  end)
end

return M
