local wezterm = require 'user.wezterm'

local M = {
  icon = '',
}

local NVIM_TITLE = 'nvim: (.+)$'
local DEFAULT_PJ_DIRS = '~/Repos/,~/.dotfiles'

local empty_preview_file

local function empty_preview_path()
  if not empty_preview_file then
    empty_preview_file = vim.fn.tempname()
    vim.fn.writefile({}, empty_preview_file)
  end
  return empty_preview_file
end

---@param panes table[]
---@return table<string, table> project_name -> pane
local function active_projects(panes)
  local active = {}
  for _, pane in ipairs(panes) do
    local name = pane.title:match(NVIM_TITLE)
    if name then
      active[name] = pane
    end
  end
  return active
end

---@return string[]
local function scan_project_dirs()
  local all_dirs = {}
  for _, path in ipairs(vim.split(vim.env.PJ_DIRS or DEFAULT_PJ_DIRS, ',', { trimempty = true })) do
    local expanded = vim.fn.expand(path)
    if expanded:match '/$' then
      expanded = expanded:gsub('/$', '')
      local handle = vim.uv.fs_scandir(expanded)
      if handle then
        while true do
          local name, typ = vim.uv.fs_scandir_next(handle)
          if not name then
            break
          end
          if typ == 'directory' then
            all_dirs[#all_dirs + 1] = expanded .. '/' .. name
          end
        end
      end
    else
      all_dirs[#all_dirs + 1] = expanded
    end
  end
  return all_dirs
end

---@param opts? { dirs?: string[]|fun(): string[], label?: fun(dir: string): string?, prompt?: string, actions?: table<string, { fn: fun(dir: string, pane: table|nil), header?: string, reload?: boolean }> }
---  dirs overrides the PJ_DIRS scan; label returns a suffix shown after the name (default: the checked-out branch); actions are extra/overriding fzf actions receiving the selected dir and its open wezterm pane
function M.pick_project(opts)
  opts = opts or {}
  local fzf = require 'fzf-lua'
  local display_to_path = {}

  local function extra_actions()
    local wrapped = {}
    for key, action in pairs(opts.actions or {}) do
      wrapped[key] = vim.tbl_extend('force', action, {
        fn = function(selected)
          local dir = selected and display_to_path[selected[1]]
          if dir then
            action.fn(dir, active_projects(wezterm.list())[vim.fn.fnamemodify(dir, ':t')])
          end
        end,
      })
    end
    return wrapped
  end

  fzf.fzf_exec(function(cb)
    for key in pairs(display_to_path) do
      display_to_path[key] = nil
    end

    local active = active_projects(wezterm.list())
    local all_dirs = type(opts.dirs) == 'function' and opts.dirs() or opts.dirs or scan_project_dirs()

    for _, dir in ipairs(all_dirs) do
      local name = vim.fn.fnamemodify(dir, ':t')
      local label = (opts.label or require('user.git').read_head_branch)(dir)
      local display_name = (active[name] and M.icon or ' ') .. ' ' .. name .. (label and ('  [' .. label .. ']') or '')
      cb(display_name)
      display_to_path[display_name] = dir
    end
    cb()
  end, {
    prompt = opts.prompt or 'Projects❯ ',
    previewer = 'builtin',
    _fmt = {
      from = function(entry)
        local dir = display_to_path[entry]
        if not dir then
          return empty_preview_path()
        end
        local readme = vim.fn.fnamemodify(vim.fn.expand(dir), ':p') .. 'README.md'
        if vim.fn.filereadable(readme) == 1 then
          return readme
        end
        return empty_preview_path()
      end,
    },
    actions = vim.tbl_extend('force', {
      ['default'] = {
        fn = function(selected)
          local display = selected and selected[1]
          local dir = display and display_to_path[display]
          if not dir then
            return
          end
          local pane = active_projects(wezterm.list())[vim.fn.fnamemodify(dir, ':t')]
          if pane then
            wezterm.activate_tab(pane.tab_id)
            wezterm.activate_pane(pane.pane_id)
          else
            wezterm.spawn_and_send('nvim' .. vim.keycode '<cr>', { cwd = vim.fn.expand(dir) })
          end
        end,
        header = 'switch',
      },
      ['ctrl-x'] = {
        fn = function(selected)
          local display = selected and selected[1]
          if not display then
            return
          end
          local dir = display_to_path[display]
          local project_name = dir and vim.fn.fnamemodify(dir, ':t')
          if not project_name then
            return
          end
          local pane = active_projects(wezterm.list())[project_name]
          if not pane then
            vim.notify('Project is not open: ' .. project_name, vim.log.levels.WARN)
            return
          end
          if not wezterm.kill_pane(pane.pane_id) then
            vim.notify('Failed to kill pane for ' .. project_name, vim.log.levels.ERROR)
          end
        end,
        reload = true,
        header = 'kill pane',
      },
    }, extra_actions()),
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
