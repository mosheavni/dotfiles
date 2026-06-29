local wezterm = require 'user.wezterm'

local M = {
  icon = '',
}

local empty_preview_file

local function empty_preview_path()
  if not empty_preview_file then
    empty_preview_file = vim.fn.tempname()
    vim.fn.writefile({}, empty_preview_file)
  end
  return empty_preview_file
end

local function readme_path(dir)
  local readme = vim.fn.fnamemodify(vim.fn.expand(dir), ':p') .. 'README.md'
  if vim.fn.filereadable(readme) == 1 then
    return readme
  end
end

---@param display string
---@param display_to_path table<string, string>
local function preview_path_for_display(display, display_to_path)
  local dir = display_to_path[display]
  if not dir then
    return empty_preview_path()
  end
  return readme_path(dir) or empty_preview_path()
end

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
local function switch_to_project(project_path)
  local project_name = vim.fn.fnamemodify(project_path, ':t')
  local existing_tab = find_project_tab(project_name, wezterm.list())

  if existing_tab then
    -- Activate existing tab
    wezterm.activate_tab(existing_tab.tab_id)
    wezterm.activate_pane(existing_tab.pane_id)
  else
    wezterm.spawn_and_send('nvim' .. vim.keycode '<cr>', { cwd = vim.fn.expand(project_path) })
  end
end

local function project_name_from_display(display)
  return display:match '%s+(.*)$'
end

local function kill_project_pane(display)
  local project_name = project_name_from_display(display)
  if not project_name then
    return
  end
  local pane = find_project_tab(project_name, wezterm.list())
  if not pane then
    vim.notify('Project is not open: ' .. project_name, vim.log.levels.WARN)
    return
  end
  if not wezterm.kill_pane(pane.pane_id) then
    vim.notify('Failed to kill pane for ' .. project_name, vim.log.levels.ERROR)
  end
end

---@param display_to_path table<string, string>
---@return string[]
local function populate_project_entries(display_to_path)
  for key in pairs(display_to_path) do
    display_to_path[key] = nil
  end

  local pj_dirs = vim.env.PJ_DIRS or '~/Repos/,~/.dotfiles'
  local dirs_from_env = vim.split(pj_dirs, ',', { trimempty = true })
  local all_dirs = get_directories(dirs_from_env)

  local active_projects = {}
  local panes = wezterm.list()
  for _, pane in ipairs(panes) do
    local project_name = pane.title:match 'nvim: (.+)$'
    if project_name then
      active_projects[project_name] = pane
    end
  end

  local formatted_dirs = {}
  for _, dir in ipairs(all_dirs) do
    local name = vim.fn.fnamemodify(dir, ':t')
    local display_name = active_projects[name] and M.icon .. ' ' .. name or '  ' .. name
    formatted_dirs[#formatted_dirs + 1] = display_name
    display_to_path[display_name] = dir
  end

  return formatted_dirs
end

-- Main function to pick and switch projects
function M.pick_project()
  local fzf = require 'fzf-lua'
  local display_to_path = {}

  local function project_contents(cb)
    local formatted_dirs = populate_project_entries(display_to_path)
    for _, display_name in ipairs(formatted_dirs) do
      cb(display_name)
    end
    cb()
  end

  -- Show fzf picker
  fzf.fzf_exec(project_contents, {
    prompt = 'Projects❯ ',
    previewer = 'builtin',
    _fmt = {
      from = function(entry)
        return preview_path_for_display(entry, display_to_path)
      end,
    },
    actions = {
      ['default'] = {
        fn = function(selected)
          if selected and selected[1] then
            local dir = display_to_path[selected[1]]
            if dir then
              switch_to_project(dir)
            end
          end
        end,
        header = 'switch',
      },
      ['ctrl-x'] = {
        fn = function(selected)
          if selected and selected[1] then
            kill_project_pane(selected[1])
          end
        end,
        reload = true,
        header = 'kill pane',
      },
    },
  })
end

function M.setup()
  vim.keymap.set('n', '<leader>pj', function()
    M.pick_project()
  end, { desc = 'Switch Project' })

  require('user.menu').add_actions('Project', {
    ['Switch project (<leader>pj)'] = function()
      M.pick_project()
    end,
  })
end

return M
