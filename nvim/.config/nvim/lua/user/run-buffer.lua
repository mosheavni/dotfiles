-- Store terminal state for reuse
local terminal_state = {
  buf = nil,
  job_id = nil,
  cwd = nil,
}

--- Given a path, open the file, extract all the Makefile keys,
--  and return them as a list.
---@param path string
---@return table options A telescope options list like
--{ { text: "1 - all", value="all" }, { text: "2 - hello", value="hello" } ...}
local function get_makefile_options(path)
  local options = {}

  -- Open the Makefile for reading
  local file = io.open(path, 'r')

  if file then
    local in_target = false
    local count = 0

    -- Iterate through each line in the Makefile
    for line in file:lines() do
      -- Check for lines starting with a target rule (e.g., "target: dependencies")
      local target = line:match '^(.-):'
      if target then
        -- Skip .PHONY declarations and empty targets
        if not target:match '^%.PHONY' and not target:match '^%s*$' then
          in_target = true
          count = count + 1
          -- Exclude the ":" and add the option to the list with text and value fields
          table.insert(options, { text = count .. ' - ' .. target, value = target })
        end
      elseif in_target then
        -- If we're inside a target block, stop adding options
        in_target = false
      end
    end

    -- Close the Makefile
    file:close()
  else
    vim.notify('Unable to open a Makefile in the current working dir.', vim.log.levels.ERROR, {
      title = 'Makeit.nvim',
    })
  end

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
  if not opts.cwd then
    opts.cwd = vim.fn.getcwd()
  end
  local spawn = vim.system({ 'wezterm', 'cli', 'spawn', '--cwd=' .. opts.cwd }, { text = true }):wait()
  local spawn_stdout = vim.trim(spawn.stdout)
  if spawn.code == 0 and spawn_stdout ~= '' then
    local send_text = { 'wezterm', 'cli', 'send-text', '--pane-id', spawn_stdout, cmd }
    local send_text_out = vim.system(send_text, {}):wait()
    if send_text_out.code ~= 0 then
      vim.notify('Error running command in wezterm: ' .. send_text_out.stdout .. ' ' .. send_text_out.stderr, vim.log.levels.ERROR)
    end
  end
end

---Get make command
---@param file_name string file name
---@return string make command
local function get_make(file_name)
  local options = get_makefile_options(file_name)
  local opts_for_select = vim.tbl_map(function(option)
    return option.text
  end, options)

  local choice = vim.fn.inputlist {
    'Select a target to run:',
    table.concat(opts_for_select, '\n'),
  }
  if choice < 1 or choice > #options then
    return ''
  end
  return 'make ' .. options[choice].value
end

--- Get cmd or break
---@param ft string filetype
---@param file_name string file name
---@return string|nil cmd
---@return boolean should_break
local function cmd_or_break(ft, file_name)
  local utils = require 'user.utils'
  local cmd = utils.filetype_to_command[ft] or 'bash'
  local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or ''

  if first_line:match '^#!' then
    cmd = file_name
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
    cmd = get_make(file_name)
    if not cmd then
      return nil, true
    end
  end

  if ft == 'terraform' then
    cmd = 'terragrunt plan'
  end

  return cmd, false
end

local function filename_and_ft()
  local ft = vim.bo.filetype ~= '' and vim.bo.filetype or 'sh'
  local file_name = vim.fn.expand '%:p'
  -- check if current buffer is a valid file
  if file_name == '' then
    vim.api.nvim_set_option_value('filetype', ft, { buf = 0 })
    local temp_name = _G.start_ls()
    if not temp_name then
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

local function execute_file(where)
  if vim.bo.buftype == 'terminal' then
    return
  end
  local file_name, ft = filename_and_ft()
  if not file_name or not ft then
    return
  end

  local cmd, should_break = cmd_or_break(ft, file_name)
  if should_break or not cmd then
    return
  end

  local opts = { cwd = vim.fn.expand '%:p:h' }
  if not where or where == 'terminal' then
    local term_buf = terminal_state.buf
    local job_id = terminal_state.job_id

    -- Check if terminal buffer exists and is valid
    if not term_buf or not vim.api.nvim_buf_is_valid(term_buf) then
      -- Create a new terminal
      vim.cmd 'split'
      term_buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_win_set_buf(0, term_buf)

      -- Set buffer name for easy identification
      vim.api.nvim_buf_set_name(term_buf, 'run-buffer-terminal')

      -- Start terminal with working directory
      job_id = vim.fn.jobstart(vim.o.shell, {
        term = true,
        cwd = opts.cwd,
        on_exit = function()
          -- Clear terminal state when it exits
          terminal_state.buf = nil
          terminal_state.job_id = nil
        end,
      })

      -- Check if jobstart succeeded
      if job_id <= 0 then
        vim.notify('Failed to start terminal', vim.log.levels.ERROR)
        return
      end

      -- Store terminal state
      terminal_state.buf = term_buf
      terminal_state.job_id = job_id
      terminal_state.cwd = opts.cwd
    else
      -- Reuse existing terminal
      -- Check if terminal is visible in any window
      local term_win = vim.fn.bufwinid(term_buf)
      if term_win == -1 then
        -- Terminal not visible, open it in a split
        vim.cmd 'split'
        vim.api.nvim_win_set_buf(0, term_buf)
      else
        -- Terminal already visible, switch to it
        vim.api.nvim_set_current_win(term_win)
      end

      -- Enter insert mode
      vim.cmd 'startinsert'

      -- Clear any running command
      if job_id then
        vim.schedule(function()
          vim.fn.chansend(job_id, vim.keycode '<C-c>')
        end)
      end

      -- Change directory if needed
      if terminal_state.cwd ~= opts.cwd then
        terminal_state.cwd = opts.cwd
        if job_id then
          vim.schedule(function()
            vim.fn.chansend(job_id, 'cd ' .. vim.fn.shellescape(opts.cwd) .. '\n')
          end)
        end
      end
    end

    -- Send the command to the terminal
    if job_id then
      vim.schedule(function()
        vim.fn.chansend(job_id, cmd)
      end)
    end
  else
    open_tab(cmd, opts)
  end
end

vim.keymap.set('n', '<F3>', execute_file, { remap = false, silent = true })

vim.api.nvim_create_user_command('RunInTerminal', function()
  execute_file 'terminal'
end, {})

vim.api.nvim_create_user_command('RunInTab', function()
  execute_file 'tab'
end, {})
