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
  go = 'go',
  html = 'open',
  javascript = 'node',
  json = 'jq',
  python = 'python3',
  sh = 'bash',
  terraform = 'terragrunt plan',
  typescript = 'node',
  typescriptreact = 'node',
  yaml = 'yq',
  ['yaml.ghaction'] = 'act -W',
  zsh = 'zsh',
}

---@param ft string
---@return string
function M.command_for_filetype(ft)
  local cmd = M.filetype_to_command[ft]
  if cmd then
    return cmd
  end
  local base = ft:match '^([^%.]+)'
  if base and base ~= ft then
    cmd = M.filetype_to_command[base]
    if cmd then
      return cmd
    end
  end
  return 'bash'
end

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

--- True when job_id refers to a running job channel.
--- jobwait raises E565 during TermClose; jobpid raises E900 on stale channels.
---@param job_id integer|nil
---@return boolean
function M.job_alive(job_id)
  if job_id == nil or job_id <= 0 then
    return false
  end
  local ok, pid = pcall(vim.fn.jobpid, job_id)
  return ok and pid ~= 0
end

--- Spawn a new Wezterm pane and send text to it (sync).
---@param text string Text to send to the new pane
---@param opts? { cwd?: string }
---@return boolean ok
function M.wezterm_spawn_and_send(text, opts)
  if vim.fn.executable 'wezterm' ~= 1 then
    vim.notify('wezterm not found in PATH', vim.log.levels.ERROR)
    return false
  end
  opts = opts or {}
  local cwd = opts.cwd or vim.fn.getcwd()
  local spawn = vim.system({ 'wezterm', 'cli', 'spawn', '--cwd=' .. cwd }, { text = true }):wait()
  local pane_id = vim.trim(spawn.stdout or '')
  if spawn.code ~= 0 or pane_id == '' then
    local err = vim.trim((spawn.stderr or '') .. ' ' .. (spawn.stdout or ''))
    vim.notify('wezterm spawn failed: ' .. (err ~= '' and err or ('exit ' .. tostring(spawn.code))), vim.log.levels.ERROR)
    return false
  end
  local send = vim.system({ 'wezterm', 'cli', 'send-text', '--pane-id', pane_id, text }, {}):wait()
  if send.code ~= 0 then
    vim.notify(
      'Error running command in wezterm: ' .. (send.stdout or '') .. ' ' .. (send.stderr or ''),
      vim.log.levels.ERROR
    )
    return false
  end
  return true
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
