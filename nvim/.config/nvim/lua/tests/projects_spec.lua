---@diagnostic disable: undefined-field, undefined-global
--# selene: allow(undefined_variable)

local eq = assert.are.same
local menu = require 'user.menu'

local original_wezterm = package.loaded['user.wezterm']
local original_fzf = package.loaded['fzf-lua']
local original_pj_dirs = vim.env.PJ_DIRS

---@type table[]
local wezterm_panes = {}

---@type table
local wezterm_calls = {}

---@class FzfAction
---@field fn fun(selected: string[]|nil)
---@field reload? boolean
---@field header? string

---@class FzfCaptured
---@field items string[]|nil
---@field opts { prompt?: string, previewer?: string, _fmt?: { from: fun(entry: string): string }, actions: table<string, FzfAction|fun(selected: string[]|nil)> }

---@type FzfCaptured|nil
local fzf_captured = nil

local function reset_wezterm_calls()
  wezterm_calls = {
    activate_tab = {},
    activate_pane = {},
    spawn_and_send = {},
    kill_pane = {},
  }
end

local function install_wezterm_stub()
  package.loaded['user.wezterm'] = {
    list = function()
      return wezterm_panes
    end,
    activate_tab = function(tab_id)
      table.insert(wezterm_calls.activate_tab, tab_id)
    end,
    activate_pane = function(pane_id)
      table.insert(wezterm_calls.activate_pane, pane_id)
    end,
    spawn_and_send = function(text, opts)
      table.insert(wezterm_calls.spawn_and_send, { text = text, opts = opts })
    end,
    kill_pane = function(pane_id)
      table.insert(wezterm_calls.kill_pane, pane_id)
      return true
    end,
  }
end

