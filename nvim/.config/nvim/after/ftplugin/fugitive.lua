local git_funcs = require 'user.git'

-- Create hints instance
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

local Hints = require 'user.hints'
local hints = Hints.new('Fugitive - Available Keymaps', {
  { key = '<CR>', desc = 'Open file or reveal directory in NvimTree' },
  { key = '<C-v>', desc = 'Open in vertical split' },
  { key = '<C-s>', desc = 'Open in horizontal split' },
  { key = '<C-t>', desc = 'Open in new tab' },
  { key = '-', desc = 'Stage/unstage file' },
  { key = 'X', desc = 'Discard changes' },
  { key = '=', desc = 'Toggle Inline Diff' },
  { key = 'cc', desc = 'Commit' },
  { key = 'dv', desc = 'Vertical diff' },
  { key = 'gl', desc = 'Pull' },
  { key = 'gp', desc = 'Push' },
  { key = 'gf', desc = 'Fetch all' },
  { key = 'czz', desc = 'Push Stash' },
  { key = 'cza', desc = 'Apply Stash' },
  { key = 'pr', desc = 'Pull request' },
  { key = 'fc', desc = 'First commit' },
  { key = 'wip', desc = 'Work in progress' },
  { key = 'R', desc = 'Reload' },
  { key = '<leader>t', desc = 'Open terminal' },
  { key = '<leader>h', desc = 'Toggle Hints' },
})

vim.g.fugitive_hints = false

-- Toggle hints on fugitive
vim.keymap.set('n', '<leader>h', function()
  if vim.bo.filetype ~= 'fugitive' then
    return
  end
  vim.g.fugitive_hints = not vim.g.fugitive_hints
  if vim.g.fugitive_hints then
    hints.show()
  else
    hints.close()
  end
end, { desc = 'Toggle Fugitive hints (only in fugitive buffers)' })

-- Show hints when entering fugitive buffer
vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
  buffer = 0,
  callback = function()
    if vim.g.fugitive_hints and vim.bo.filetype == 'fugitive' then
      hints.show()
    end
  end,
})

-- Hide hints when leaving fugitive buffer
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

  -- Show hints immediately
  -- hints.show()
end)
