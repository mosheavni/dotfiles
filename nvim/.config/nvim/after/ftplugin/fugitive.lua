local git_funcs = require 'user.git'

local function porcelain_path()
  local esc = vim.fn['fugitive#PorcelainCfile']()
  if esc == '' then
    return nil, nil
  end
  return esc, esc:gsub('\\(.)', '%1')
end

local function open_directory(path)
  local ok, api = pcall(require, 'nvim-tree.api')
  if ok then
    api.tree.find_file { buf = path, open = true, focus = true, update_root = false }
  end
end

local function open_fugitive(mode)
  local esc, path = porcelain_path()
  if not esc or not path then
    return
  end
  if vim.fn.isdirectory(path) == 1 then
    if mode == 'edit' then
      open_directory(path)
    end
    return
  end
  if mode == 'edit' then
    vim.cmd('Gedit ' .. esc)
  else
    vim.cmd 'wincmd p'
    vim.cmd(('G%s %s'):format(mode, esc))
  end
end

local bufnr = vim.api.nvim_get_current_buf()
vim.schedule(function()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  vim.keymap.set('n', '<leader>t', function()
    vim.cmd 'vertical terminal'
  end, { buffer = bufnr, desc = 'Open terminal' })

  vim.keymap.set('n', 'cc', function()
    vim.cmd 'silent Git commit --quiet'
  end, { buffer = bufnr, desc = 'Commit' })

  vim.keymap.set('n', 'gl', git_funcs.pull, { buffer = bufnr, desc = 'Pull' })
  vim.keymap.set('n', 'gp', git_funcs.push, { buffer = bufnr, desc = 'Push' })
  vim.keymap.set('n', 'gf', git_funcs.fetch_all, { buffer = bufnr, desc = 'Fetch' })

  vim.keymap.set('n', 'pr', function()
    vim.cmd 'silent! Cpr'
  end, { buffer = bufnr, desc = 'Pull request' })

  vim.keymap.set('n', 'fc', git_funcs.first_commit, { buffer = bufnr, desc = 'First commit' })

  vim.keymap.set('n', 'R', function()
    vim.cmd 'e'
  end, { buffer = bufnr, desc = 'Reload' })

  vim.keymap.set('n', 'wip', git_funcs.enter_wip, { buffer = bufnr, desc = 'Enter work in progress' })

  vim.keymap.set('n', '<CR>', function()
    open_fugitive 'edit'
  end, { buffer = bufnr, desc = 'Open file or reveal directory in NvimTree' })

  vim.keymap.set('n', '<c-v>', function()
    open_fugitive 'vsplit'
  end, { buffer = bufnr, desc = 'Open in vertical split' })

  vim.keymap.set('n', '<C-s>', function()
    open_fugitive 'split'
  end, { buffer = bufnr, desc = 'Open in horizontal split' })

  vim.keymap.set('n', '<C-t>', function()
    open_fugitive 'tabedit'
  end, { buffer = bufnr, desc = 'Open in new tab' })
end)
