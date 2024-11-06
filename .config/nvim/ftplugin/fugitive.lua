local actions_pretty_print = function(message)
  require('user.utils').pretty_print(message, 'Git Actions', '')
end

local function random_emoji()
  local emojis = {
    '🤩',
    '👻',
    '😈',
    '✨',
    '👰',
    '👑',
    '💯',
    '💖',
    '🌒',
    '🇮🇱',
    '★',
    '⚓️',
    '🙉',
    '☘️',
    '🌍',
    '🥨',
    '🔥',
    '🚀',
  }
  return emojis[math.random(#emojis)]
end

local function first_commit()
  local head = vim.fn.FugitiveHead()
  vim.notify('Committing: ' .. head)
  vim.cmd('silent! Git commit --quiet -m ' .. head)
  vim.cmd('silent! Git push -u origin ' .. head)
  vim.cmd 'silent! !cpr'
end

local function enter_wip()
  local emoji = random_emoji()
  local now = vim.fn.strftime '%c'
  local msg = string.format('%s work in progress %s', emoji, now)
  vim.notify('Committing: ' .. msg)
  vim.cmd('silent Git commit --quiet -m "' .. msg .. '"')
  vim.cmd('silent Git push -u origin ' .. vim.fn.FugitiveHead())
end

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
    callback = function()
      actions_pretty_print 'Pulling...'
      vim.cmd 'silent Git pull --quiet'
    end,
  })

  vim.api.nvim_buf_set_keymap(0, 'n', 'gp', '', {
    noremap = true,
    silent = true,
    desc = 'Push',
    callback = function()
      actions_pretty_print 'Pushing...'
      vim.cmd('silent Git push -u origin ' .. vim.fn.FugitiveHead())
    end,
  })

  vim.api.nvim_buf_set_keymap(0, 'n', 'gf', '', {
    noremap = true,
    silent = true,
    desc = 'Fetch',
    callback = function()
      actions_pretty_print 'Fetching...'
      vim.cmd 'silent Git fetch --all --tags'
    end,
  })

  vim.api.nvim_buf_set_keymap(0, 'n', 'pr', '', {
    noremap = true,
    silent = true,
    desc = 'Pull request',
    callback = function()
      vim.cmd 'silent! !cpr'
    end,
  })

  vim.api.nvim_buf_set_keymap(0, 'n', 'fc', '', {
    noremap = true,
    silent = true,
    desc = 'First commit',
    callback = first_commit,
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
    callback = enter_wip,
  })
end)
