local git_funcs = require 'user.git'

-- Create hints instance
-- local Hints = require 'user.hints'
-- local hints = Hints.new('Fugitive - Available Keymaps', {
--   { key = '-', desc = 'Stage/unstage file' },
--   { key = 'X', desc = 'Discard changes' },
--   { key = '=', desc = 'Toggle Inline Diff' },
--   { key = 'cc', desc = 'Commit' },
--   { key = 'dv', desc = 'Vertical diff' },
--   { key = 'gl', desc = 'Pull' },
--   { key = 'gp', desc = 'Push' },
--   { key = 'gf', desc = 'Fetch all' },
--   { key = 'czz', desc = 'Push Stash' },
--   { key = 'cza', desc = 'Apply Stash' },
--   { key = 'pr', desc = 'Pull request' },
--   { key = 'fc', desc = 'First commit' },
--   { key = 'wip', desc = 'Work in progress' },
--   { key = 'R', desc = 'Reload' },
--   { key = '<leader>t', desc = 'Open terminal' },
-- })

-- Show hints when entering fugitive buffer
-- vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
--   buffer = 0,
--   callback = function()
--     hints.show()
--   end,
-- })
--
-- -- Hide hints when leaving fugitive buffer
-- vim.api.nvim_create_autocmd({ 'BufLeave', 'WinLeave' }, {
--   buffer = 0,
--   callback = function()
--     hints.close()
--   end,
-- })

vim.schedule(function()
  local buf = git_funcs.get_fugitive_buffer() or 0
  vim.api.nvim_buf_set_keymap(buf, 'n', '<leader>t', '', {
    noremap = true,
    silent = true,
    desc = 'Open terminal',
    callback = function()
      vim.cmd 'vertical terminal'
    end,
  })

  vim.api.nvim_buf_set_keymap(buf, 'n', 'cc', '', {
    noremap = true,
    silent = true,
    desc = 'Commit',
    callback = function()
      vim.cmd 'silent Git commit --quiet'
    end,
  })

  vim.api.nvim_buf_set_keymap(buf, 'n', 'gl', '', {
    noremap = true,
    silent = true,
    desc = 'Pull',
    callback = git_funcs.pull,
  })

  vim.api.nvim_buf_set_keymap(buf, 'n', 'gp', '', {
    noremap = true,
    silent = true,
    desc = 'Push',
    callback = git_funcs.push,
  })

  vim.api.nvim_buf_set_keymap(buf, 'n', 'gf', '', {
    noremap = true,
    silent = true,
    desc = 'Fetch',
    callback = git_funcs.fetch_all,
  })

  vim.api.nvim_buf_set_keymap(buf, 'n', 'pr', '', {
    noremap = true,
    silent = true,
    desc = 'Pull request',
    callback = function()
      vim.cmd 'silent! Cpr'
    end,
  })

  vim.api.nvim_buf_set_keymap(buf, 'n', 'fc', '', {
    noremap = true,
    silent = true,
    desc = 'First commit',
    callback = git_funcs.first_commit,
  })

  vim.api.nvim_buf_set_keymap(buf, 'n', 'R', '', {
    noremap = true,
    silent = true,
    desc = 'Reload',
    callback = function()
      vim.cmd 'e'
    end,
  })

  vim.api.nvim_buf_set_keymap(buf, 'n', 'wip', '', {
    noremap = true,
    silent = true,
    desc = 'Enter work in progress',
    callback = git_funcs.enter_wip,
  })

  -- Show hints immediately
  -- hints.show()
end)
