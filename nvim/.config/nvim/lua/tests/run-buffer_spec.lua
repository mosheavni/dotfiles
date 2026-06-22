---@diagnostic disable: undefined-field, undefined-global, need-check-nil
--# selene: allow(undefined_variable)

local buffer = require 'user.run-buffer.buffer'
local make = require 'user.run-buffer.handlers.make'
local resolve = require 'user.run-buffer.resolve'
local eq = assert.are.same

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
  return resolve.resolve_sync { ft = ft, file_name = file_name, first_line = first_line or '' }
end

describe('user.run-buffer', function()
  local original_start_ls
  local original_notify
  local notifications

  before_each(function()
    original_start_ls = _G.start_ls
    original_notify = vim.notify
    notifications = {}
    vim.notify = function(msg, level, _opts)
      table.insert(notifications, { msg = msg, level = level })
    end
  end)

  after_each(function()
    _G.start_ls = original_start_ls
    vim.notify = original_notify
    pcall(vim.cmd, 'bwipeout!')
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
      _G.start_ls = function()
        called = true
      end
      local tmp = vim.fn.tempname() .. '.sh'
      fresh_named_buffer(tmp, 'sh')

      buffer.filename_and_ft()
      assert.is_false(called)
    end)
  end)

  describe('buffer.filename_and_ft - unnamed buffer (regression guards)', function()
    it('calls _G.start_ls with `true` so a tempfile is written (REGRESSION GUARD)', function()
      local received_args
      _G.start_ls = function(...)
        received_args = { ... }
        vim.bo.modified = false
        return '/tmp/run-buffer-test.sh'
      end
      fresh_unnamed_buffer()

      buffer.filename_and_ft()
      eq(received_args, { true })
    end)

    it('returns the path that _G.start_ls produced', function()
      _G.start_ls = function()
        vim.bo.modified = false
        return '/tmp/run-buffer-test.sh'
      end
      fresh_unnamed_buffer()

      local path, ft = buffer.filename_and_ft()
      eq(path, '/tmp/run-buffer-test.sh')
      eq(ft, 'sh')
    end)

    it('propagates the existing filetype onto the buffer before calling start_ls', function()
      local observed_ft
      _G.start_ls = function()
        observed_ft = vim.bo.filetype
        vim.bo.modified = false
        return '/tmp/run-buffer-test.py'
      end
      vim.cmd 'enew'
      vim.bo.buftype = ''
      vim.bo.filetype = 'python'

      buffer.filename_and_ft()
      eq(observed_ft, 'python')
    end)

    it('notifies (not silently no-ops) when _G.start_ls returns nil (CONTRACT GUARD)', function()
      _G.start_ls = function()
        return nil
      end
      fresh_unnamed_buffer()

      local path, ft = buffer.filename_and_ft()
      eq(path, nil)
      eq(ft, nil)
      assert.is_true(#notifications >= 1)
      assert.is_true(notifications[1].msg:find 'start_ls' ~= nil)
      eq(notifications[1].level, vim.log.levels.ERROR)
    end)

    it('notifies when _G.start_ls returns an empty string', function()
      _G.start_ls = function()
        return ''
      end
      fresh_unnamed_buffer()

      local path = buffer.filename_and_ft()
      eq(path, nil)
      assert.is_true(#notifications >= 1)
    end)

    it('notifies when _G.start_ls is not defined at all', function()
      _G.start_ls = nil
      fresh_unnamed_buffer()

      local path = buffer.filename_and_ft()
      eq(path, nil)
      assert.is_true(#notifications >= 1)
      assert.is_true(notifications[1].msg:find 'start_ls' ~= nil)
      eq(notifications[1].level, vim.log.levels.ERROR)
    end)

  end)

  describe('buffer.run_cwd', function()
    local original_git

    before_each(function()
      original_git = package.loaded['user.git']
    end)

    after_each(function()
      package.loaded['user.git'] = original_git
    end)

    it('uses git repo root for yaml.ghaction', function()
      package.loaded['user.git'] = {
        get_toplevel_sync = function()
          return '/repo'
        end,
      }
      eq(buffer.run_cwd 'yaml.ghaction', '/repo')
    end)

    it('falls back to the buffer directory when not in a git repo', function()
      package.loaded['user.git'] = {
        get_toplevel_sync = function()
          return ''
        end,
      }
      local tmp = vim.fn.tempname() .. '.yml'
      fresh_named_buffer(tmp, 'yaml.ghaction')
      eq(buffer.run_cwd 'yaml.ghaction', vim.fn.expand '%:p:h')
    end)

    it('uses the buffer directory for other filetypes', function()
      local tmp = vim.fn.tempname() .. '.py'
      fresh_named_buffer(tmp, 'python')
      eq(buffer.run_cwd 'python', vim.fn.expand '%:p:h')
    end)
  end)

  describe('command resolution', function()
    it('terraform runs terraform plan without appending the file path', function()
      local result = sync_result('terraform', '/tmp/main.tf', '')
      eq(result.cmd, 'terraform plan')
      eq(result.done, false)
    end)

    it('python appends the file path', function()
      local result = sync_result('python', '/tmp/script.py', '')
      eq(result.cmd, 'python3 /tmp/script.py')
      eq(result.done, false)
    end)

    it('yaml uses yq', function()
      local result = sync_result('yaml', '/tmp/config.yaml', '')
      eq(result.cmd, 'yq /tmp/config.yaml')
      eq(result.done, false)
    end)

    it('compound yaml filetypes use yq', function()
      local result = sync_result('yaml.docker-compose', '/tmp/docker-compose.yml', '')
      eq(result.cmd, 'yq /tmp/docker-compose.yml')
      eq(result.done, false)
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
      eq(result.done, true)
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
      eq(result.done, true)
      assert.is_true(called)

      package.loaded['user.jenkins-validate'] = original_jv
    end)

    it('uses the file path when the shebang is present', function()
      local result = sync_result('sh', '/tmp/run.sh', '#!/bin/bash')
      eq(result.cmd, '/tmp/run.sh')
    end)

    it('markdown starts mdserve detached and does not return a shell command', function()
      local original_jobstart = vim.fn.jobstart
      local received
      vim.fn.jobstart = function(cmd, opts)
        received = { cmd = cmd, opts = opts }
        return 42
      end

      local result = sync_result('markdown', '/tmp/readme.md', '')
      eq(result.cmd, nil)
      eq(result.done, true)
      eq(received.cmd, { 'mdserve', '--open', '/tmp/readme.md' })
      eq(received.opts.detach, true)

      vim.fn.jobstart = original_jobstart
    end)

    it('yaml.ghaction uses gh-actions to build the act command', function()
      local original_gh = package.loaded['user.gh-actions']
      local workflow = '/repo/.github/workflows/ci.yml'
      package.loaded['user.gh-actions'] = {
        build_act_cmd = function(path)
          eq(path, workflow)
          return 'act --defaultbranch=master -W /repo/.github/workflows/ci.yml -e /tmp/event.json'
        end,
      }

      local done_cmd
      local done_break
      resolve.run('yaml.ghaction', workflow, function(cmd, done)
        done_cmd = cmd
        done_break = done
      end)
      eq(done_cmd, 'act --defaultbranch=master -W /repo/.github/workflows/ci.yml -e /tmp/event.json')
      eq(done_break, false)

      package.loaded['user.gh-actions'] = original_gh
    end)

    it('yaml.ghaction breaks when gh-actions returns nil', function()
      local original_gh = package.loaded['user.gh-actions']
      package.loaded['user.gh-actions'] = {
        build_act_cmd = function()
          return nil
        end,
      }

      local done_cmd = 'pending'
      local done_break = false
      resolve.run('yaml.ghaction', '/repo/.github/workflows/ci.yml', function(cmd, done)
        done_cmd = cmd
        done_break = done
      end)
      eq(done_cmd, nil)
      eq(done_break, true)

      package.loaded['user.gh-actions'] = original_gh
    end)

    it('make returns the selected target command', function()
      local makefile_path = vim.fn.tempname()
      local f = assert(io.open(makefile_path, 'w'))
      f:write 'all:\n\ntest:\n'
      f:close()

      local original_ui_select = vim.ui.select
      vim.ui.select = function(_items, _opts, on_select)
        on_select('2 - test', 2)
      end

      local done_cmd
      resolve.run('make', makefile_path, function(cmd, done)
        done_cmd = cmd
        eq(done, false)
      end)
      eq(done_cmd, 'make test')

      vim.ui.select = original_ui_select
      os.remove(makefile_path)
    end)
  end)

  describe('make.get_make_async', function()
    local makefile_path
    local original_ui_select

    before_each(function()
      makefile_path = vim.fn.tempname()
      local f = assert(io.open(makefile_path, 'w'))
      f:write 'all:\n\ntest:\n'
      f:close()
      original_ui_select = vim.ui.select
    end)

    after_each(function()
      vim.ui.select = original_ui_select
      os.remove(makefile_path)
    end)

    it('returns make <target> for the selected index', function()
      vim.ui.select = function(_items, _opts, on_select)
        on_select('2 - test', 2)
      end
      local done_cmd
      make.get_make_async(makefile_path, function(cmd)
        done_cmd = cmd
      end)
      eq(done_cmd, 'make test')
    end)

    it('returns nil when the picker is cancelled', function()
      vim.ui.select = function(_items, _opts, on_select)
        on_select(nil, nil)
      end
      local done_cmd = 'pending'
      make.get_make_async(makefile_path, function(cmd)
        done_cmd = cmd
      end)
      eq(done_cmd, nil)
    end)
  end)

  describe('Makefile target parsing', function()
    local makefile_path

    before_each(function()
      makefile_path = vim.fn.tempname()
      local f = assert(io.open(makefile_path, 'w'))
      f:write [[
.PHONY: all test prepare clean

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
  end)
end)
