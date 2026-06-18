-- Managed terminal buffers: generic shells (:Terminal) and run-buffer (F3) terminals.
-- One registry; at most one bottom split slot is reused when showing a terminal.
---@class TerminalEntry
---@field buf integer
---@field job_id integer
---@field cwd string
---@field name string
---@field file? string

local M = {}

local TERMINAL_HEIGHT = 15

---@type table<string, TerminalEntry>
local by_id = {}

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

---@param state TerminalEntry|nil
---@return boolean
local function usable(state)
  return state ~= nil and state.buf ~= nil and vim.api.nvim_buf_is_valid(state.buf) and M.job_alive(state.job_id)
end

---@return integer|nil winid
local function find_visible_terminal_win()
  for _, state in pairs(by_id) do
    if state.buf then
      local win = vim.fn.bufwinid(state.buf)
      if win ~= -1 then
        return win
      end
    end
  end
  return nil
end

--- Show term_buf in an existing window or open/reuse the bottom split.
---@param term_buf integer
---@return integer winid
function M.show(term_buf)
  local term_win = vim.fn.bufwinid(term_buf)
  if term_win ~= -1 then
    vim.api.nvim_set_current_win(term_win)
    return term_win
  end
  local reuse_win = find_visible_terminal_win()
  if reuse_win then
    vim.api.nvim_win_set_buf(reuse_win, term_buf)
    vim.api.nvim_set_current_win(reuse_win)
    return reuse_win
  end
  vim.cmd('botright ' .. TERMINAL_HEIGHT .. 'split')
  vim.api.nvim_win_set_buf(0, term_buf)
  return vim.api.nvim_get_current_win()
end

local function default_cwd()
  local dir = vim.fn.expand '%:p:h'
  if dir ~= '' then
    return dir
  end
  return vim.fn.getcwd()
end

local shell_name_seq = { n = 0 }

local function next_shell_name()
  shell_name_seq.n = shell_name_seq.n + 1
  return 'Terminal ' .. shell_name_seq.n
end

---@param cwd string
---@param on_exit? fun(buf: integer)
---@return integer buf
---@return integer job_id
local function spawn_shell(cwd, on_exit)
  local term_buf = vim.api.nvim_create_buf(false, true)
  M.show(term_buf)

  local job_id = vim.fn.jobstart(vim.o.shell, {
    term = true,
    cwd = cwd,
    on_exit = function()
      if on_exit then
        on_exit(term_buf)
      end
    end,
  })

  if job_id <= 0 then
    vim.notify('Failed to start terminal', vim.log.levels.ERROR)
    return term_buf, job_id
  end

  return term_buf, job_id
end

--- Open a managed shell terminal. When opts.focus is false the terminal is
--- shown but focus returns to the originating window (no startinsert).
---@param opts? { cwd?: string, name?: string, focus?: boolean }
---@return integer|nil buf
---@return integer|nil job_id
function M.open(opts)
  opts = opts or {}
  local focus = opts.focus ~= false
  local prev_win = vim.api.nvim_get_current_win()
  local cwd = opts.cwd or default_cwd()
  local buf, job_id = spawn_shell(cwd, function(term_buf)
    M.unregister('shell-' .. term_buf)
  end)

  if job_id <= 0 then
    return nil, nil
  end

  local id = 'shell-' .. buf
  by_id[id] = {
    buf = buf,
    job_id = job_id,
    cwd = cwd,
    name = opts.name or next_shell_name(),
    file = nil,
  }
  if focus then
    vim.cmd 'startinsert'
  elseif vim.api.nvim_win_is_valid(prev_win) then
    vim.api.nvim_set_current_win(prev_win)
  end
  return buf, job_id
end

--- Send a command to a managed terminal's job. Targets opts.id, then opts.buf,
--- then the current buffer's terminal. A trailing newline is appended (so the
--- shell runs the command) unless opts.newline is false, which just types it.
---@param cmd string
---@param opts? { id?: string, buf?: integer, newline?: boolean }
---@return boolean ok
function M.send(cmd, opts)
  opts = opts or {}
  local state
  if opts.id then
    state = M.get(opts.id)
  else
    state = M.entry_for_buf(opts.buf)
  end
  if not state then
    vim.notify('No managed terminal to send to', vim.log.levels.ERROR)
    return false
  end
  if opts.newline ~= false and not cmd:match '\n$' then
    cmd = cmd .. '\n'
  end
  vim.fn.chansend(state.job_id, cmd)
  return true
end

---@param id string
---@return TerminalEntry|nil
function M.get(id)
  local state = by_id[id]
  if usable(state) then
    return state
  end
  if state then
    by_id[id] = nil
  end
  return nil
end

---@param id string
---@param buf integer
---@param job_id integer
---@param cwd string
function M.register_run(id, buf, job_id, cwd)
  by_id[id] = {
    buf = buf,
    job_id = job_id,
    cwd = cwd,
    name = vim.fn.fnamemodify(id, ':t'),
    file = id,
  }
end

