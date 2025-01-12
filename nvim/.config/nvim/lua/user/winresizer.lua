local M = {}

local function can_move_cursor(dir)
  local from = vim.fn.winnr()
  vim.cmd('wincmd ' .. dir)
  local to = vim.fn.winnr()
  vim.cmd(from .. 'wincmd w')
  return from ~= to
end

local function resize_window(dir, amount)
  local cmd = dir:match '[hl]' and 'vertical resize' or 'resize'
  local sign = can_move_cursor(dir) and '+' or '-'
  vim.cmd(string.format('%s %s%d', cmd, sign, amount))
end

M.setup = function()
  local mappings = {
    ['<M-h>'] = 'h',
    ['<M-j>'] = 'j',
    ['<M-k>'] = 'k',
    ['<M-l>'] = 'l',
  }

  for key, dir in pairs(mappings) do
    vim.keymap.set('n', key, function()
      resize_window(dir, 2)
    end)
  end
end

M.setup()

return M
