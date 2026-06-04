-- Run the current buffer in a terminal (F3) or external runner. Per-file terminals
-- are registered in user.terminal so output for different files does not interleave.
local M = {}

local utils = require 'user.utils'
local terminal = require 'user.terminal'

-- Delay between sending <C-c> and the next command, so the shell has time
-- to handle SIGINT and return to a fresh prompt before we feed it more input.
local INTERRUPT_DELAY_MS = 50

-- Filetypes whose command must not include the buffer path (e.g. directory-scoped tools).
local FT_NO_FILE_ARG = {
  terraform = true,
}

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
  vim.ui.select(labels, { prompt = 'Select make target❯ ' }, function(_, idx)
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
  local cmd = utils.command_for_filetype(ft)

  if first_line:match '^#!' then
    cmd = file_name
  elseif not FT_NO_FILE_ARG[ft] then
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

  if ft == 'yaml.ghaction' then
    local cmd = require('user.gh-actions').build_act_cmd(file_name)
    on_done(cmd, cmd == nil)
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
  local state = terminal.get(file_name)

  if not state then
    local term_buf = vim.api.nvim_create_buf(false, true)
    terminal.show(term_buf)

    local job_id = vim.fn.jobstart(vim.o.shell, {
      term = true,
      cwd = opts.cwd,
      on_exit = function()
        terminal.unregister(file_name)
      end,
    })

    if job_id <= 0 then
      vim.notify('Failed to start terminal', vim.log.levels.ERROR)
      return
    end

    terminal.register_run(file_name, term_buf, job_id, opts.cwd)

    vim.schedule(function()
      if terminal.job_alive(job_id) then
        vim.fn.chansend(job_id, cmd)
      end
    end)
    return
  end

  terminal.show(state.buf)
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
    if terminal.job_alive(job_id) then
      vim.fn.chansend(job_id, payload)
    end
  end, INTERRUPT_DELAY_MS)
end

--- Working directory for running the buffer (repo root for GitHub Actions workflows).
---@param ft string
---@return string
local function run_cwd(ft)
  if ft == 'yaml.ghaction' then
    local root = require('user.git').get_toplevel_sync()
    if root ~= '' then
      return root
    end
  end
  return vim.fn.expand '%:p:h'
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

    local opts = { cwd = run_cwd(ft) }
    if where and where ~= 'terminal' then
      utils.wezterm_spawn_and_send(cmd, opts)
      return
    end

    run_in_terminal(file_name, cmd, opts)
  end)
end

-- Exposed for tests in lua/tests/run-buffer_spec.lua. Treat as internal.
M._filename_and_ft = filename_and_ft
M._get_makefile_options = get_makefile_options
M._makefile_target_name = makefile_target_name
M._get_make_async = get_make_async
M._run_cwd = run_cwd

function M.setup()
  vim.keymap.set('n', '<F3>', execute_file, { remap = false, silent = true })

  vim.api.nvim_create_user_command('RunInTerminal', function()
    execute_file 'terminal'
  end, {})

  vim.api.nvim_create_user_command('RunInTab', function()
    execute_file 'tab'
  end, {})

  require('user.menu').add_actions('Run', {
    ['Run buffer in terminal split (<F3> | :RunInTerminal)'] = function()
      vim.cmd [[RunInTerminal]]
    end,
    ['Run buffer in new tab (:RunInTab)'] = function()
      vim.cmd [[RunInTab]]
    end,
  })
end

return M