local function install_fzf_stub()
  package.loaded['fzf-lua'] = {
    fzf_exec = function(items, opts)
      local captured_items = items
      if type(items) == 'function' then
        captured_items = {}
        items(function(entry)
          if entry then
            captured_items[#captured_items + 1] = entry
          end
        end)
      end
      fzf_captured = { items = captured_items, opts = opts }
    end,
  }
end

---@param action FzfAction|fun(selected: string[]|nil)
---@param selected string[]|nil
local function run_action(action, selected)
  if type(action) == 'table' then
    action.fn(selected)
  else
    action(selected)
  end
end

local function load_projects()
  package.loaded['user.projects'] = nil
  return require 'user.projects'
end

---@return FzfCaptured
local function require_fzf_captured()
  assert(fzf_captured, 'fzf_exec was not called')
  return fzf_captured
end

---@param base string
---@param names string[]
local function make_repo_tree(base, names)
  vim.fn.mkdir(base, 'p')
  for _, name in ipairs(names) do
    vim.fn.mkdir(base .. '/' .. name, 'p')
  end
end

local function project_action_keys()
  local keys = {}
  for key in pairs(menu.get_actions { prefix = 'Project' }) do
    keys[#keys + 1] = key
  end
  table.sort(keys)
  return keys
end

describe('user.projects', function()
  local tmp_root

  before_each(function()
    tmp_root = vim.fn.tempname()
    vim.fn.delete(tmp_root, 'rf')
    wezterm_panes = {}
    fzf_captured = nil
    reset_wezterm_calls()
    install_wezterm_stub()
    install_fzf_stub()
    vim.env.PJ_DIRS = tmp_root .. '/'
  end)

  after_each(function()
    package.loaded['user.projects'] = nil
    package.loaded['user.wezterm'] = original_wezterm
    package.loaded['fzf-lua'] = original_fzf
    if original_pj_dirs == nil then
      vim.env.PJ_DIRS = nil
    else
      vim.env.PJ_DIRS = original_pj_dirs
    end
    vim.fn.delete(tmp_root, 'rf')
    for key in pairs(menu.get_actions { prefix = 'Project' }) do
      menu.actions[key] = nil
    end
  end)

  describe('pick_project', function()
    it('lists subdirectories when PJ_DIRS path ends with /', function()
      make_repo_tree(tmp_root, { 'alpha', 'beta' })
      local projects = load_projects()

      projects.pick_project()

      local captured = require_fzf_captured()
      table.sort(captured.items)
      eq({ '  alpha', '  beta' }, captured.items)
      eq('Projects❯ ', captured.opts.prompt)
    end)

    it('lists a single directory when PJ_DIRS path has no trailing /', function()
      local only = tmp_root .. '/solo'
      vim.fn.mkdir(only, 'p')
      vim.env.PJ_DIRS = only
      local projects = load_projects()

      projects.pick_project()

      eq({ '  solo' }, require_fzf_captured().items)
    end)

    it('marks active wezterm nvim panes with the project icon', function()
      make_repo_tree(tmp_root, { 'active-one', 'idle-two' })
      wezterm_panes = {
        { title = 'nvim: active-one', tab_id = 11, pane_id = 22 },
      }
      local projects = load_projects()

      projects.pick_project()

      local captured = require_fzf_captured()
      local items = {}
      for _, item in ipairs(captured.items) do
        items[item:match '%s+(.*)$'] = item
      end
      eq(projects.icon .. ' active-one', items['active-one'])
      eq('  idle-two', items['idle-two'])
    end)

    it('activates an existing tab when the selected project is already open', function()
      local project = tmp_root .. '/existing'
      vim.fn.mkdir(project, 'p')
      vim.env.PJ_DIRS = project
      wezterm_panes = {
        { title = 'nvim: existing', tab_id = 3, pane_id = 4 },
      }
      local projects = load_projects()

      projects.pick_project()
      local captured = require_fzf_captured()
      run_action(captured.opts.actions.default, { captured.items[1] })

      eq({ 3 }, wezterm_calls.activate_tab)
      eq({ 4 }, wezterm_calls.activate_pane)
      eq({}, wezterm_calls.spawn_and_send)
    end)

    it('spawns nvim in a new tab when the selected project is not open', function()
      local project = tmp_root .. '/fresh'
      vim.fn.mkdir(project, 'p')
      vim.env.PJ_DIRS = project
      local projects = load_projects()

      projects.pick_project()
      run_action(require_fzf_captured().opts.actions.default, { '  fresh' })

      eq({}, wezterm_calls.activate_tab)
      eq({}, wezterm_calls.activate_pane)
      eq(1, #wezterm_calls.spawn_and_send)
      eq('nvim' .. vim.keycode '<cr>', wezterm_calls.spawn_and_send[1].text)
      eq(project, wezterm_calls.spawn_and_send[1].opts.cwd)
    end)

    it('matches project names literally when finding an existing tab', function()
      local project = tmp_root .. '/proj.a'
      vim.fn.mkdir(project, 'p')
      vim.env.PJ_DIRS = project
      wezterm_panes = {
        { title = 'nvim: proj.a', tab_id = 7, pane_id = 8 },
      }
      local projects = load_projects()

      projects.pick_project()
      local captured = require_fzf_captured()
      run_action(captured.opts.actions.default, { captured.items[1] })

      eq({ 7 }, wezterm_calls.activate_tab)
      eq({ 8 }, wezterm_calls.activate_pane)
    end)

    it('does nothing when fzf returns no selection', function()
      local project = tmp_root .. '/ignored'
      vim.fn.mkdir(project, 'p')
      vim.env.PJ_DIRS = project
      local projects = load_projects()

      projects.pick_project()
      local captured = require_fzf_captured()
      run_action(captured.opts.actions.default, nil)
      run_action(captured.opts.actions.default, {})

      eq({}, wezterm_calls.activate_tab)
      eq({}, wezterm_calls.activate_pane)
      eq({}, wezterm_calls.spawn_and_send)
    end)

    it('uses the builtin previewer for README.md when present', function()
      local project = tmp_root .. '/with-readme'
      vim.fn.mkdir(project, 'p')
      local readme = project .. '/README.md'
      vim.fn.writefile({ '# Hello' }, readme)
      vim.env.PJ_DIRS = project
      local projects = load_projects()

      projects.pick_project()

      local captured = require_fzf_captured()
      eq('builtin', captured.opts.previewer)
      assert.is_function(captured.opts._fmt.from)
      eq(readme, captured.opts._fmt.from(captured.items[1]))
    end)

    it('previews an empty file when README.md is missing', function()
      local project = tmp_root .. '/no-readme'
      vim.fn.mkdir(project, 'p')
      vim.env.PJ_DIRS = project
      local projects = load_projects()

      projects.pick_project()

      local captured = require_fzf_captured()
      local preview_path = captured.opts._fmt.from(captured.items[1])
      assert.is_not_nil(preview_path)
      assert.is_not.same(project .. '/README.md', preview_path)
      eq({}, vim.fn.readfile(preview_path))
    end)

    it('kills the wezterm pane for an open project on ctrl-x', function()
      make_repo_tree(tmp_root, { 'open-one', 'closed-two' })
      wezterm_panes = {
        { title = 'nvim: open-one', tab_id = 11, pane_id = 22 },
      }
      local projects = load_projects()

      projects.pick_project()

      local captured = require_fzf_captured()
      local open_entry = nil
      for _, item in ipairs(captured.items) do
        if item:match 'open%-one$' then
          open_entry = item
          break
        end
      end
      assert.is_not_nil(open_entry)
      run_action(captured.opts.actions['ctrl-x'], { open_entry })

      eq({ 22 }, wezterm_calls.kill_pane)
    end)

    it('does not kill a pane when the selected project is not open', function()
      make_repo_tree(tmp_root, { 'closed-only' })
      local projects = load_projects()

      projects.pick_project()

      local captured = require_fzf_captured()
      run_action(captured.opts.actions['ctrl-x'], { captured.items[1] })

      eq({}, wezterm_calls.kill_pane)
    end)

    it('spawns a new tab after killing the project pane in the same picker session', function()
      local project = tmp_root .. '/reopen'
      vim.fn.mkdir(project, 'p')
      vim.env.PJ_DIRS = project
      wezterm_panes = {
        { title = 'nvim: reopen', tab_id = 11, pane_id = 22 },
      }
      local projects = load_projects()

      projects.pick_project()

      local captured = require_fzf_captured()
      local entry = captured.items[1]
      run_action(captured.opts.actions['ctrl-x'], { entry })
      wezterm_panes = {}
      run_action(captured.opts.actions.default, { entry })

      eq({}, wezterm_calls.activate_tab)
      eq({}, wezterm_calls.activate_pane)
      eq(1, #wezterm_calls.spawn_and_send)
      eq(project, wezterm_calls.spawn_and_send[1].opts.cwd)
    end)
  end)

  describe('setup', function()
    it('registers leader pj and adds a Project menu action', function()
      vim.g.mapleader = ' '
      local projects = load_projects()
      local before_keys = project_action_keys()

      projects.setup()

      assert.is_true(vim.fn.maparg(' pj', 'n', false, true).callback ~= nil)
      local after_keys = project_action_keys()
      eq(#before_keys + 1, #after_keys)
      assert.is_true(vim.tbl_contains(after_keys, '[Project] Switch project (<leader>pj)'))
    end)
  end)
end)
