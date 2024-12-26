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

local function execute_file(where)
  if vim.bo.buftype == 'terminal' then
    return
  end
  local utils = require 'user.utils'
  local ft = vim.bo.filetype ~= '' and vim.bo.filetype or 'sh'

  -- check if current buffer is a valid file
  local file_name = vim.fn.expand '%:p'
  if file_name == '' then
    vim.api.nvim_set_option_value('filetype', ft, { buf = 0 })
    file_name = _G.start_ls()
  end

  -- check if file has changed and prompt the user if should save
  if vim.bo.modified then
    local save = vim.fn.confirm(('Save changes to %q before running?'):format(vim.fn.bufname()), '&Yes\n&No\n&Cancel')
    if save == 3 then
      return
    elseif save == 1 then
      vim.cmd.write()
    end
  end

  -- check if there's a shebang to determine cmd
  local cmd = utils.filetype_to_command[ft] or 'bash'
  local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or ''
  if cmd == 'open' then
    return vim.ui.open(file_name)
  end
  if ft == 'lua' then
    local path = vim.fn.expand('%:p'):match('nvim/lua/(.*)%.lua'):gsub('/', '.')
    if package.loaded[path] then
      package.loaded[path] = nil
    end
    vim.cmd 'luafile %'
    vim.notify('Reloading lua file', vim.log.levels.INFO)
    return
  end
  if ft == 'groovy' then
    require('user.jenkins-validate').validate()
    return
  end
  if ft == 'terraform' then
    cmd = 'terragrunt plan'
  ---@diagnostic disable-next-line: undefined-field
  elseif first_line:match '^#!' then
    cmd = file_name
  else
    cmd = cmd .. ' ' .. file_name
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
