---@diagnostic disable: undefined-field, undefined-global, need-check-nil
--# selene: allow(undefined_variable)

local buffer = require 'user.run-buffer.buffer'
local command = require 'user.run-buffer.command'
local make = require 'user.run-buffer.handlers.make'
local notify_stub = require 'tests.notify_stub'
local package_json = require 'user.run-buffer.handlers.package_json'
local eq = assert.are.same

---@param fn (fun(...): string?|nil)?|nil
local function set_start_ls_stub(fn)
  ---@diagnostic disable-next-line: duplicate-set-field
  _G.start_ls = fn
end

---@param fn fun(cmd: string|string[], opts?: table): integer
local function set_jobstart_stub(fn)
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.fn.jobstart = fn
end

---@param fn fun(textlist: string[]): integer
local function set_inputlist_stub(fn)
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.fn.inputlist = fn
end

local function fresh_unnamed_buffer()
  vim.cmd 'enew'
  vim.bo.filetype = ''
  vim.bo.buftype = ''
end

local function fresh_named_buffer(path, ft)
  local f = assert(io.open(path, 'w'))
  f:close()
  vim.cmd 'enew'
  vim.api.nvim_buf_set_name(0, path)
  vim.bo.buftype = ''
  vim.bo.filetype = ft or ''
  vim.bo.modified = false
end

local function sync_result(ft, file_name, first_line)
  local parent = vim.fs.dirname(file_name)
  if parent and parent ~= '' and vim.fn.isdirectory(parent) == 0 then
    vim.fn.mkdir(parent, 'p')
  end
  if vim.fn.filereadable(file_name) == 0 then
    local f = assert(io.open(file_name, 'w'))
    f:close()
  end
  vim.cmd 'enew'
  vim.api.nvim_buf_set_name(0, file_name)
  vim.bo.buftype = ''
  vim.bo.modified = false
  if first_line and first_line ~= '' then
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { first_line })
  else
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
  end
  return command.build(ft, file_name)
end

