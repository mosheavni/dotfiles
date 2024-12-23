vim.b.is_bash = 1

local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or ''
if not first_line:match '^#!' then
  local default_shebang = '#!/bin/bash'
  local cursor = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_buf_set_lines(0, 0, 0, false, { default_shebang })
  -- Preserve cursor position only if we're not at the first line
  if cursor[1] > 1 then
    vim.api.nvim_win_set_cursor(0, { cursor[1] + 1, cursor[2] })
  end
end

vim.keymap.set('n', 'J', function()
  local line = vim.api.nvim_get_current_line()
  if line:match '\\%s*$' then
    local final_line = line:gsub('\\%s*$', '')
    vim.api.nvim_set_current_line(final_line)
  end
  vim.cmd 'normal! J'
end, { buffer = true })
