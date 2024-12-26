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
        in_target = true
        count = count + 1
        -- Exclude the ":" and add the option to the list with text and value fields
        table.insert(options, { text = count .. ' - ' .. target, value = target })
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
    file_name = _G.start_ls()
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
    -- selene: allow(undefined_variable)
    local term, created = Snacks.terminal.get(nil, opts)
    local job_id = vim.bo[term.buf].channel

    -- clear terminal input if already open
    if not created then
      if not term:valid() then
        term:show()
      end
      vim.api.nvim_set_current_win(term.win)
      vim.schedule(function()
        vim.fn.chansend(job_id, vim.api.nvim_replace_termcodes('<C-c>', true, true, true))
      end)
    end
    -- send command
    vim.schedule(function()
      vim.fn.chansend(job_id, cmd)
    end)
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
