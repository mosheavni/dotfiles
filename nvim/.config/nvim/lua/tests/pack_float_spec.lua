---@diagnostic disable: undefined-field
--# selene: allow(undefined_variable)
local eq = assert.are.same

---@return vim.SystemCompleted
local function system_ok(stdout)
  return { code = 0, stdout = stdout or '', stderr = '', signal = 0 }
end

---@return vim.SystemObj
local function system_obj(stdout)
  return {
    wait = function()
      return system_ok(stdout or '2.3.1')
    end,
  }
end

---@param fn fun(command: string[], opts?: vim.SystemOpts, on_exit?: fun(result: vim.SystemCompleted)): vim.SystemObj
local function set_system_stub(fn)
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.system = fn
end

local function includes(lines, expected)
  for _, line in ipairs(lines) do
    if line == expected then
      return true
    end
  end
  return false
end

local function has_highlight(lines, text, hl_group)
  local ns_id = vim.api.nvim_get_namespaces().pack_float_ui
  local marks = vim.api.nvim_buf_get_extmarks(0, ns_id, 0, -1, { details = true })

  for row, line in ipairs(lines) do
    local start_col = line:find(text, 1, true)
    if start_col then
      start_col = start_col - 1
      for _, mark in ipairs(marks) do
        local details = mark[4]
        if details and mark[2] == row - 1 and mark[3] == start_col and details.end_col == start_col + #text and details.hl_group == hl_group then
          return true
        end
      end
    end
  end

  return false
end

