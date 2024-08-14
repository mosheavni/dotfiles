local M = {}
M.autocmd = vim.api.nvim_create_autocmd

---Creates an augroup while clearing previous
--- @param name string The name of the augroup.
---@return number The augroup id
M.augroup = function(name)
  return vim.api.nvim_create_augroup(name, { clear = true })
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

M.get_os_command_output = function(cmd, cwd)
  local Job = require 'plenary.job'
  if not cwd then
    cwd = vim.fn.getcwd()
  end
  if type(cmd) ~= 'table' then
    M.pretty_print('cmd has to be a table', vim.log.leger.ERROR, [[🖥️]])
    return {}
  end
  local command = table.remove(cmd, 1)
  local stderr = {}
  local stdout, ret = Job:new({
    command = command,
    args = cmd,
    cwd = cwd,
    on_stderr = function(_, data)
      table.insert(stderr, data)
    end,
  }):sync()
  return stdout, ret, stderr
end

--- Pretty print using vim.notify
---@param message string: The message to print
---@param title? string: The title of the notification
---@param icon? string: The icon of the notification
---@param level? number: The log level of the notification (vim.log.levels.INFO by default)
---@return nil
M.pretty_print = function(message, title, icon, level)
  if not icon then
    icon = ''
  end
  if not title then
    title = 'Neovim'
  end
  if not level then
    level = vim.log.levels.INFO
  end
  vim.notify(message, level, { title = title, icon = icon })
end

---Converts country code to emoji of the country flag
---@param iso string: The country code
---@return string: emoji of the country flag
M.country_os_to_emoji = function(iso)
  local python_file = vim.fn.tempname() .. '.py'
  local python_file_content = [[import sys; print("".join(chr(ord(c) + 127397) for c in sys.argv[1].upper()), end='')]]
  local python_file_handle = io.open(python_file, 'w')
  python_file_handle:write(python_file_content)
  python_file_handle:close()
  local emoji = vim.system({ 'python3', python_file, iso }, { text = true }):wait().stdout
  vim.fn.delete(python_file)
  return emoji or ''
end

M.tbl_get_next = function(tbl, cur)
  local idx = 1
  for i, v in ipairs(tbl) do
    if v == cur then
      idx = i % #tbl + 1
      break
    end
  end
  return idx
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

M.filetype_to_extension = {
  bash = 'sh',
  javascript = 'js',
  javascriptreact = 'jsx',
  kotlin = 'kt',
  markdown = 'md',
  perl = 'pl',
  python = 'py',
  ruby = 'rb',
  rust = 'rs',
  terraform = 'tf',
  typescript = 'ts',
  typescriptreact = 'tsx',
  zsh = 'sh',
}

return M
