local pack = require 'user.pack.add'
pack.add 'https://github.com/stevearc/overseer.nvim'

local dont_append_filename = { terraform = true }

local function run_in_wezterm_tab()
  local ft = vim.bo.filetype ~= '' and vim.bo.filetype or 'sh'
  local file_name = vim.fn.expand '%:p'
  if file_name == '' then
    return
  end

  local utils = require 'user.utils'
  local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or ''
  local cmd = first_line:match '^#!' and file_name or (utils.filetype_to_command[ft] or 'bash')
  if not dont_append_filename[ft] then
    cmd = cmd .. ' ' .. file_name
  end

  local cwd = vim.fn.expand '%:p:h'
  local spawn = vim.system({ 'wezterm', 'cli', 'spawn', '--cwd=' .. cwd }, { text = true }):wait()
  if spawn.code == 0 and vim.trim(spawn.stdout) ~= '' then
    vim.system({ 'wezterm', 'cli', 'send-text', '--pane-id', vim.trim(spawn.stdout), cmd }, {})
  end
end

local function run_lua_file()
  local file_name = vim.fn.expand '%:p'
  local module_path = file_name:match '.*/lua/(.*)%.lua$'
  if module_path then
    module_path = module_path:gsub('/', '.')
    if package.loaded[module_path] then
      package.loaded[module_path] = nil
      vim.notify('Unloaded: ' .. module_path, vim.log.levels.INFO)
    end
  end
  vim.cmd('luafile ' .. file_name)
  vim.notify('Sourced: ' .. vim.fn.expand '%:t', vim.log.levels.INFO)
end

local function open_task_picker()
  local ft = vim.bo.filetype
  if ft == 'lua' then
    return run_lua_file()
  end
  if ft == 'groovy' then
    return require('user.jenkins-validate').validate()
  end
  local overseer = require 'overseer'
  overseer.run_task({}, function(task)
    if task then
      overseer.open { enter = false }
    end
  end)
end

local run_current_buffer_template = {
  name = 'run_current_buffer',
  generator = function(_, cb)
    local file_name = vim.fn.expand '%:p'
    if file_name == '' then
      return cb {}
    end
    local ft = vim.bo.filetype or ''
    local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or ''
    local utils = require 'user.utils'
    local has_shebang = first_line:match '^#!'
    local has_cmd = utils.filetype_to_command[ft] ~= nil
    local is_terraform = ft == 'terraform'
    if not (has_shebang or has_cmd or is_terraform) then
      return cb {}
    end
    local cmd
    if has_shebang then
      cmd = file_name
    elseif ft == 'terraform' then
      cmd = 'terragrunt plan'
    else
      cmd = (utils.filetype_to_command[ft] or 'bash') .. ' ' .. file_name
    end
    cb {
      {
        name = 'Run: ' .. vim.fn.expand '%:t',
        priority = 0,
        builder = function()
          return { cmd = cmd, cwd = vim.fn.expand '%:p:h' }
        end,
      },
    }
  end,
}

local project_tasks = {
  {
    name = 'dotfiles: stow all',
    builder = function()
      return { cmd = { './start.sh' }, cwd = vim.env.HOME .. '/.dotfiles' }
    end,
    condition = { dir = vim.env.HOME .. '/.dotfiles' },
  },
  {
    name = 'nvim: run tests',
    builder = function()
      return { cmd = { 'make', 'test' }, cwd = vim.env.HOME .. '/.dotfiles/nvim/.config/nvim' }
    end,
    condition = { dir = vim.env.HOME .. '/.dotfiles' },
  },
}

return function()
  require('overseer').setup {
    task_list = { direction = 'bottom', min_height = 8 },
  }
  local overseer = require 'overseer'
  overseer.register_template(run_current_buffer_template)
  for _, task in ipairs(project_tasks) do
    overseer.register_template(task)
  end
  vim.api.nvim_create_user_command('RunInTab', run_in_wezterm_tab, {})
  vim.keymap.set('n', '<F3>', open_task_picker, { desc = 'Open task picker' })
end
