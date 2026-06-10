---@diagnostic disable: undefined-field, undefined-global, need-check-nil
--# selene: allow(undefined_variable)

local term = require 'user.terminal'
local eq = assert.are.same

local function fresh_named_buffer(path, ft)
  vim.cmd('edit ' .. vim.fn.fnameescape(path))
  vim.bo.filetype = ft or ''
end

describe('user.terminal', function()
  local original_jobpid

  before_each(function()
    for k in pairs(term._by_id) do
      term._by_id[k] = nil
    end
    term._shell_name_seq.n = 0
    original_jobpid = vim.fn.jobpid
    vim.fn.jobpid = function()
      return 12345
    end
  end)

  after_each(function()
    vim.fn.jobpid = original_jobpid
  end)

  describe('job_alive', function()
    it('returns false for nil', function()
      assert.is_false(term.job_alive(nil))
    end)

    it('returns false for non-positive job_id', function()
      assert.is_false(term.job_alive(0))
      assert.is_false(term.job_alive(-1))
    end)

    it('returns true when jobpid returns non-zero', function()
      assert.is_true(term.job_alive(1))
    end)

    it('returns false when jobpid returns zero', function()
      vim.fn.jobpid = function()
        return 0
      end
      assert.is_false(term.job_alive(1))
    end)

    it('returns false when jobpid raises E900', function()
      vim.fn.jobpid = function()
        error('E900: Invalid channel id', 0)
      end
      assert.is_false(term.job_alive(1))
    end)
  end)

  describe('list', function()
    it('reports zero terminals when none are tracked', function()
      eq(term.list(), {})
    end)

    it('ignores entries whose buffer is invalid', function()
      term._by_id['shell-1'] = { buf = 999999, job_id = 1, cwd = '/tmp', name = 'x' }
      eq(term.list(), {})
    end)

    it('ignores entries whose job is no longer running', function()
      vim.fn.jobpid = function()
        return 0
      end
      local buf = vim.api.nvim_create_buf(false, true)
      term._by_id['shell-1'] = { buf = buf, job_id = 1, cwd = '/tmp', name = 'x' }
      eq(term.list(), {})
    end)

    it('ignores entries whose job id is no longer valid (E900)', function()
      vim.fn.jobpid = function()
        error('E900: Invalid channel id', 0)
      end
      local buf = vim.api.nvim_create_buf(false, true)
      term._by_id['shell-1'] = { buf = buf, job_id = 1, cwd = '/tmp', name = 'x' }
      eq(term.list(), {})
    end)

    it('returns entries sorted by buf id (creation order)', function()
      local buf_a = vim.api.nvim_create_buf(false, true)
      local buf_b = vim.api.nvim_create_buf(false, true)
      assert.is_true(buf_a < buf_b)
      term._by_id['/tmp/zzz.sh'] = { buf = buf_b, job_id = 1, cwd = '/tmp', name = 'zzz.sh', file = '/tmp/zzz.sh' }
      term._by_id['/tmp/aaa.sh'] = { buf = buf_a, job_id = 1, cwd = '/tmp', name = 'aaa.sh', file = '/tmp/aaa.sh' }

      local list = term.list()
      eq(#list, 2)
      eq(list[1].id, '/tmp/aaa.sh')
      eq(list[1].name, 'aaa.sh')
      eq(list[2].id, '/tmp/zzz.sh')
      eq(list[2].name, 'zzz.sh')
    end)

    it('marks the entry whose file is the current buffer as active', function()
      local tmp = vim.fn.tempname() .. '.sh'
      fresh_named_buffer(tmp, 'sh')
      local term_buf = vim.api.nvim_create_buf(false, true)
      term.register_run(tmp, term_buf, 1, '/tmp')
      local other = vim.api.nvim_create_buf(false, true)
      term._by_id['/tmp/other.sh'] = { buf = other, job_id = 1, cwd = '/tmp', name = 'other.sh', file = '/tmp/other.sh' }

      local list = term.list()
      local active = {}
      for _, item in ipairs(list) do
        if item.is_active then
          table.insert(active, item.id)
        end
      end
      eq(active, { tmp })
    end)
  end)

  describe('cycle', function()
    it('is a no-op when fewer than 2 terminals exist', function()
      local buf_a = vim.api.nvim_create_buf(false, true)
      term._by_id['/tmp/only.sh'] = { buf = buf_a, job_id = 1, cwd = '/tmp', name = 'only.sh', file = '/tmp/only.sh' }
      local before = vim.api.nvim_get_current_buf()
      term.cycle 'next'
      eq(vim.api.nvim_get_current_buf(), before)
    end)
  end)

  describe('_clear_for_buf', function()
    it('drops the matching entry', function()
      local buf_a = vim.api.nvim_create_buf(false, true)
      term._by_id['/tmp/wipe.sh'] = { buf = buf_a, job_id = 1, cwd = '/tmp', name = 'wipe.sh', file = '/tmp/wipe.sh' }
      term._clear_for_buf(buf_a)
      eq(term._by_id['/tmp/wipe.sh'], nil)
    end)
  end)

  describe('is_tracked_buf', function()
    it('is true for buffers in the registry', function()
      local buf = vim.api.nvim_create_buf(true, false)
      term._by_id['shell-1'] = { buf = buf, job_id = 1, cwd = '/tmp', name = 'T1' }
      assert.is_true(term.is_tracked_buf(buf))
      local other = vim.api.nvim_create_buf(true, false)
      assert.is_false(term.is_tracked_buf(other))
    end)
  end)

  describe('rename', function()
    it('updates name in list', function()
      local buf = vim.api.nvim_create_buf(false, true)
      term._by_id['shell-1'] = { buf = buf, job_id = 1, cwd = '/tmp', name = 'Old' }
      vim.api.nvim_set_current_buf(buf)
      term.rename 'New'
      local list = term.list()
      eq(#list, 1)
      eq(list[1].name, 'New')
    end)
  end)

  describe('next_shell_name', function()
    it('uses a monotonic counter independent of live terminal count', function()
      eq(term._next_shell_name(), 'Terminal 1')
      eq(term._next_shell_name(), 'Terminal 2')
      term._by_id['shell-99'] = {
        buf = vim.api.nvim_create_buf(false, true),
        job_id = 1,
        cwd = '/tmp',
        name = 'Terminal 1',
      }
      term._by_id['shell-99'] = nil
      eq(term._next_shell_name(), 'Terminal 3')
    end)
  end)

  describe('register_run', function()
    it('get returns usable entry by file id', function()
      local buf = vim.api.nvim_create_buf(false, true)
      term.register_run('/tmp/run.sh', buf, 1, '/tmp')
      local state = term.get('/tmp/run.sh')
      assert.is_not_nil(state)
      eq(state.buf, buf)
      eq(state.name, 'run.sh')
      eq(state.file, '/tmp/run.sh')
    end)
  end)
end)
