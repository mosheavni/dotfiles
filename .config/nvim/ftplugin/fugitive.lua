local git_funcs = require 'user.git'

vim.schedule(function()
  vim.api.nvim_buf_set_keymap(0, 'n', '<leader>t', '', {
    noremap = true,
    silent = true,
    desc = 'Open terminal',
    callback = function()
      vim.cmd 'vertical terminal'
    end,
  })

  vim.api.nvim_buf_set_keymap(0, 'n', 'cc', '', {
    noremap = true,
    silent = true,
    desc = 'Commit',
    callback = function()
      vim.cmd 'silent Git commit --quiet'
    end,
  })

  vim.api.nvim_buf_set_keymap(0, 'n', 'gl', '', {
    noremap = true,
    silent = true,
    desc = 'Pull',
    callback = git_funcs.pull,
  })

  vim.api.nvim_buf_set_keymap(0, 'n', 'gp', '', {
    noremap = true,
    silent = true,
    desc = 'Push',
    callback = git_funcs.push,
  })

  vim.api.nvim_buf_set_keymap(0, 'n', 'gf', '', {
    noremap = true,
    silent = true,
    desc = 'Fetch',
    callback = git_funcs.fetch_all,
  })

  vim.api.nvim_buf_set_keymap(0, 'n', 'pr', '', {
    noremap = true,
    silent = true,
    desc = 'Pull request',
    callback = function()
      vim.cmd 'silent! Cpr'
    end,
  })

  vim.api.nvim_buf_set_keymap(0, 'n', 'fc', '', {
    noremap = true,
    silent = true,
    desc = 'First commit',
    callback = git_funcs.first_commit,
  })

  vim.api.nvim_buf_set_keymap(0, 'n', 'R', '', {
    noremap = true,
    silent = true,
    desc = 'Reload',
    callback = function()
      vim.cmd 'e'
    end,
  })

  vim.api.nvim_buf_set_keymap(0, 'n', 'wip', '', {
    noremap = true,
    silent = true,
    desc = 'Enter work in progress',
    callback = git_funcs.enter_wip,
  })
end)