describe('user.run-buffer', function()
  local original_start_ls
  local notify
  local notifications

  before_each(function()
    original_start_ls = _G.start_ls
    notify = notify_stub.install()
    notifications = notify.messages
  end)

  after_each(function()
    _G.start_ls = original_start_ls
    notify_stub.restore(notify)
    pcall(function()
      vim.cmd 'bwipeout!'
    end)
  end)

  describe('buffer.filename_and_ft - named buffer', function()
    it('returns the buffer path and its filetype', function()
      local tmp = vim.fn.tempname() .. '.sh'
      fresh_named_buffer(tmp, 'sh')

      local path, ft = buffer.filename_and_ft()
      eq(path, tmp)
      eq(ft, 'sh')
    end)

    it('defaults filetype to sh when empty', function()
      local tmp = vim.fn.tempname() .. '.unknown'
      fresh_named_buffer(tmp, '')

      local _, ft = buffer.filename_and_ft()
      eq(ft, 'sh')
    end)

    it('does not call _G.start_ls when buffer already has a name', function()
      local called = false
      set_start_ls_stub(function()
        called = true
      end)
      local tmp = vim.fn.tempname() .. '.sh'
      fresh_named_buffer(tmp, 'sh')

      buffer.filename_and_ft()
      assert.is_false(called)
    end)
  end)

  describe('buffer.filename_and_ft - unnamed buffer (regression guards)', function()
    it('calls _G.start_ls with `true` so a tempfile is written (REGRESSION GUARD)', function()
      local received_args
      set_start_ls_stub(function(...)
        received_args = { ... }
        vim.bo.modified = false
        return '/tmp/run-buffer-test.sh'
      end)
      fresh_unnamed_buffer()

      buffer.filename_and_ft()
      eq(received_args, { true })
    end)

    it('returns the path that _G.start_ls produced', function()
      set_start_ls_stub(function()
        vim.bo.modified = false
        return '/tmp/run-buffer-test.sh'
      end)
      fresh_unnamed_buffer()

      local path, ft = buffer.filename_and_ft()
      eq(path, '/tmp/run-buffer-test.sh')
      eq(ft, 'sh')
    end)

    it('propagates the existing filetype onto the buffer before calling start_ls', function()
      local observed_ft
      set_start_ls_stub(function()
        observed_ft = vim.bo.filetype
        vim.bo.modified = false
        return '/tmp/run-buffer-test.py'
      end)
      vim.cmd 'enew'
      vim.bo.buftype = ''
      vim.bo.filetype = 'python'

      buffer.filename_and_ft()
      eq(observed_ft, 'python')
    end)

    it('notifies (not silently no-ops) when _G.start_ls returns nil (CONTRACT GUARD)', function()
      set_start_ls_stub(function()
        return nil
      end)
      fresh_unnamed_buffer()

      local path, ft = buffer.filename_and_ft()
      eq(path, nil)
      eq(ft, nil)
      assert.is_true(#notifications >= 1)
      assert.is_true(notifications[1].msg:find 'start_ls' ~= nil)
      eq(notifications[1].level, vim.log.levels.ERROR)
    end)

    it('notifies when _G.start_ls returns an empty string', function()
      set_start_ls_stub(function()
        return ''
      end)
      fresh_unnamed_buffer()

      local path = buffer.filename_and_ft()
      eq(path, nil)
      assert.is_true(#notifications >= 1)
    end)

    it('notifies when _G.start_ls is not defined at all', function()
      set_start_ls_stub(nil)
      fresh_unnamed_buffer()

      local path = buffer.filename_and_ft()
      eq(path, nil)
      assert.is_true(#notifications >= 1)
      assert.is_true(notifications[1].msg:find 'start_ls' ~= nil)
      eq(notifications[1].level, vim.log.levels.ERROR)
    end)
  end)

  describe('command.build result cwd', function()
    local original_git
    local original_gh

    before_each(function()
      original_git = package.loaded['user.git']
      original_gh = package.loaded['user.gh-actions']
    end)

    after_each(function()
      package.loaded['user.git'] = original_git
      package.loaded['user.gh-actions'] = original_gh
    end)

    it('yaml.precommit runs pre-commit from git repo root', function()
      package.loaded['user.git'] = {
        get_toplevel_sync = function()
          return '/repo'
        end,
      }
      local config = '/repo/.pre-commit-config.yaml'
      local result = command.build('yaml.precommit', config)
      eq(result.cmd, 'pre-commit run --all-files')
      eq(result.spawn, true)
      eq(result.cwd, '/repo')
    end)

    it('yaml.ghaction includes git repo root when spawning', function()
      package.loaded['user.git'] = {
        get_toplevel_sync = function()
          return '/repo'
        end,
      }
      package.loaded['user.gh-actions'] = {
        build_act_cmd = function()
          return 'act -W /repo/.github/workflows/ci.yml'
        end,
      }
      local workflow = '/repo/.github/workflows/ci.yml'
      local result = command.build('yaml.ghaction', workflow)
      eq(result.cwd, '/repo')
    end)

    it('leaves cwd unset for default filetypes', function()
      local tmp = vim.fn.tempname() .. '.py'
      local result = sync_result('python', tmp, '')
      eq(result.cwd, nil)
    end)
  end)

  describe('command resolution', function()
    it('terraform runs terraform plan without appending the file path', function()
      local result = sync_result('terraform', '/tmp/main.tf', '')
      eq(result.cmd, 'terraform plan')
      eq(result.spawn, true)
    end)

    it('terraform runs terragrunt plan when terragrunt.hcl exists in the buffer directory', function()
      local dir = vim.fn.tempname()
      vim.fn.mkdir(dir, 'p')
      vim.fn.writefile({}, dir .. '/terragrunt.hcl')
      local result = sync_result('terraform', dir .. '/main.tf', '')
      eq(result.cmd, 'terragrunt plan')
      eq(result.spawn, true)
      vim.fn.delete(dir, 'rf')
    end)

    it('python appends the file path', function()
      local result = sync_result('python', '/tmp/script.py', '')
      eq(result.cmd, 'python3 /tmp/script.py')
      eq(result.spawn, true)
    end)

    it('yaml uses yq when vim.b.is_kubernetes is not set', function()
      vim.b.is_kubernetes = nil
      local result = sync_result('yaml', '/tmp/config.yaml', '')
      eq(result.cmd, 'yq /tmp/config.yaml')
      eq(result.spawn, true)
    end)

    it('yaml uses kubectl dry-run when vim.b.is_kubernetes is true', function()
      local manifest = '/tmp/deployment.yaml'
      fresh_named_buffer(manifest, 'yaml')
      vim.b.is_kubernetes = true
      local result = command.build('yaml', manifest)
      eq(result.cmd, 'kubectl apply --dry-run=client -f ' .. vim.fn.shellescape(manifest))
      eq(result.spawn, true)
    end)

    it('compound yaml filetypes use yq', function()
      local result = sync_result('yaml.docker-compose', '/tmp/docker-compose.yml', '')
      eq(result.cmd, 'yq /tmp/docker-compose.yml')
      eq(result.spawn, true)
    end)

    it('lua reloads the buffer and does not return a shell command', function()
      local original_cmd = vim.cmd
      local called
      vim.cmd = setmetatable({}, {
        __call = function(_, arg)
          called = arg
        end,
      })

      local result = sync_result('lua', '/tmp/nvim/lua/user/foo.lua', '')
      eq(result.cmd, nil)
      eq(result.spawn, false)
      eq(called, 'luafile %')

      vim.cmd = original_cmd
    end)

    it('groovy validates via jenkins-validate and does not return a shell command', function()
      local original_jv = package.loaded['user.jenkins-validate']
      local called = false
      package.loaded['user.jenkins-validate'] = {
        validate = function()
          called = true
        end,
      }

      local result = sync_result('groovy', '/tmp/Jenkinsfile', '')
      eq(result.cmd, nil)
      eq(result.spawn, false)
      assert.is_true(called)

      package.loaded['user.jenkins-validate'] = original_jv
    end)

    it('uses the file path when the shebang is present', function()
      local result = sync_result('sh', '/tmp/run.sh', '#!/bin/bash')
      eq(result.cmd, '/tmp/run.sh')
    end)

    it('markdown starts mdserve on a free port and does not return a shell command', function()
      local original_jobstart = vim.fn.jobstart
      local original_system = vim.fn.system
      local received
      set_jobstart_stub(function(cmd, opts)
        received = { cmd = cmd, opts = opts }
        return 42
      end)
      vim.fn.system = function()
        return ''
      end

      local result = sync_result('markdown', '/tmp/readme.md', '')
      eq(result.cmd, nil)
      eq(result.spawn, false)
      eq(received.cmd, {
        'mdserve',
        '--hostname',
        '127.0.0.1',
        '--port',
        '3000',
        '--open',
        '/tmp/readme.md',
      })
      eq(received.opts.detach, nil)
      eq(type(received.opts.on_exit), 'function')

      vim.fn.jobstart = original_jobstart
      vim.fn.system = original_system
    end)

    it('yaml.ghaction uses gh-actions to build the act command', function()
      local original_gh = package.loaded['user.gh-actions']
      local original_git = package.loaded['user.git']
      local workflow = '/repo/.github/workflows/ci.yml'
      package.loaded['user.gh-actions'] = {
        build_act_cmd = function(path)
          eq(path, workflow)
          return 'act --defaultbranch=master -W /repo/.github/workflows/ci.yml -e /tmp/event.json'
        end,
      }
      package.loaded['user.git'] = {
        get_toplevel_sync = function()
          return '/repo'
        end,
      }

      local result = command.build('yaml.ghaction', workflow)
      eq(result.cmd, 'act --defaultbranch=master -W /repo/.github/workflows/ci.yml -e /tmp/event.json')
      eq(result.spawn, true)
      eq(result.cwd, '/repo')

      package.loaded['user.gh-actions'] = original_gh
      package.loaded['user.git'] = original_git
    end)

    it('yaml.precommit breaks when not in a git repository', function()
      local original_git = package.loaded['user.git']
      package.loaded['user.git'] = {
        get_toplevel_sync = function()
          return ''
        end,
      }

      local result = command.build('yaml.precommit', '/tmp/.pre-commit-config.yaml')
      eq(result.cmd, nil)
      eq(result.spawn, false)

      package.loaded['user.git'] = original_git
    end)

    it('yaml.ghaction breaks when gh-actions returns nil', function()
      local original_gh = package.loaded['user.gh-actions']
      package.loaded['user.gh-actions'] = {
        build_act_cmd = function()
          return nil
        end,
      }

      local result = command.build('yaml.ghaction', '/repo/.github/workflows/ci.yml')
      eq(result.cmd, nil)
      eq(result.spawn, false)

      package.loaded['user.gh-actions'] = original_gh
    end)

    it('requirements runs pip install -r', function()
      local req = '/tmp/project/requirements.txt'
      local result = sync_result('requirements', req, '')
      eq(result.cmd, 'pip install -r ' .. vim.fn.shellescape(req))
      eq(result.spawn, true)
      eq(result.cwd, nil)
    end)

    it('make returns the selected target command', function()
      local makefile_path = vim.fn.tempname()
      local f = assert(io.open(makefile_path, 'w'))
      f:write 'all:\n\ntest:\n'
      f:close()

      local original_inputlist = vim.fn.inputlist
      set_inputlist_stub(function()
        return 2
      end)

      local result = sync_result('make', makefile_path, '')
      eq(result.cmd, 'make test')
      eq(result.spawn, true)

      vim.fn.inputlist = original_inputlist
      os.remove(makefile_path)
    end)

    it('json.package returns the selected npm run command', function()
      local dir = vim.fn.tempname()
      vim.fn.mkdir(dir, 'p')
      local pkg_path = dir .. '/package.json'
      local f = assert(io.open(pkg_path, 'w'))
      f:write '{"scripts":{"build":"tsc","test":"jest"}}'
      f:close()

      local original_inputlist = vim.fn.inputlist
      set_inputlist_stub(function()
        return 2
      end)

      local result = sync_result('json.package', pkg_path, '')
      eq(result.cmd, 'npm run test')
      eq(result.spawn, true)
      eq(result.cwd, nil)

      vim.fn.inputlist = original_inputlist
      vim.fn.delete(dir, 'rf')
    end)
  end)

  describe('make.pick_make_cmd', function()
    local makefile_path
    local original_inputlist

    before_each(function()
      makefile_path = vim.fn.tempname()
      local f = assert(io.open(makefile_path, 'w'))
      f:write 'all:\n\ntest:\n'
      f:close()
      original_inputlist = vim.fn.inputlist
    end)

    after_each(function()
      vim.fn.inputlist = original_inputlist
      os.remove(makefile_path)
    end)

    it('returns make <target> for the selected index', function()
      set_inputlist_stub(function()
        return 2
      end)
      eq(make.pick_make_cmd(makefile_path), 'make test')
    end)

    it('returns nil when the picker is cancelled', function()
      set_inputlist_stub(function()
        return -1
      end)
      eq(make.pick_make_cmd(makefile_path), nil)
    end)

    it('skips the picker when there is only one target', function()
      local single = vim.fn.tempname()
      local sf = assert(io.open(single, 'w'))
      sf:write 'all:\n'
      sf:close()
      local called = false
      set_inputlist_stub(function()
        called = true
        return 1
      end)
      eq(make.pick_make_cmd(single), 'make all')
      assert.is_false(called)
      os.remove(single)
    end)
  end)

  describe('Makefile target parsing', function()
    local makefile_path

    before_each(function()
      makefile_path = vim.fn.tempname()
      local f = assert(io.open(makefile_path, 'w'))
      f:write [[
.PHONY: all test prepare clean

NVIM_DIR := nvim/.config/nvim

all: test

prepare:
	@test -d ../plenary.nvim || git clone --depth 1 https://github.com/nvim-lua/plenary.nvim ../plenary.nvim

test: prepare
	nvim --headless --noplugin -u scripts/minimal_init.vim -c "PlenaryBustedDirectory lua/tests/ { minimal_init = './scripts/minimal_init.vim' }"

clean:
	rm -rf ../plenary.nvim
]]
      f:close()
    end)

    after_each(function()
      os.remove(makefile_path)
    end)

    it('lists only rule targets, not recipe lines with colons', function()
      local options = make.get_makefile_options(makefile_path)
      local values = vim.tbl_map(function(o)
        return o.value
      end, options)
      eq(values, { 'all', 'prepare', 'test', 'clean' })
    end)

    it('does not treat https:// in a tab-indented recipe as a target', function()
      local line = '\t@test -d x || git clone https://github.com/foo/bar'
      eq(make.makefile_target_name(line), nil)
    end)

    it('does not treat variable assignments as targets', function()
      eq(make.makefile_target_name 'VAR := value', nil)
      eq(make.makefile_target_name 'VAR ::= value', nil)
      eq(make.makefile_target_name 'VAR = value', nil)
    end)
  end)

  describe('package_json.pick_script_cmd', function()
    local pkg_path
    local original_inputlist

    local function write_pkg(contents)
      pkg_path = vim.fn.tempname()
      local f = assert(io.open(pkg_path, 'w'))
      f:write(contents)
      f:close()
    end

    before_each(function()
      original_inputlist = vim.fn.inputlist
    end)

    after_each(function()
      vim.fn.inputlist = original_inputlist
      if pkg_path then
        os.remove(pkg_path)
        pkg_path = nil
      end
    end)

    it('returns npm run <script> for the selected index', function()
      write_pkg '{"scripts":{"build":"tsc","test":"jest"}}'
      set_inputlist_stub(function()
        return 2
      end)
      eq(package_json.pick_script_cmd(pkg_path), 'npm run test')
    end)

    it('returns nil when the picker is cancelled', function()
      write_pkg '{"scripts":{"build":"tsc","test":"jest"}}'
      set_inputlist_stub(function()
        return 0
      end)
      eq(package_json.pick_script_cmd(pkg_path), nil)
    end)

    it('skips the picker when there is only one script', function()
      write_pkg '{"scripts":{"build":"tsc"}}'
      local called = false
      set_inputlist_stub(function()
        called = true
        return 1
      end)
      eq(package_json.pick_script_cmd(pkg_path), 'npm run build')
      assert.is_false(called)
    end)

    it('returns nil and notifies when there are no scripts', function()
      write_pkg '{"name":"x"}'
      eq(package_json.pick_script_cmd(pkg_path), nil)
      assert.is_true(#notifications > 0)
    end)
  end)

  describe('package.json script parsing', function()
    local pkg_path

    after_each(function()
      if pkg_path then
        os.remove(pkg_path)
        pkg_path = nil
      end
    end)

    it('lists scripts sorted by name', function()
      pkg_path = vim.fn.tempname()
      local f = assert(io.open(pkg_path, 'w'))
      f:write '{"scripts":{"test":"jest","build":"tsc","lint":"eslint"}}'
      f:close()
      local options = package_json.get_script_options(pkg_path)
      local values = vim.tbl_map(function(o)
        return o.value
      end, options)
      eq(values, { 'build', 'lint', 'test' })
    end)

    it('returns an empty list when scripts is missing', function()
      pkg_path = vim.fn.tempname()
      local f = assert(io.open(pkg_path, 'w'))
      f:write '{"name":"x"}'
      f:close()
      eq(package_json.get_script_options(pkg_path), {})
    end)

    it('returns an empty list for unreadable files', function()
      eq(package_json.get_script_options '/nonexistent/package.json', {})
    end)
  end)

  describe('helm handler', function()
    local chart_root
    local template_path

    local function write_chart(root, opts)
      opts = opts or {}
      vim.fn.mkdir(root, 'p')
      vim.fn.mkdir(vim.fs.joinpath(root, 'templates'), 'p')
      local lines = {
        'apiVersion: v2',
        'name: ' .. (opts.chart_name or 'x'),
        'version: 0.1.0',
      }
      if opts.dependencies then
        table.insert(lines, 'dependencies:')
        for _, name in ipairs(opts.dependencies) do
          table.insert(lines, '  - name: ' .. name)
          table.insert(lines, '    version: 1.0.0')
        end
      end
      vim.fn.writefile(lines, vim.fs.joinpath(root, 'Chart.yaml'))
      vim.fn.writefile({ 'apiVersion: v1', 'kind: ConfigMap' }, vim.fs.joinpath(root, 'templates', 'cm.yaml'))
    end

    before_each(function()
      chart_root = vim.fn.tempname() .. '-mychart'
      write_chart(chart_root)
      template_path = vim.fs.joinpath(chart_root, 'templates', 'cm.yaml')
    end)

    after_each(function()
      if chart_root then
        vim.fn.delete(chart_root, 'rf')
      end
    end)

    it('finds chart root upward from a nested template file', function()
      local result = command.build('helm', template_path)
      eq(result.cwd, vim.fs.normalize(chart_root))
      eq(result.spawn, true)
    end)

    it('yaml.chart on Chart.yaml uses the helm handler', function()
      local chart_yaml = vim.fs.joinpath(chart_root, 'Chart.yaml')
      local result = command.build('yaml.chart', chart_yaml)
      eq(result.cmd, 'helm template ' .. vim.fn.shellescape(vim.fs.basename(chart_root)) .. ' .')
      eq(result.spawn, true)
      eq(result.cwd, vim.fs.normalize(chart_root))
    end)

    it('templates the chart using the directory name as release name', function()
      local result = command.build('helm', template_path)
      local show_only = ' --show-only ' .. vim.fn.shellescape 'templates/cm.yaml'
      eq(result.cmd, 'helm template ' .. vim.fn.shellescape(vim.fs.basename(chart_root)) .. ' .' .. show_only)
      eq(result.spawn, true)
      eq(result.cwd, vim.fs.normalize(chart_root))
    end)

    it('runs helm dependency build when dependencies are missing from charts/', function()
      write_chart(chart_root, { dependencies = { 'nginx' } })
      local result = command.build('helm', template_path)
      local show_only = ' --show-only ' .. vim.fn.shellescape 'templates/cm.yaml'
      eq(result.cmd, 'helm dependency build; helm template ' .. vim.fn.shellescape(vim.fs.basename(chart_root)) .. ' .' .. show_only)
      eq(result.cwd, vim.fs.normalize(chart_root))
    end)

    it('skips helm dependency build when charts/ is populated', function()
      write_chart(chart_root, { dependencies = { 'nginx' } })
      local charts_dir = vim.fs.joinpath(chart_root, 'charts')
      vim.fn.mkdir(charts_dir, 'p')
      vim.fn.writefile({ '' }, vim.fs.joinpath(charts_dir, 'nginx-1.0.0.tgz'))
      local result = command.build('helm', template_path)
      local show_only = ' --show-only ' .. vim.fn.shellescape 'templates/cm.yaml'
      eq(result.cmd, 'helm template ' .. vim.fn.shellescape(vim.fs.basename(chart_root)) .. ' .' .. show_only)
    end)

    it('does not spawn when no Chart.yaml exists above the file', function()
      local orphan = vim.fn.tempname() .. '.yaml'
      local f = assert(io.open(orphan, 'w'))
      f:write 'kind: Pod'
      f:close()
      local result = command.build('helm', orphan)
      eq(result.spawn, false)
      os.remove(orphan)
    end)
  end)
end)
