---@diagnostic disable: need-check-nil
local M = {}
M.autocmd = vim.api.nvim_create_autocmd

--Creates an augroup while clearing previous
--- @param name string #The name of the augroup.
M.augroup = function(name)
  return vim.api.nvim_create_augroup(name, { clear = true })
end
M.map_opts = {
  no_remap = { noremap = true },
  silent = { silent = true },
  no_remap_expr = { expr = true, noremap = true },
  no_remap_expr_silent = { expr = true, noremap = true, silent = true },
  no_remap_silent = { silent = true, noremap = true },
  remap = { noremap = false },
  expr_silent = { silent = true, expr = true },
}

M.keymap = vim.keymap.set
M.check_silent = function(silent, rest)
  if silent ~= nil then
    if type(silent) == 'table' then
      return vim.tbl_extend('force', rest, silent)
    elseif silent then
      return vim.tbl_extend('force', M.map_opts.silent, rest)
    end
  end
  return rest
end
M.nmap = function(lhs, rhs, silent)
  M.keymap('n', lhs, rhs, M.check_silent(silent, M.map_opts.remap))
end
M.nnoremap = function(lhs, rhs, silent)
  M.keymap('n', lhs, rhs, M.check_silent(silent, M.map_opts.no_remap))
end
M.vmap = function(lhs, rhs, silent)
  M.keymap('v', lhs, rhs, M.check_silent(silent, M.map_opts.remap))
end
M.vnoremap = function(lhs, rhs, silent)
  M.keymap('v', lhs, rhs, M.check_silent(silent, M.map_opts.no_remap))
end
M.omap = function(lhs, rhs, silent)
  M.keymap('o', lhs, rhs, M.check_silent(silent, M.map_opts.remap))
end
M.onoremap = function(lhs, rhs, silent)
  M.keymap('o', lhs, rhs, M.check_silent(silent, M.map_opts.no_remap))
end
M.imap = function(lhs, rhs, silent)
  M.keymap('i', lhs, rhs, M.check_silent(silent, M.map_opts.remap))
end
M.inoremap = function(lhs, rhs, silent)
  M.keymap('i', lhs, rhs, M.check_silent(silent, M.map_opts.no_remap))
end
M.tmap = function(lhs, rhs, silent)
  M.keymap('t', lhs, rhs, M.check_silent(silent, M.map_opts.remap))
end
M.tnoremap = function(lhs, rhs, silent)
  M.keymap('t', lhs, rhs, M.check_silent(silent, M.map_opts.no_remap))
end

M.xmap = function(lhs, rhs, silent)
  M.keymap('x', lhs, rhs, M.check_silent(silent, M.map_opts.remap))
end
M.xnoremap = function(lhs, rhs, silent)
  M.keymap('x', lhs, rhs, M.check_silent(silent, M.map_opts.no_remap))
end

-- Helper functions
vim.cmd [[
function! GetVisualSelection() abort
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][: col2 - (&selection ==? 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][col1 - 1:]
  let entire_selection = join(lines, "\n")
  return entire_selection
endfunction

function! GetMotion(motion)
  let saved_register = getreg('a')
  defer setreg('a', saved_register)

  exe 'normal! ' .. a:motion .. '"ay'
  return @a
endfunction

function! ReplaceMotion(motion, text)
  let saved_register = getreg('a')
  defer setreg('a', saved_register)

  let @a = a:text

  exe 'normal! ' .. a:motion .. '"ap'
endfunction
]]

M.pretty_print = function(message, title, icon)
  if not icon then
    icon = ''
  end
  if not title then
    title = 'Neovim'
  end
  vim.notify(message, 2, { title = title, icon = '' })
end

-- borders
M.borders = {
  double_rounded = { '╔', '═', '╗', '║', '╝', '═', '╚', '║' },
  single_rounded = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' },
  double_sharp = { '┏', '━', '┓', '┃', '┛', '━', '┗', '┃' },
  single_sharp = { '┌', '─', '┐', '│', '┘', '─', '└', '│' },
}
-- M.float_border = M.single_border_rounded
M.float_border = M.borders.single_rounded

return M
