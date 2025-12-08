local M = {
  icon = '',
}

-- Helper function to get all directories in the given paths
local function get_directories(paths)
  local dirs = {}
  for _, path in ipairs(paths) do
    local expanded_path = vim.fn.expand(path)
    -- If path ends with /, scan subdirectories
    if expanded_path:match '/$' then
      -- Remove trailing slash for consistent path handling
      expanded_path = expanded_path:gsub('/$', '')
      local handle = vim.uv.fs_scandir(expanded_path)
      if handle then
        while true do
          local name, type = vim.uv.fs_scandir_next(handle)
          if not name then
            break
          end
          if type == 'directory' then
            dirs[#dirs + 1] = expanded_path .. '/' .. name
          end
        end
      end
    else
      -- If path doesn't end with /, just add the directory itself
      dirs[#dirs + 1] = expanded_path
    end
  end
  return dirs
end

-- Get wezterm panes information
local function get_wezterm_panes()
  local output = vim.fn.system 'wezterm cli list --format json'
  if vim.v.shell_error ~= 0 then
    vim.notify('Failed to get wezterm panes', vim.log.levels.ERROR)
    return {}
  end
  return vim.json.decode(output)
end

-- Find existing nvim project tab
local function find_project_tab(project_name, panes)
  for _, pane in ipairs(panes) do
    if pane.title:match('nvim: ' .. vim.pesc(project_name) .. '$') then
      return pane
    end
  end
  return nil
end

-- Switch to project
local function switch_to_project(project_path, panes)
  local project_name = vim.fn.fnamemodify(project_path, ':t')
  local existing_tab = find_project_tab(project_name, panes)

  if existing_tab then
    -- Activate existing tab
    vim.fn.system('wezterm cli activate-tab --tab-id ' .. existing_tab.tab_id)
    vim.fn.system('wezterm cli activate-pane --pane-id ' .. existing_tab.pane_id)
  else
    -- Create new tab with nvim
    vim.system({ 'wezterm', 'cli', 'spawn', '--cwd', vim.fn.expand(project_path) }, { text = true }, function(res)
      local id = vim.trim(res.stdout)
      vim.schedule(function()
        vim.system { 'wezterm', 'cli', 'send-text', '--pane-id', id, 'nvim' .. vim.keycode '<cr>' }
      end)
    end)
  end
end

-- Main function to pick and switch projects
function M.pick_project()
  local fzf = require 'fzf-lua'

  -- Get all directories from Repos and dotfiles
  local pj_dirs = vim.env.PJ_DIRS or '~/Repos/,~/.dotfiles'
  local dirs_from_env = vim.split(pj_dirs, ',', { trimempty = true })
  local all_dirs = get_directories(dirs_from_env)

  -- Get active projects from wezterm
  local active_projects = {}
  local panes = get_wezterm_panes()
  for _, pane in ipairs(panes) do
    local project_name = pane.title:match 'nvim: (.+)$'
    if project_name then
      active_projects[project_name] = pane
    end
  end

  -- Format directories for display
  local formatted_dirs = {}
  local display_to_path = {}
  for _, dir in ipairs(all_dirs) do
    local name = vim.fn.fnamemodify(dir, ':t')
    local display_name = active_projects[name] and M.icon .. ' ' .. name or '  ' .. name
    formatted_dirs[#formatted_dirs + 1] = display_name
    display_to_path[display_name] = dir
  end

  -- Show fzf picker
  fzf.fzf_exec(formatted_dirs, {
    prompt = 'Projects❯ ',
    actions = {
      ['default'] = function(selected)
        if selected and selected[1] then
          local dir = display_to_path[selected[1]]
          if dir then
            switch_to_project(dir, panes)
          end
        end
      end,
    },
  })
end

function M.setup()
  vim.keymap.set('n', '<leader>pj', function()
    M.pick_project()
  end, { desc = 'Switch Project' })
end

return M
