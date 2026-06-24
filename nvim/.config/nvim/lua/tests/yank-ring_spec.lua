local notify_stub = require 'tests.notify_stub'
local ring = require 'user.yank-ring'
local eq = assert.are.same

local function buf_lines()
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

describe('user.yank-ring', function()
  before_each(function()
    ring.setup()
    vim.cmd 'enew!'
    for i = 0, 9 do
      vim.fn.setreg(tostring(i), '')
    end
    vim.fn.setreg('"', '')
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'aaa', 'bbb', 'ccc' })
  end)

  describe('ring registers', function()
    it('shifts yank history into registers 1-9', function()
      vim.cmd 'normal! ggyy'
      vim.cmd 'normal! jyy'
      vim.cmd 'normal! jyy'
      eq('ccc\n', vim.fn.getreg '1')
      eq('bbb\n', vim.fn.getreg '2')
      eq('aaa\n', vim.fn.getreg '3')
    end)

    it('does not shift on explicit-register yanks', function()
      vim.cmd 'normal! ggyy'
      vim.cmd 'normal! j"ayy'
      eq('aaa\n', vim.fn.getreg '1')
      eq('', vim.fn.getreg '2')
    end)

    it('does not double-shift on deletes (vim shifts those natively)', function()
      vim.cmd 'normal! ggyy'
      vim.cmd 'normal! jdd'
      -- vim itself moves linewise deletes into reg 1 (:h quote_number);
      -- the module must not shift again on top of that
      eq('bbb\n', vim.fn.getreg '1')
      eq('aaa\n', vim.fn.getreg '2')
      eq('', vim.fn.getreg '3')
    end)
  end)

  describe('cycle', function()
    before_each(function()
      vim.cmd 'normal! ggyy'
      vim.cmd 'normal! jyy'
      vim.cmd 'normal! jyy'
      vim.cmd 'normal! Gp'
    end)

    it('replaces last put with older yank', function()
      eq({ 'aaa', 'bbb', 'ccc', 'ccc' }, buf_lines())
      ring.cycle(1)
      eq({ 'aaa', 'bbb', 'ccc', 'bbb' }, buf_lines())
      ring.cycle(1)
      eq({ 'aaa', 'bbb', 'ccc', 'aaa' }, buf_lines())
    end)

    it('cycles back to newer yank', function()
      ring.cycle(1)
      ring.cycle(1)
      ring.cycle(-1)
      eq({ 'aaa', 'bbb', 'ccc', 'bbb' }, buf_lines())
    end)

    it('does not touch ring registers while cycling', function()
      ring.cycle(1)
      eq('ccc\n', vim.fn.getreg '1')
      eq('bbb\n', vim.fn.getreg '2')
      eq('aaa\n', vim.fn.getreg '3')
    end)

    it('syncs unnamed register to the shown entry', function()
      ring.cycle(1)
      eq('bbb\n', vim.fn.getreg '"')
    end)

    it('stops at the oldest yank and notifies', function()
      notify_stub.with(function(messages)
        ring.cycle(1)
        ring.cycle(1)
        ring.cycle(1) -- past the oldest entry
        eq({ 'aaa', 'bbb', 'ccc', 'aaa' }, buf_lines())
        eq('No older yanks', messages[1].msg)
      end)
    end)

    it('stops at the newest yank and notifies', function()
      notify_stub.with(function(messages)
        ring.cycle(-1) -- already at the newest entry
        eq({ 'aaa', 'bbb', 'ccc', 'ccc' }, buf_lines())
        eq('No newer yanks', messages[1].msg)
      end)
    end)

    it('is a no-op after the buffer changed', function()
      vim.api.nvim_buf_set_lines(0, 0, 1, false, { 'zzz' })
      local before = buf_lines()
      ring.cycle(1)
      eq(before, buf_lines())
    end)

    it('is a no-op without a tracked put', function()
      vim.cmd 'enew!'
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'xxx' })
      ring.cycle(1)
      eq({ 'xxx' }, buf_lines())
    end)

    it('handles charwise puts', function()
      vim.cmd 'normal! gg0yiw'
      vim.cmd 'normal! j0yiw'
      vim.cmd 'normal! Go'
      vim.cmd 'normal! 0"0p'
      ring.cycle(1)
      local lines = buf_lines()
      eq('aaa', lines[#lines])
    end)
  end)
end)
