-- Per-file terminal state, keyed by absolute file path. Each file that runs
-- via F3 gets its own dedicated shell terminal so output for different files
-- doesn't get interleaved. At most one of these terminals is visible at a
-- time; the bottom split slot is swapped to the relevant file's terminal.
---@class RunBufferTerminal
---@field buf integer
---@field job_id integer
---@field cwd string
local terminals = {}

local M = {}

local utils = require 'user.utils'

-- Height of the horizontal terminal split, in lines.
local TERMINAL_HEIGHT = 15
-- Delay between sending <C-c> and the next command, so the shell has time
-- to handle SIGINT and return to a fresh prompt before we feed it more input.
local INTERRUPT_DELAY_MS = 50

-- Filetypes whose command must not include the buffer path (e.g. directory-scoped tools).
local FT_NO_FILE_ARG = {
  terraform = true,
}

---@param buf? integer
---@return boolean
function M.is_run_buffer_terminal_buf(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  -- jobstart(..., { term = true }) renames the buffer to term://…; track by bufnr.
  for _, state in pairs(terminals) do
    if state.buf == buf then
      return true
    end
  end
  return false
end

--- Cheap check for statusline: any F3 terminal still tracked (may include dead jobs).
---@return boolean
function M.has_tracked_terminals()
  return next(terminals) ~= nil
end

---@param job_id integer|nil
---@return boolean
local function job_alive(job_id)
  return job_id ~= nil and job_id > 0 and vim.fn.jobwait({ job_id }, 0)[1] == -1
end

---@param state RunBufferTerminal|nil
---@return boolean
local function terminal_usable(state)
  return state ~= nil and state.buf ~= nil and vim.api.nvim_buf_is_valid(state.buf) and job_alive(state.job_id)
end

--- Find an already-visible run-buffer terminal window to reuse so we don't
--- stack multiple bottom splits when switching between files.
---@return integer|nil winid
local function find_visible_run_buffer_win()
  for _, state in pairs(terminals) do
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
local function ensure_terminal_visible(term_buf)
  local term_win = vim.fn.bufwinid(term_buf)
  if term_win ~= -1 then
    vim.api.nvim_set_current_win(term_win)
    return term_win
  end
  local reuse_win = find_visible_run_buffer_win()
  if reuse_win then
    vim.api.nvim_win_set_buf(reuse_win, term_buf)
    vim.api.nvim_set_current_win(reuse_win)
    return reuse_win
  end
  vim.cmd('botright ' .. TERMINAL_HEIGHT .. 'split')
  vim.api.nvim_win_set_buf(0, term_buf)
  return vim.api.nvim_get_current_win()
end

---@param file_name string
local function clear_terminal_for_file(file_name)
  terminals[file_name] = nil
end

---@param buf integer
local function clear_terminal_for_buf(buf)
  for file, state in pairs(terminals) do
    if state.buf == buf then
      terminals[file] = nil
      return
    end
  end
end

--- True when the line is a Makefile rule target (not a recipe, comment, or assignment).
---@param line string
---@return string|nil target
local function makefile_target_name(line)
  -- Recipe lines must start with TAB; skip them (avoids false positives like https:// in recipes).
  if line:match '^\t' or line:match '^%s*#' then
    return nil
  end
  -- Target rules start at column 0: "target:" or "target: deps" (not "VAR := value").
  local target = line:match '^([^:#=]+):'
  if not target then
    return nil
  end
  target = vim.trim(target)
  if target == '' or target:match '^%.PHONY$' then
    return nil
  end
  return target
end

--- Given a path, open the file, extract all the Makefile keys,
--  and return them as a list.
---@param path string
---@return table options A telescope options list like
--{ { text: "1 - all", value="all" }, { text: "2 - hello", value="hello" } ...}
local function get_makefile_options(path)
  local options = {}

  local file = io.open(path, 'r')
  if not file then
    vim.notify('Unable to open a Makefile in the current working dir.', vim.log.levels.ERROR, {
      title = 'Makeit.nvim',
    })
    return options
  end

  local count = 0
  for line in file:lines() do
    local target = makefile_target_name(line)
    if target then
      count = count + 1
      table.insert(options, { text = count .. ' - ' .. target, value = target })
    end
  end
  file:close()

  return options
end

local function run_lua(file_name)
  local path = file_name:match 'nvim/lua/(.*)%.lua'
  if path then
    path = path:gsub('/', '.')
    if package.loaded[path] then
      package.loaded[path] = nil
      vim.notify('Unloaded package.path: ' .. path, vim.log.levels.INFO)
    end
  end
  vim.cmd 'luafile %'
  vim.notify('Reloading lua file', vim.log.levels.INFO)
end

---Open a new tab in wezterm and write the command
---@param cmd string command to write
---@param opts table options
local function open_tab(cmd, opts)
  if vim.fn.executable('wezterm') ~= 1 then
    vim.notify('wezterm not found in PATH', vim.log.levels.ERROR)
    return
  end
  if not opts.cwd then
    opts.cwd = vim.fn.getcwd()
  end
  local spawn = vim.system({ 'wezterm', 'cli', 'spawn', '--cwd=' .. opts.cwd }, { text = true }):wait()
  local spawn_stdout = vim.trim(spawn.stdout or '')
  if spawn.code ~= 0 or spawn_stdout == '' then
    local err = vim.trim((spawn.stderr or '') .. ' ' .. (spawn.stdout or ''))
    vim.notify('wezterm spawn failed: ' .. (err ~= '' and err or ('exit ' .. tostring(spawn.code))), vim.log.levels.ERROR)
    return
  end
  local send_text = { 'wezterm', 'cli', 'send-text', '--pane-id', spawn_stdout, cmd }
  local send_text_out = vim.system(send_text, {}):wait()
  if send_text_out.code ~= 0 then
    vim.notify(
      'Error running command in wezterm: ' .. (send_text_out.stdout or '') .. ' ' .. (send_text_out.stderr or ''),
      vim.log.levels.ERROR
    )
  end
end

---@param file_name string
---@param on_done fun(cmd: string|nil)
local function get_make_async(file_name, on_done)
  local options = get_makefile_options(file_name)
  if #options == 0 then
    on_done(nil)
    return
  end
  local labels = vim.tbl_map(function(option)
    return option.text
  end, options)
  vim.ui.select(labels, { prompt = 'Select make target❯ ' }, function(_choice, idx)
    if not idx then
      on_done(nil)
      return
    end
    on_done('make ' .. options[idx].value)
  end)
end

--- Build the shell command for a filetype (sync). Make targets use get_make_async.
---@param ft string
---@param file_name string
---@param first_line string
---@return string|nil cmd
---@return boolean should_break
function M._resolve_cmd(ft, file_name, first_line)
  local cmd = utils.filetype_to_command[ft] or 'bash'

  if first_line:match '^#!' then
    cmd = file_name
  elseif FT_NO_FILE_ARG[ft] then
    -- Use mapped command as-is (e.g. terragrunt plan).
  else
    cmd = cmd .. ' ' .. file_name
  end

  if vim.startswith(cmd, 'open') then
    vim.ui.open(file_name)
    return nil, true
  end

  if ft == 'lua' then
    run_lua(file_name)
    return nil, true
  end

  if ft == 'groovy' then
    require('user.jenkins-validate').validate()
    return nil, true
  end

  if ft == 'make' then
    return nil, false
  end

  return cmd, false
end

--- Get cmd or break (async when ft is make).
---@param ft string
---@param file_name string
---@param on_done fun(cmd: string|nil, should_break: boolean)
local function cmd_or_break_async(ft, file_name, on_done)
  local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or ''

  if ft == 'make' then
    get_make_async(file_name, function(cmd)
      if not cmd then
        on_done(nil, true)
        return
      end
      on_done(cmd, false)
    end)
    return
  end

  local cmd, should_break = M._resolve_cmd(ft, file_name, first_line)
  on_done(cmd, should_break)
end

local function filename_and_ft()
  local ft = vim.bo.filetype ~= '' and vim.bo.filetype or 'sh'
  local file_name = vim.fn.expand '%:p'
  -- check if current buffer is a valid file
  if file_name == '' then
    vim.api.nvim_set_option_value('filetype', ft, { buf = 0 })
    -- Pass `true` explicitly so _G.start_ls writes the unnamed buffer to a
    -- tempfile (named after its filetype) and returns the new path. Without
    -- it, start_ls returns nil and we'd silently no-op. See
    -- run-buffer_spec.lua for the regression test.
    if type(_G.start_ls) ~= 'function' then
      vim.notify('run-buffer: _G.start_ls is not defined; cannot run an unnamed buffer', vim.log.levels.ERROR)
      return
    end
    local temp_name = _G.start_ls(true)
    if type(temp_name) ~= 'string' or temp_name == '' then
      vim.notify('run-buffer: _G.start_ls(true) did not return a filepath; cannot run an unnamed buffer', vim.log.levels.ERROR)
      return
    end
    file_name = temp_name
  end

  -- check if file has changed and prompt the user if should save
  if vim.bo.modified then
    local save = vim.fn.confirm(('Save changes to %q before running?'):format(file_name), '&Yes\n&No\n&Cancel')
    if save == 3 then
      return
    elseif save == 1 then
      vim.cmd.write()
    end
  end
  return file_name, ft
end

---@param file_name string
---@param cmd string
---@param opts { cwd: string }
local function run_in_terminal(file_name, cmd, opts)
  local state = terminals[file_name]

  if not terminal_usable(state) then
    terminals[file_name] = nil

    local term_buf = vim.api.nvim_create_buf(false, true)
    vim.b[term_buf].run_buffer_terminal = true
    ensure_terminal_visible(term_buf)

    local job_id = vim.fn.jobstart(vim.o.shell, {
      term = true,
      cwd = opts.cwd,
      on_exit = function()
        clear_terminal_for_file(file_name)
      end,
    })

    if job_id <= 0 then
      vim.notify('Failed to start terminal', vim.log.levels.ERROR)
      return
    end

    terminals[file_name] = { buf = term_buf, job_id = job_id, cwd = opts.cwd }

    vim.schedule(function()
      if job_alive(job_id) then
        vim.fn.chansend(job_id, cmd)
      end
    end)
    return
  end

  ensure_terminal_visible(state.buf)
  vim.cmd 'startinsert'

  local job_id = state.job_id
  vim.fn.chansend(job_id, vim.keycode '<C-c>')

  local payload = ''
  if state.cwd ~= opts.cwd then
    state.cwd = opts.cwd
    payload = 'cd ' .. vim.fn.shellescape(opts.cwd) .. '\n'
  end
  payload = payload .. cmd

  vim.defer_fn(function()
    if job_alive(job_id) then
      vim.fn.chansend(job_id, payload)
    end
  end, INTERRUPT_DELAY_MS)
end

local function execute_file(where)
  if vim.bo.buftype == 'terminal' then
    return
  end
  local file_name, ft = filename_and_ft()
  if not file_name or not ft then
    return
  end

  cmd_or_break_async(ft, file_name, function(cmd, should_break)
    if should_break or not cmd then
      return
    end

    local opts = { cwd = vim.fn.expand '%:p:h' }
    if where and where ~= 'terminal' then
      open_tab(cmd, opts)
      return
    end

    run_in_terminal(file_name, cmd, opts)
  end)
end

-- Exposed for tests in lua/tests/run-buffer_spec.lua. Treat as internal.
M._filename_and_ft = filename_and_ft
M._terminals = terminals
M._get_makefile_options = get_makefile_options
M._makefile_target_name = makefile_target_name
M._clear_terminal_for_buf = clear_terminal_for_buf
M._get_make_async = get_make_async

--- Return all live run-buffer terminals, sorted by buffer-id (== creation
--- order). Each entry has `is_active = true` when it belongs to the file of
--- the current buffer (or, when on a terminal buffer, when it IS the current
--- buffer). Used by the statusline and `]t`/`[t` cycling.
---@return { file: string, basename: string, buf: integer, is_active: boolean }[]
function M.list_terminals()
  local cur_buf = vim.api.nvim_get_current_buf()
  local cur_file = vim.fn.expand '%:p'
  local list = {}
  for file, state in pairs(terminals) do
    if terminal_usable(state) then
      local is_active = state.buf == cur_buf or (cur_file ~= '' and file == cur_file)
      table.insert(list, {
        file = file,
        basename = vim.fn.fnamemodify(file, ':t'),
        buf = state.buf,
        is_active = is_active,
      })
    end
  end
  table.sort(list, function(a, b)
    return a.buf < b.buf
  end)
  return list
end

--- Count of run-buffer terminals that still have a live job and a valid buf.
---@return integer
function M.get_active_count()
  return #M.list_terminals()
end

--- Cycle the current window's buffer to the next/previous run-buffer
--- terminal. Wraps at the ends. No-op when fewer than 2 terminals exist or
--- the current buffer isn't one of them.
---@param direction 'next'|'prev'
function M.cycle_terminal(direction)
  local list = M.list_terminals()
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

function M.setup()
  vim.keymap.set('n', '<F3>', execute_file, { remap = false, silent = true })

  vim.api.nvim_create_user_command('RunInTerminal', function()
    execute_file 'terminal'
  end, {})

  vim.api.nvim_create_user_command('RunInTab', function()
    execute_file 'tab'
  end, {})

  vim.api.nvim_create_autocmd('BufWipeout', {
    callback = function(ev)
      clear_terminal_for_buf(ev.buf)
    end,
  })
end

return M
