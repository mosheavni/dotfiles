-- Thin wrapper around the `wezterm cli` so all wezterm interaction lives in one
-- place. Functions are synchronous and no-op gracefully when wezterm is not on
-- PATH (e.g. when nvim runs outside of wezterm).
local M = {}

---@return boolean
function M.available()
  return vim.fn.executable 'wezterm' == 1
end

--- Run a `wezterm cli` subcommand synchronously.
---@param args string[] Arguments after `wezterm cli`
---@param opts? table Options forwarded to vim.system
---@return vim.SystemCompleted|nil
local function cli(args, opts)
  if not M.available() then
    return nil
  end
  local cmd = { 'wezterm', 'cli' }
  vim.list_extend(cmd, args)
  return vim.system(cmd, opts or {}):wait()
end

--- List all windows/tabs/panes as decoded JSON.
---@return table panes
function M.list()
  local res = cli({ 'list', '--format', 'json' }, { text = true })
  if not res or res.code ~= 0 then
    vim.notify('Failed to get wezterm panes', vim.log.levels.ERROR)
    return {}
  end
  local ok, decoded = pcall(vim.json.decode, res.stdout or '')
  return ok and decoded or {}
end

--- Activate (focus) a tab by id.
---@param tab_id string|number
function M.activate_tab(tab_id)
  cli { 'activate-tab', '--tab-id', tostring(tab_id) }
end

--- Activate (focus) a pane by id.
---@param pane_id string|number
function M.activate_pane(pane_id)
  cli { 'activate-pane', '--pane-id', tostring(pane_id) }
end

--- Spawn a new tab. Returns the new pane id, or nil on failure.
---@param opts? { cwd?: string }
---@return string|nil pane_id
function M.spawn(opts)
  opts = opts or {}
  local cwd = opts.cwd or vim.fn.getcwd()
  local res = cli({ 'spawn', '--cwd=' .. cwd }, { text = true })
  if not res then
    vim.notify('wezterm not found in PATH', vim.log.levels.ERROR)
    return nil
  end
  local pane_id = vim.trim(res.stdout or '')
  if res.code ~= 0 or pane_id == '' then
    local err = vim.trim((res.stderr or '') .. ' ' .. (res.stdout or ''))
    vim.notify('wezterm spawn failed: ' .. (err ~= '' and err or ('exit ' .. tostring(res.code))), vim.log.levels.ERROR)
    return nil
  end
  return pane_id
end

--- Send text to a pane.
---@param pane_id string|number
---@param text string
---@param opts? { no_paste?: boolean }
---@return boolean ok
function M.send_text(pane_id, text, opts)
  opts = opts or {}
  local args = { 'send-text' }
  if opts.no_paste then
    table.insert(args, '--no-paste')
  end
  vim.list_extend(args, { '--pane-id', tostring(pane_id), text })
  local res = cli(args)
  if not res or res.code ~= 0 then
    local detail = res and ((res.stdout or '') .. ' ' .. (res.stderr or '')) or 'wezterm not found in PATH'
    vim.notify('Error running command in wezterm: ' .. detail, vim.log.levels.ERROR)
    return false
  end
  return true
end

--- Set a wezterm user var on a pane by emitting the OSC SetUserVar sequence from
--- that pane's shell (the only way to reach the GUI's user-var-changed event).
--- The value is base64-encoded as required by wezterm.
---@param pane_id string|number
---@param name string
---@param value string
function M.set_user_var(pane_id, name, value)
  local osc = ([[printf '\033]1337;SetUserVar=%s=%s\007']]):format(name, vim.base64.encode(value))
  M.send_text(pane_id, osc .. '\n', { no_paste = true })
end

--- Spawn a new tab and send text to it.
---@param text string Text to send to the new pane
---@param opts? { cwd?: string, place_after_current?: boolean }
---@return boolean ok
function M.spawn_and_send(text, opts)
  opts = opts or {}
  local pane_id = M.spawn { cwd = opts.cwd }
  if not pane_id then
    return false
  end

  -- wezterm's CLI cannot reorder tabs, so the new tab always lands at the end.
  -- To move it next to the current (nvim) tab, set a user var on the new pane
  -- carrying our pane id; the .wezterm.lua user-var-changed handler performs the
  -- GUI MoveTab action.
  if opts.place_after_current then
    local src_pane = os.getenv 'WEZTERM_PANE'
    if src_pane and src_pane ~= '' then
      M.set_user_var(pane_id, 'runintab_after', src_pane)
    end
  end

  return M.send_text(pane_id, text)
end

return M
