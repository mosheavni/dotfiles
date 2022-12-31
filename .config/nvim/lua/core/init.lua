function _G.put_text(...)
  local objects = {}
  for i = 1, select('#', ...) do
    local v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  local lines = vim.split(table.concat(objects, '\n'), '\n')
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  vim.fn.append(lnum, lines)
  return ...
end

function _G.P(v, r)
  if r then
    print(vim.inspect(v))
  else
    vim.notify(vim.inspect(v), 4, {
      title = 'P debug',
      icon = '✎',
    })
  end
  return v
end
-- leader key - before mapping lsp maps
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
