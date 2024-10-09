--- @param s string
--- @param t string
local function string_endswith(s, t)
  return string.len(s) >= string.len(t) and string.sub(s, #s - #t + 1) == t
end

local function get_commit_hash()
  local line = vim.api.nvim_get_current_line()
  return string.match(line, '(%x+)')
end
-- set winbar to empty string
-- vim.api.nvim_win_set_option(0, 'winbar', '-')
vim.schedule(function()
  vim.api.nvim_set_option_value('winbar', 'Git blame', { win = 0 })
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
      require('gitlinker').link {
        action = function(url)
          vim.ui.open(url)
        end,
        router = function(lk)
          local builder = 'https://'
            .. lk.host
            .. '/'
            .. lk.org
            .. '/'
            .. (string_endswith(lk.repo, '.git') and lk.repo:sub(1, #lk.repo - 4) or lk.repo)
            .. '/'
            .. 'commit/'
            .. lk.rev
          return builder
        end,
        rev = commit_hash,
      }
    end,
  })
end)
