-- return 7 chars commit hash
local function get_commit_hash()
  local line = vim.api.nvim_get_current_line()
  return string.sub(line, 1, 7)
end

-- Create hints instance
local Hints = require 'user.hints'
local hints = Hints.new('Git Blame - Available Keymaps', {
  { key = '<CR>', desc = 'Open commit in Diffview' },
  { key = 'yy', desc = 'Copy commit hash to clipboard' },
  { key = '<leader>gh', desc = 'Open commit in GitHub' },
})

-- Show hints when entering blame buffer
vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
  buffer = 0,
  callback = function()
    hints.show()
  end,
})

-- Hide hints when leaving blame buffer
vim.api.nvim_create_autocmd({ 'BufLeave', 'WinLeave' }, {
  buffer = 0,
  callback = function()
    hints.close()
  end,
})

local bufnr = vim.api.nvim_get_current_buf()
vim.schedule(function()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  vim.keymap.set('n', '<CR>', function()
    local commit_hash = get_commit_hash()
    vim.notify('Opening Diffview for ' .. commit_hash)
    vim.cmd('DiffviewOpen ' .. commit_hash .. '^!')
  end, { buffer = bufnr, desc = 'Open Diffview' })

  vim.keymap.set('n', 'yy', function()
    local commit_hash = get_commit_hash()
    vim.fn.setreg('+', commit_hash)
    vim.notify(commit_hash .. ' copied to clipboard')
  end, { buffer = bufnr, desc = 'Copy commit hash' })

  vim.keymap.set('n', '<leader>gh', function()
    local commit_hash = get_commit_hash()
    vim.cmd 'wincmd p'
    -- selene: allow(undefined_variable)
    require('user.gitbrowse').open {
      what = 'commit',
      commit = commit_hash,
    }
  end, { buffer = bufnr, desc = 'Open commit hash in browser' })

  -- Show hints immediately
  hints.show()
end)
