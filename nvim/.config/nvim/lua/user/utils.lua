local M = {}

---Creates an augroup while clearing previous
--- @param name string The name of the augroup.
---@return number id The augroup id
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

M.get_visual_selection = function()
  local mode = vim.api.nvim_get_mode().mode
  local opts = {}
  -- \22 is an escaped version of <c-v>
  if mode == 'v' or mode == 'V' or mode == '\22' then
    opts.type = mode
  end
  return vim.fn.getregion(vim.fn.getpos 'v', vim.fn.getpos '.', opts)
end

M.get_os_command_output = function(cmd, cwd)
  local Job = require 'plenary.job'
  if not cwd then
    cwd = vim.fn.getcwd()
  end
  if type(cmd) ~= 'table' then
    M.pretty_print('cmd has to be a table', vim.log.leger.ERROR, [[🖥️]])
    return '', -1, ''
  end
  local command = table.remove(cmd, 1)
  local stderr = {}
  ---@diagnostic disable-next-line: missing-fields
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
---@param timeout? number: The timeout of the notification
---@return nil
M.pretty_print = function(message, title, icon, level, timeout)
  if not icon then
    icon = ''
  end
  if not title then
    title = 'Neovim'
  end
  if not level then
    level = vim.log.levels.INFO
  end
  if not timeout then
    timeout = 3000
  end
  vim.notify(message, level, { title = title, icon = icon, timeout = timeout })
end

---Converts country code to emoji of the country flag
---@param country_iso string: The country code in 2 uppercase letters
---@return string: emoji of the country flag
M.country_os_to_emoji = function(country_iso)
  local flag_icon = ''
  for i = 1, #country_iso do
    local code_point = country_iso:byte(i) + 127397
    if code_point <= 0x7F then
      flag_icon = flag_icon .. string.char(code_point)
    elseif code_point <= 0x7FF then
      flag_icon = flag_icon .. string.char(0xC0 + math.floor(code_point / 0x40), 0x80 + code_point % 0x40)
    elseif code_point <= 0xFFFF then
      flag_icon = flag_icon .. string.char(0xE0 + math.floor(code_point / 0x1000), 0x80 + math.floor((code_point % 0x1000) / 0x40), 0x80 + code_point % 0x40)
    elseif code_point <= 0x10FFFF then
      flag_icon = flag_icon
        .. string.char(
          0xF0 + math.floor(code_point / 0x40000),
          0x80 + math.floor((code_point % 0x40000) / 0x1000),
          0x80 + math.floor((code_point % 0x1000) / 0x40),
          0x80 + code_point % 0x40
        )
    end
  end
  return flag_icon
end

--- Get the next index in a table after the current element
--- @param tbl table The table to search in
--- @param cur any The current element to find
--- @return number index The next index in the table (loops back to 1)
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

M.filetype_to_command = {
  javascript = 'node',
  typescript = 'node',
  typescriptreact = 'node',
  python = 'python3',
  html = 'open',
  sh = 'bash',
  zsh = 'zsh',
  go = 'go',
  yaml = 'yq',
  json = 'jq',
}

M.random_emoji = function()
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

return M
