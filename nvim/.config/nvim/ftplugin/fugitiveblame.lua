-- return 7 chars commit hash
local function get_commit_hash()
  local line = vim.api.nvim_get_current_line()
  return string.sub(line, 1, 7)
end

vim.schedule(function()
  vim.api.nvim_set_option_value(
    'winbar',
    'Git blame (<CR> to open commit in diffview | yy to copy commit hash to clipboard | <leader>gh to open commit in GitHub)',
    { win = 0 }
  )

  vim.api.nvim_buf_set_keymap(0, 'n', '<CR>', '', {
    noremap = true,
    silent = true,
    desc = 'Open Diffview',
    callback = function()
      local commit_hash = get_commit_hash()
      vim.notify('Opening Diffview for ' .. commit_hash)
      vim.cmd('DiffviewOpen ' .. commit_hash .. '^!')
    end,
  })

  vim.api.nvim_buf_set_keymap(0, 'n', 'yy', '', {
    noremap = true,
    silent = true,
    desc = 'Copy commit hash',
    callback = function()
      local commit_hash = get_commit_hash()
      vim.fn.setreg('+', commit_hash)
      vim.notify(commit_hash .. ' copied to clipboard')
    end,
  })

  vim.api.nvim_buf_set_keymap(0, 'n', '<leader>gh', '', {
    noremap = true,
    silent = true,
    desc = 'Open commit hash in browser',
    callback = function()
      local commit_hash = get_commit_hash()
      vim.cmd 'wincmd p'
      -- selene: allow(undefined_variable)
      require('user.gitbrowse').open {
        what = 'commit',
        commit = commit_hash,
      }
    end,
  })
end)