describe('user.pack.float', function()
  local original_pack
  local original_system
  local original_diffview
  local original_git_conflict
  local original_user_pack

  before_each(function()
    original_pack = vim.pack
    original_system = vim.system
    original_diffview = package.preload.diffview
    original_git_conflict = package.preload['git-conflict']
    original_user_pack = package.loaded['user.pack']
    package.loaded['user.pack'] = {}
    package.loaded['user.pack.float'] = nil
    package.preload.diffview = function()
      return { setup = function() end }
    end
    package.preload['git-conflict'] = function()
      return { setup = function() end }
    end
    pcall(vim.api.nvim_del_user_command, 'PackFloat')
    vim.o.columns = 120
    vim.o.lines = 40
  end)

  after_each(function()
    if vim.api.nvim_win_is_valid(0) then
      pcall(vim.api.nvim_win_close, 0, true)
    end
    vim.pack = original_pack
    vim.system = original_system
    package.preload.diffview = original_diffview
    package.preload['git-conflict'] = original_git_conflict
    package.loaded['user.pack'] = original_user_pack
    package.loaded['user.pack.float'] = nil
    pcall(vim.api.nvim_del_user_command, 'PackFloat')
  end)

  it('does not start git work immediately on open', function()
    local system_calls = 0

    vim.pack = {
      get = function()
        return {
          {
            active = true,
            path = '/tmp/alpha.nvim',
            rev = '1111111111111111111111111111111111111111',
            spec = {
              name = 'alpha.nvim',
              src = 'https://github.com/example/alpha.nvim',
            },
          },
        }
      end,
    }
    set_system_stub(function()
      system_calls = system_calls + 1
      return system_obj()
    end)

    require('user.pack.float').open()

    eq(0, system_calls)
  end)

  it('batches fetch work after open', function()
    local plugins = {}
    for i = 1, 10 do
      plugins[i] = {
        active = true,
        path = ('/tmp/plugin-%02d.nvim'):format(i),
        rev = '1111111111111111111111111111111111111111',
        spec = {
          name = ('plugin-%02d.nvim'):format(i),
          src = ('https://github.com/example/plugin-%02d.nvim'):format(i),
        },
      }
    end

    local fetch_callbacks = {}
    local active_fetches = 0
    local max_active_fetches = 0

    vim.pack = {
      add = function() end,
      get = function(names)
        if type(names) == 'table' then
          for _, plugin in ipairs(plugins) do
            if plugin.spec.name == names[1] then
              return { plugin }
            end
          end
        end
        return plugins
      end,
    }
    set_system_stub(function(command, _, on_exit)
      if command[1] == 'git' and command[4] == 'fetch' then
        active_fetches = active_fetches + 1
        max_active_fetches = math.max(max_active_fetches, active_fetches)
        fetch_callbacks[#fetch_callbacks + 1] = function()
          active_fetches = active_fetches - 1
          if on_exit then
            on_exit(system_ok())
          end
        end
      elseif on_exit then
        on_exit(system_ok '2.3.1')
      end
      return system_obj()
    end)

    require('user.pack.float').open { fetch = false }
    vim.fn.maparg('r', 'n', false, true).callback()

    eq(6, #fetch_callbacks)
    eq(6, max_active_fetches)

    fetch_callbacks[1]()
    assert.is_true(vim.wait(200, function()
      return #fetch_callbacks == 7
    end))
    eq(6, max_active_fetches)
  end)

  it('shows the last five commits under the plugin description', function()
    local plugin = {
      active = true,
      path = '/tmp/alpha.nvim',
      rev = '1111111111111111111111111111111111111111',
      spec = {
        desc = 'Alpha plugin',
        name = 'alpha.nvim',
        src = 'https://github.com/example/alpha.nvim',
      },
    }
    local git_log_command

    vim.pack = {
      add = function() end,
      get = function()
        return { plugin }
      end,
    }
    set_system_stub(function(command, _, on_exit)
      if command[1] == 'git' and command[3] == plugin.path then
        git_log_command = command
        if on_exit then
          on_exit(system_ok(table.concat({
            'abc00005 2024-06-05 fifth commit',
            'abc00004 2024-06-04 fourth commit',
            'abc00003 2024-06-03 third commit',
            'abc00002 2024-06-02 second commit',
            'abc00001 2024-06-01 first commit',
          }, '\n')))
        end
      elseif on_exit then
        on_exit(system_ok '2.3.1')
      end
      return system_obj()
    end)

    require('user.pack.float').open { fetch = false }
    eq(nil, git_log_command)

    local plugin_line
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    for row, line in ipairs(lines) do
      if line:find('alpha.nvim', 1, true) then
        plugin_line = row
        break
      end
    end
    assert.is_not_nil(plugin_line)

    vim.api.nvim_win_set_cursor(0, { plugin_line, 0 })
    vim.fn.maparg('<CR>', 'n', false, true).callback()
    vim.wait(100, function()
      return includes(vim.api.nvim_buf_get_lines(0, 0, -1, false), '    abc00001 2024-06-01 first commit')
    end)

    lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.is_true(includes(lines, '    desc: Alpha plugin'))
    assert.is_true(includes(lines, '    recent commits:'))
    assert.is_true(includes(lines, '    abc00005 2024-06-05 fifth commit'))
    assert.is_true(includes(lines, '    abc00004 2024-06-04 fourth commit'))
    assert.is_true(includes(lines, '    abc00003 2024-06-03 third commit'))
    assert.is_true(includes(lines, '    abc00002 2024-06-02 second commit'))
    assert.is_true(includes(lines, '    abc00001 2024-06-01 first commit'))
    eq({
      'git',
      '-C',
      '/tmp/alpha.nvim',
      'log',
      '--pretty=format:%h %ad%d %s',
      '--date=short',
      '--decorate=short',
      '-5',
    }, git_log_command)
  end)

  it('highlights conventional commit prefixes by type', function()
    local plugin = {
      active = true,
      path = '/tmp/alpha.nvim',
      rev = '1111111111111111111111111111111111111111',
      spec = {
        name = 'alpha.nvim',
        src = 'https://github.com/example/alpha.nvim',
      },
    }

    vim.pack = {
      add = function() end,
      get = function()
        return { plugin }
      end,
    }
    set_system_stub(function(command, _, on_exit)
      if command[1] == 'git' and command[3] == plugin.path then
        if on_exit then
          on_exit(system_ok(table.concat({
            'abc00004 2024-06-04 (HEAD, origin/main, origin/HEAD, main) feat(actions): add selection',
            'abc00003 2024-06-03 build(ci): update workflow',
            'abc00002 2024-06-02 feat(parser)!: support scoped commits',
            'abc00001 2024-06-01 fix(ui): correct colors',
          }, '\n')))
        end
      elseif on_exit then
        on_exit(system_ok '2.3.1')
      end
      return system_obj()
    end)

    require('user.pack.float').open { fetch = false }

    local plugin_line
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    for row, line in ipairs(lines) do
      if line:find('alpha.nvim', 1, true) then
        plugin_line = row
        break
      end
    end
    assert.is_not_nil(plugin_line)

    vim.api.nvim_win_set_cursor(0, { plugin_line, 0 })
    vim.fn.maparg('<CR>', 'n', false, true).callback()
    assert.is_true(vim.wait(100, function()
      return includes(vim.api.nvim_buf_get_lines(0, 0, -1, false), '    abc00001 2024-06-01 fix(ui): correct colors')
    end))

    lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.is_true(has_highlight(lines, 'feat(actions):', 'PackFloatCommitFeat'))
    assert.is_true(has_highlight(lines, 'feat(parser)!:', 'PackFloatCommitFeat'))
    assert.is_true(has_highlight(lines, 'fix(ui):', 'PackFloatCommitFix'))
    assert.is_true(has_highlight(lines, 'build(ci):', 'PackFloatCommitBuild'))
  end)
end)
