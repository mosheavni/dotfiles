---@diagnostic disable: undefined-field, undefined-global, need-check-nil
--# selene: allow(undefined_variable)

-- Tests for user.run-buffer.
--
-- The original regression these tests guard against: filename_and_ft used to
-- call `_G.start_ls()` without arguments. After the lsp/config.lua refactor
-- in commit 2f1fce9d (July 2025) made tempfile creation opt-in via
-- `with_file = true`, the no-arg call started silently returning nil and
-- <F3> on an unnamed buffer became a no-op. The tests below pin down both
-- the call-site (start_ls receives `true`) and the runtime contract
-- (a non-string return is reported, not swallowed).

local rb = require 'user.run-buffer'
local eq = assert.are.same

local function fresh_unnamed_buffer()
  vim.cmd 'enew'
  vim.bo.filetype = ''
  vim.bo.buftype = ''
end

local function fresh_named_buffer(path, ft)
  vim.cmd('edit ' .. vim.fn.fnameescape(path))
  vim.bo.filetype = ft or ''
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

  describe('filename_and_ft - named buffer', function()
    it('returns the buffer path and its filetype', function()
      local tmp = vim.fn.tempname() .. '.sh'
      fresh_named_buffer(tmp, 'sh')

      local path, ft = rb._filename_and_ft()
      eq(path, tmp)
      eq(ft, 'sh')
    end)

    it('defaults filetype to sh when empty', function()
      local tmp = vim.fn.tempname() .. '.unknown'
      fresh_named_buffer(tmp, '')

      local _, ft = rb._filename_and_ft()
      eq(ft, 'sh')
    end)

    it('does not call _G.start_ls when buffer already has a name', function()
      local called = false
      _G.start_ls = function()
        called = true
      end
      local tmp = vim.fn.tempname() .. '.sh'
      fresh_named_buffer(tmp, 'sh')

      rb._filename_and_ft()
      assert.is_false(called)
    end)
  end)

  describe('filename_and_ft - unnamed buffer (regression guards)', function()
    it('calls _G.start_ls with `true` so a tempfile is written (REGRESSION GUARD)', function()
      -- This is THE test that would have caught the original bug.
      -- If someone removes the `true` argument again, this fails loudly.
      local received_args
      _G.start_ls = function(...)
        received_args = { ... }
        -- Mimic the real start_ls(true) post-condition: buffer was written
        -- to disk by tmp_write, so it's no longer modified.
        vim.bo.modified = false
        return '/tmp/run-buffer-test.sh'
      end
      fresh_unnamed_buffer()

      rb._filename_and_ft()
      eq(received_args, { true })
    end)

    it('returns the path that _G.start_ls produced', function()
      _G.start_ls = function()
        vim.bo.modified = false
        return '/tmp/run-buffer-test.sh'
      end
      fresh_unnamed_buffer()

      local path, ft = rb._filename_and_ft()
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

      rb._filename_and_ft()
      eq(observed_ft, 'python')
    end)

    it('notifies (not silently no-ops) when _G.start_ls returns nil (CONTRACT GUARD)', function()
      _G.start_ls = function()
        return nil
      end
      fresh_unnamed_buffer()

      local path, ft = rb._filename_and_ft()
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

      local path = rb._filename_and_ft()
      eq(path, nil)
      assert.is_true(#notifications >= 1)
    end)

    it('notifies when _G.start_ls is not defined at all', function()
      _G.start_ls = nil
      fresh_unnamed_buffer()

      local path = rb._filename_and_ft()
      eq(path, nil)
      assert.is_true(#notifications >= 1)
      assert.is_true(notifications[1].msg:find 'start_ls' ~= nil)
      eq(notifications[1].level, vim.log.levels.ERROR)
    end)
  end)

  describe('per-file terminal tracking (statusline + cycling API)', function()
    -- The terminal logic itself depends on a real shell job; we don't drive
    -- execute_file from here. These tests pin the public API used by the
    -- statusline and ]t/[t cycling so they stay cheap and side-effect-free.

    -- Stand-in for a real terminal: a fresh scratch buffer whose bufnr is
    -- valid for as long as the test holds it. We pair it with a fake job_id
    -- that utils.job_alive() will reject so terminal_usable() returns false; for
    -- tests where we DO want a usable entry we stub vim.fn.jobpid.
    local original_jobpid

    before_each(function()
      for k in pairs(rb._terminals) do
        rb._terminals[k] = nil
      end
      original_jobpid = vim.fn.jobpid
      vim.fn.jobpid = function()
        return 12345
      end
    end)

    after_each(function()
      vim.fn.jobpid = original_jobpid
    end)

    it('reports zero terminals when none are tracked', function()
      eq(rb.list_terminals(), {})
    end)

    it('ignores entries whose buffer is invalid', function()
      rb._terminals['/tmp/fake.sh'] = { buf = 999999, job_id = 1, cwd = '/tmp' }
      eq(rb.list_terminals(), {})
    end)

    it('ignores entries whose job is no longer running', function()
      vim.fn.jobpid = function()
        return 0
      end
      local buf = vim.api.nvim_create_buf(false, true)
      rb._terminals['/tmp/dead.sh'] = { buf = buf, job_id = 1, cwd = '/tmp' }
      eq(rb.list_terminals(), {})
    end)

    it('ignores entries whose job id is no longer valid (E900)', function()
      vim.fn.jobpid = function()
        error('E900: Invalid channel id', 0)
      end
      local buf = vim.api.nvim_create_buf(false, true)
      rb._terminals['/tmp/stale.sh'] = { buf = buf, job_id = 1, cwd = '/tmp' }
      eq(rb.list_terminals(), {})
    end)

    it('list_terminals returns entries sorted by buf id (creation order)', function()
      local buf_a = vim.api.nvim_create_buf(false, true)
      local buf_b = vim.api.nvim_create_buf(false, true)
      assert.is_true(buf_a < buf_b)
      -- Insert in reverse so we know sort, not insertion order, drives it.
      rb._terminals['/tmp/zzz.sh'] = { buf = buf_b, job_id = 1, cwd = '/tmp' }
      rb._terminals['/tmp/aaa.sh'] = { buf = buf_a, job_id = 1, cwd = '/tmp' }

      local list = rb.list_terminals()
      eq(#list, 2)
      eq(list[1].file, '/tmp/aaa.sh')
      eq(list[1].basename, 'aaa.sh')
      eq(list[2].file, '/tmp/zzz.sh')
      eq(list[2].basename, 'zzz.sh')
    end)

    it('marks the entry whose file is the current buffer as active', function()
      local tmp = vim.fn.tempname() .. '.sh'
      fresh_named_buffer(tmp, 'sh')
      local term_buf = vim.api.nvim_create_buf(false, true)
      rb._terminals[tmp] = { buf = term_buf, job_id = 1, cwd = '/tmp' }
      local other = vim.api.nvim_create_buf(false, true)
      rb._terminals['/tmp/other.sh'] = { buf = other, job_id = 1, cwd = '/tmp' }

      local list = rb.list_terminals()
      local active = {}
      for _, item in ipairs(list) do
        if item.is_active then
          table.insert(active, item.file)
        end
      end
      eq(active, { tmp })
    end)

    it('cycle_terminal is a no-op when fewer than 2 terminals exist', function()
      local buf_a = vim.api.nvim_create_buf(false, true)
      rb._terminals['/tmp/only.sh'] = { buf = buf_a, job_id = 1, cwd = '/tmp' }
      local before = vim.api.nvim_get_current_buf()
      rb.cycle_terminal 'next'
      eq(vim.api.nvim_get_current_buf(), before)
    end)

    it('_clear_terminal_for_buf drops the matching entry', function()
      local buf_a = vim.api.nvim_create_buf(false, true)
      rb._terminals['/tmp/wipe.sh'] = { buf = buf_a, job_id = 1, cwd = '/tmp' }
      rb._clear_terminal_for_buf(buf_a)
      eq(rb._terminals['/tmp/wipe.sh'], nil)
    end)

    it('is_run_buffer_terminal_buf is true for buffers in the terminals table', function()
      local buf = vim.api.nvim_create_buf(true, false)
      rb._terminals['/tmp/foo.sh'] = { buf = buf, job_id = 1, cwd = '/tmp' }
      assert.is_true(rb.is_run_buffer_terminal_buf(buf))
      local other = vim.api.nvim_create_buf(true, false)
      assert.is_false(rb.is_run_buffer_terminal_buf(other))
    end)
  end)

  describe('_run_cwd', function()
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
      eq(rb._run_cwd('yaml.ghaction'), '/repo')
    end)

    it('falls back to the buffer directory when not in a git repo', function()
      package.loaded['user.git'] = {
        get_toplevel_sync = function()
          return ''
        end,
      }
      local tmp = vim.fn.tempname() .. '.yml'
      fresh_named_buffer(tmp, 'yaml.ghaction')
      eq(rb._run_cwd('yaml.ghaction'), vim.fn.expand '%:p:h')
    end)

    it('uses the buffer directory for other filetypes', function()
      local tmp = vim.fn.tempname() .. '.py'
      fresh_named_buffer(tmp, 'python')
      eq(rb._run_cwd('python'), vim.fn.expand '%:p:h')
    end)
  end)

  describe('_resolve_cmd', function()
    it('terraform runs terragrunt plan without appending the file path', function()
      local cmd, should_break = rb._resolve_cmd('terraform', '/tmp/main.tf', '')
      eq(cmd, 'terragrunt plan')
      eq(should_break, false)
    end)

    it('python appends the file path', function()
      local cmd, should_break = rb._resolve_cmd('python', '/tmp/script.py', '')
      eq(cmd, 'python3 /tmp/script.py')
      eq(should_break, false)
    end)

    it('yaml uses yq', function()
      local cmd, should_break = rb._resolve_cmd('yaml', '/tmp/config.yaml', '')
      eq(cmd, 'yq /tmp/config.yaml')
      eq(should_break, false)
    end)

    it('compound yaml filetypes use yq', function()
      local cmd, should_break = rb._resolve_cmd('yaml.docker-compose', '/tmp/docker-compose.yml', '')
      eq(cmd, 'yq /tmp/docker-compose.yml')
      eq(should_break, false)
    end)

    it('yaml.ghaction runs act with the workflow path', function()
      local cmd, should_break = rb._resolve_cmd('yaml.ghaction', '/repo/.github/workflows/ci.yml', '')
      eq(cmd, 'act -W /repo/.github/workflows/ci.yml')
      eq(should_break, false)
    end)

    it('uses the file path when the shebang is present', function()
      local cmd = rb._resolve_cmd('sh', '/tmp/run.sh', '#!/bin/bash')
      eq(cmd, '/tmp/run.sh')
    end)
  end)

  describe('get_make_async', function()
    local makefile_path
    local original_ui_select

    before_each(function()
      makefile_path = vim.fn.tempname()
      local f = assert(io.open(makefile_path, 'w'))
      f:write('all:\n\ntest:\n')
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
      rb._get_make_async(makefile_path, function(cmd)
        done_cmd = cmd
      end)
      eq(done_cmd, 'make test')
    end)

    it('returns nil when the picker is cancelled', function()
      vim.ui.select = function(_items, _opts, on_select)
        on_select(nil, nil)
      end
      local done_cmd = 'pending'
      rb._get_make_async(makefile_path, function(cmd)
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
      f:write([[
.PHONY: all test prepare clean

all: test

prepare:
	@test -d ../plenary.nvim || git clone --depth 1 https://github.com/nvim-lua/plenary.nvim ../plenary.nvim

test: prepare
	nvim --headless --noplugin -u scripts/minimal_init.vim -c "PlenaryBustedDirectory lua/tests/ { minimal_init = './scripts/minimal_init.vim' }"

clean:
	rm -rf ../plenary.nvim
]])
      f:close()
      package.loaded['user.run-buffer'] = nil
    end)

    after_each(function()
      os.remove(makefile_path)
      package.loaded['user.run-buffer'] = nil
    end)

    it('lists only rule targets, not recipe lines with colons', function()
      local mod = require 'user.run-buffer'
      local options = mod._get_makefile_options(makefile_path)
      local values = vim.tbl_map(function(o)
        return o.value
      end, options)
      eq(values, { 'all', 'prepare', 'test', 'clean' })
    end)

    it('does not treat https:// in a tab-indented recipe as a target', function()
      local mod = require 'user.run-buffer'
      local line = '\t@test -d x || git clone https://github.com/foo/bar'
      eq(mod._makefile_target_name(line), nil)
    end)
  end)
end)
