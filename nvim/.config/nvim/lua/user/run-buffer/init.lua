-- Run the current buffer in a terminal (F3) or external runner. Per-file terminals
-- are registered in user.terminal so output for different files does not interleave.
local M = {}

local buffer = require 'user.run-buffer.buffer'
local resolve = require 'user.run-buffer.resolve'
local terminal = require 'user.terminal'
local wezterm = require 'user.wezterm'

local INTERRUPT_DELAY_MS = 50

--- Register a custom run handler for a filetype.
M.register_handler = resolve.register_handler
--- Register a handler module (`{ ft, handler }`).
M.register_handler_module = resolve.register_handler_module

--- Send `cmd` to the per-file run terminal, creating or reusing the split for `file_name`.
--- On re-run, interrupts the previous job with Ctrl-C, optionally `cd`s, then sends the command.
---@param file_name string Absolute buffer path (terminal registry key).
---@param cmd string Shell command to execute.
---@param opts { cwd: string } Working directory for a new terminal or `cd` on re-run.
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
      terminal.send(cmd, { id = file_name, newline = false })
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
    terminal.send(payload, { id = file_name, newline = false })
  end, INTERRUPT_DELAY_MS)
end

--- Resolve and run the current buffer.
---@param where? 'terminal'|'tab' `terminal` forces the Neovim split; `tab` opens Wezterm; `nil` is F3 default.
local function execute_file(where)
  if vim.bo.buftype == 'terminal' then
    return
  end
  local file_name, ft = buffer.filename_and_ft()
  if not file_name or not ft then
    return
  end

  resolve.run(ft, file_name, function(cmd, done)
    if done or not cmd then
      return
    end

    local opts = { cwd = buffer.run_cwd(ft) }
    if where and where ~= 'terminal' then
      wezterm.spawn_and_send(cmd, vim.tbl_extend('force', opts, { place_after_current = true }))
      return
    end

    run_in_terminal(file_name, cmd, opts)
  end)
end

--- Install F3, `:RunInTerminal`, `:RunInTab`, and menu entries.
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
