---@class Utils
local M = {}

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

---Returns the current visual selection without leaving visual mode
---@return string[] lines Array of selected lines
function M.get_visual_selection_stay_in_visual()
  local mode = vim.api.nvim_get_mode().mode
  local opts = {}
  -- \22 is an escaped version of <c-v>
  if mode == 'v' or mode == 'V' or mode == '\22' then
    opts.type = mode
  end
  return vim.fn.getregion(vim.fn.getpos 'v', vim.fn.getpos '.', opts)
end

---Returns the current visual selection and exits visual mode
---@return string text The selected text
function M.get_visual_selection()
  local esc = vim.keycode '<esc>'
  vim.api.nvim_feedkeys(esc, 'x', false)
  local vstart = vim.fn.getpos "'<"
  local vend = vim.fn.getpos "'>"
  return table.concat(vim.fn.getregion(vstart, vend), '\n')
end

---Converts country code to emoji of the country flag
---@param country_iso string The country code in 2 uppercase letters (e.g. "US", "GB")
---@return string emoji The country flag emoji
function M.country_os_to_emoji(country_iso)
  -- Precompute byte offsets for country code conversion
  local COUNTRY_CODE_OFFSET = 127397
  local flag_icon = {}
  for i = 1, #country_iso do
    local code_point = country_iso:byte(i) + COUNTRY_CODE_OFFSET
    if code_point <= 0x7F then
      table.insert(flag_icon, string.char(code_point))
    elseif code_point <= 0x7FF then
      table.insert(flag_icon, string.char(0xC0 + math.floor(code_point / 0x40), 0x80 + code_point % 0x40))
    elseif code_point <= 0xFFFF then
      table.insert(flag_icon, string.char(0xE0 + math.floor(code_point / 0x1000), 0x80 + math.floor((code_point % 0x1000) / 0x40), 0x80 + code_point % 0x40))
    elseif code_point <= 0x10FFFF then
      table.insert(
        flag_icon,
        string.char(
          0xF0 + math.floor(code_point / 0x40000),
          0x80 + math.floor((code_point % 0x40000) / 0x1000),
          0x80 + math.floor((code_point % 0x1000) / 0x40),
          0x80 + code_point % 0x40
        )
      )
    end
  end
  return table.concat(flag_icon)
end

-- Static mappings
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

-- Cache emojis table
local EMOJIS = {
  '★',
  '☘️',
  '⚓️',
  '✨',
  '❄️',
  '🇮🇱',
  '🌍',
  '🌒',
  '🎉',
  '🎯',
  '🐙',
  '👑',
  '👰',
  '👻',
  '👾',
  '💖',
  '💯',
  '🔥',
  '😈',
  '🙉',
  '🚀',
  '🤖',
  '🤠',
  '🤡',
  '🤩',
  '🥨',
  '🥳',
}

---Returns a random emoji from the predefined list
---@return string emoji The random emoji
function M.random_emoji()
  return EMOJIS[math.random(#EMOJIS)]
end

---@param file_name string The filename to load
---@return table|nil The content of the file
function M.read_json_file(file_name)
  local file_path = file_name
  local file = io.open(file_path, 'r')
  if not file then
    return nil
  end

  local json_data = file:read '*a'
  file:close()

  local ok, decoded = pcall(vim.json.decode, json_data, { luanil = { object = true, array = true } })
  if ok then
    return decoded
  end
  return nil
end

return M
