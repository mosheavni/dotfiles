---@diagnostic disable: undefined-field
--# selene: allow(undefined_variable)
local sc = require 'user.search-count'

describe('user.search-count', function()
  local buf

  before_each(function()
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'hello world hello', 'foo bar', 'hello again' })
    vim.o.hlsearch = true
  end)

  after_each(function()
    sc.clear()
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  local function extmarks()
    return vim.api.nvim_buf_get_extmarks(buf, sc.ns, 0, -1, { details = true })
  end

  describe('update', function()
    it('places no extmark when cursor is not on a match', function()
      vim.fn.setreg('/', 'hello')
      vim.api.nvim_win_set_cursor(0, { 2, 0 }) -- 'foo bar' line
      sc.update()
      assert.are.same({}, extmarks())
    end)

    it('places extmark with X/Y format when on a match', function()
      vim.fn.setreg('/', 'hello')
      vim.api.nvim_win_set_cursor(0, { 1, 0 }) -- cursor at first 'hello'
      sc.update()
      local marks = extmarks()
      assert.is_true(#marks == 1)
      local virt_text = marks[1][4].virt_text[1][1]
      assert.is_truthy(virt_text:match '^%s%d+/%d+$')
    end)

    it('places extmark on the correct line', function()
      vim.fn.setreg('/', 'hello')
      vim.api.nvim_win_set_cursor(0, { 3, 0 }) -- 'hello again' line
      sc.update()
      local marks = extmarks()
      assert.is_true(#marks == 1)
      assert.are.same(2, marks[1][2]) -- 0-indexed row 2 = line 3
    end)

    it('clears previous extmark before placing a new one', function()
      vim.fn.setreg('/', 'hello')
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      sc.update()
      sc.update()
      assert.are.same(1, #extmarks())
    end)

    it('places no extmark when total is 0', function()
      vim.fn.setreg('/', 'zzznomatch')
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      sc.update()
      assert.are.same({}, extmarks())
    end)
  end)

  describe('clear', function()
    it('removes all extmarks', function()
      vim.fn.setreg('/', 'hello')
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      sc.update()
      assert.is_true(#extmarks() > 0)
      sc.clear()
      assert.are.same({}, extmarks())
    end)
  end)
end)
