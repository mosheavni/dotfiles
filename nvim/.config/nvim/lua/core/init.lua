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
    vim.notify(vim.inspect(v), 2, {
      title = 'P debug',
      icon = '✎',
    })
  end
  return v
end

local original_vim_print = vim.print
vim.print = function(...)
  local str = type(...) == 'table' and vim.inspect(...) or ...
  original_vim_print(str)
end

-- Write a temporary file, optionally delete on exit, set filetype and open in a
-- new buffer
-- @param should_delete boolean whether to delete the file on exit
-- @param ft string filetype to set
-- @params new boolean whether to open in a new buffer
-- @params vertical boolean whether to open in a vertical split (only if new is true)
-- @returns nil
function _G.tmp_write(opts)
  local defaults = {
    should_delete = true,
    ft = nil,
    new = true,
    vertical = false,
  }
  local final_opts = vim.tbl_extend('force', defaults, opts)
  local should_delete = final_opts.should_delete
  local ft = final_opts.ft
  local new = final_opts.new
  local vertical = final_opts.vertical
  local tmp = vim.fn.tempname()
  if new then
    if vertical then
      vim.cmd 'vnew'
    else
      vim.cmd 'new'
    end
  end

  if ft then
    local extension = require('user.utils').filetype_to_extension[ft] or ft
    vim.api.nvim_set_option_value('filetype', ft, { buf = 0 })
    tmp = tmp .. '.' .. extension
  end
  vim.cmd(string.format('write %s', tmp))
  vim.cmd 'edit'

  -- Create autocmd to delete the file on exit
  if should_delete then
    vim.api.nvim_create_autocmd({ 'VimLeavePre' }, {
      buffer = 0,
      command = 'delete("' .. tmp .. '")',
    })
  end
  return tmp
end

-- leader key - before mapping lsp maps
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