---@param id string
function M.unregister(id)
  by_id[id] = nil
end

--- Adopt an externally-created terminal buffer (e.g. from :terminal) so it gains
--- cycle/pick/rename support. No-op when the buffer is already tracked or has no
--- live terminal job. Scheduled from TermOpen so module-spawned terminals, which
--- register synchronously after jobstart returns, are already tracked and skipped.
---@param buf integer
function M.adopt(buf)
  if not vim.api.nvim_buf_is_valid(buf) or M.is_tracked_buf(buf) then
    return
  end
  local job_id = vim.b[buf].terminal_job_id
  if not M.job_alive(job_id) then
    return
  end
  by_id['shell-' .. buf] = {
    buf = buf,
    job_id = job_id,
    cwd = vim.fn.getcwd(),
    name = next_shell_name(),
    file = nil,
  }
end

---@param buf integer
function M._clear_for_buf(buf)
  for id, state in pairs(by_id) do
    if state.buf == buf then
      by_id[id] = nil
      return
    end
  end
end

---@param buf? integer
---@return boolean
function M.is_tracked_buf(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  for _, state in pairs(by_id) do
    if state.buf == buf then
      return true
    end
  end
  return false
end

---@param buf? integer
---@return TerminalEntry|nil
---@return string|nil id
function M.entry_for_buf(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  for id, state in pairs(by_id) do
    if state.buf == buf then
      if usable(state) then
        return state, id
      end
      by_id[id] = nil
      return nil, nil
    end
  end
  return nil, nil
end

---@return { id: string, name: string, buf: integer, file?: string, is_active: boolean }[]
function M.list()
  local cur_buf = vim.api.nvim_get_current_buf()
  local cur_file = vim.fn.expand '%:p'
  local list = {}
  for id, state in pairs(by_id) do
    if usable(state) then
      local is_active = state.buf == cur_buf or (cur_file ~= '' and state.file == cur_file)
      table.insert(list, {
        id = id,
        name = state.name,
        buf = state.buf,
        file = state.file,
        is_active = is_active,
      })
    else
      by_id[id] = nil
    end
  end
  table.sort(list, function(a, b)
    return a.buf < b.buf
  end)
  return list
end

---@param direction 'next'|'prev'
function M.cycle(direction)
  local list = M.list()
  if #list < 2 then
    return
  end
  local cur = vim.api.nvim_get_current_buf()
  local idx
  for i, item in ipairs(list) do
    if item.buf == cur then
      idx = i
      break
    end
  end
  if not idx then
    return
  end
  local target
  if direction == 'next' then
    target = (idx % #list) + 1
  else
    target = ((idx - 2) % #list) + 1
  end
  vim.api.nvim_win_set_buf(0, list[target].buf)
  vim.cmd 'startinsert'
end

---@param name? string
function M.rename(name)
  local state, id = M.entry_for_buf()
  if not state or not id then
    vim.notify('Not a managed terminal buffer', vim.log.levels.ERROR)
    return
  end
  name = name and vim.trim(name) or ''
  if name == '' then
    name = vim.fn.input('Terminal name: ', state.name)
    if name == '' then
      return
    end
  end
  state.name = name
end

function M.pick()
  local list = M.list()
  if #list == 0 then
    vim.notify('No terminals', vim.log.levels.INFO)
    return
  end
  local labels = vim.tbl_map(function(item)
    local label = item.name
    if vim.fn.bufwinid(item.buf) == -1 then
      label = label .. ' (hidden)'
    end
    return label
  end, list)
  vim.ui.select(labels, { prompt = 'Terminal❯ ' }, function(_, idx)
    if not idx then
      return
    end
    M.show(list[idx].buf)
    vim.cmd 'startinsert'
  end)
end

function M.setup()
  vim.api.nvim_create_user_command('Terminal', function()
    M.open()
  end, {})

  vim.api.nvim_create_user_command('TerminalRename', function(opts)
    M.rename(opts.args ~= '' and opts.args or nil)
  end, { nargs = '?' })

  vim.api.nvim_create_user_command('TerminalPick', function()
    M.pick()
  end, {})

  require('user.menu').add_actions('Terminal', {
    ['Open new floating terminal (:Terminal)'] = function()
      vim.cmd [[Terminal]]
    end,
    ['Rename current terminal (:TerminalRename)'] = function()
      vim.cmd [[TerminalRename]]
    end,
    ['Pick existing terminal (:TerminalPick)'] = function()
      vim.cmd [[TerminalPick]]
    end,
  })

  vim.api.nvim_create_autocmd('BufWipeout', {
    callback = function(ev)
      M._clear_for_buf(ev.buf)
    end,
  })

  vim.api.nvim_create_autocmd('TermOpen', {
    group = vim.api.nvim_create_augroup('TerminalAdopt', { clear = true }),
    callback = function(ev)
      vim.schedule(function()
        M.adopt(ev.buf)
      end)
    end,
  })
end

M._by_id = by_id
M._shell_name_seq = shell_name_seq
M._next_shell_name = next_shell_name

return M
