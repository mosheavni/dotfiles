---@class user.ftplugin.ShellOpts
---@field shebang string
---@field buffer_flag? string vim.b key set to 1 for this shell type

local function shell_setup(opts)
  opts = vim.tbl_extend('force', {
    shebang = '#!/bin/bash',
    buffer_flag = 'is_bash',
  }, opts or {})

  if opts.buffer_flag then
    vim.b[opts.buffer_flag] = 1
  end

  local bufname = vim.api.nvim_buf_get_name(0)
  local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or ''
  if not first_line:match '^#!' and not bufname:match '^/private/tmp/zsh%w+%.zsh$' then
    local cursor = vim.api.nvim_win_get_cursor(0)
    vim.api.nvim_buf_set_lines(0, 0, 0, false, { opts.shebang })
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
end

return {
  shell = {
    setup = shell_setup,
  },
}
