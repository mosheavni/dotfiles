---@diagnostic disable: undefined-field, need-check-nil
local input = require 'user.input'
local eq = assert.are.same

describe('user.input', function()
  describe('is_active', function()
    it('is false when no session is open', function()
      assert.is_false(input.is_active())
    end)
  end)

  describe('end_cursor_col', function()
    it('returns 0 for empty string', function()
      eq(input.end_cursor_col '', 0)
    end)

    it('returns byte length for ASCII', function()
      eq(input.end_cursor_col 'hello', 5)
    end)

    it('handles multibyte characters', function()
      local col = input.end_cursor_col 'café'
      assert.is_true(col >= 4)
      assert.is_true(col < 6)
    end)
  end)

  describe('completion_base', function()
    it('uses fname tail for dir completion', function()
      local text = '/tmp/fo'
      local base, start = input.completion_base(text, 'dir')
      assert.is_true(#base > 0)
      eq(vim.fn.strpart(text, start), base)
    end)

    it('returns empty base at end for empty text', function()
      local base, start = input.completion_base('', 'dir')
      eq(base, '')
      eq(start, 0)
    end)

    it('uses keyword tail for non-fs completion', function()
      local text = 'foo_bar'
      local base = input.completion_base(text, 'tag')
      assert.is_true(#base > 0)
      assert.is_true(vim.endswith(text, base))
    end)
  end)

  describe('format_completion_footer', function()
    it('formats id and total', function()
      eq(input.format_completion_footer(2, 5), ' 2/5 ')
    end)

    it('returns empty string when total is zero', function()
      eq(input.format_completion_footer(0, 0), '')
    end)
  end)

  describe('compute_float_width', function()
    it('uses minimum width for short text', function()
      eq(input.compute_float_width('hi', 60, 120), 60)
    end)

    it('expands for long display text', function()
      local width = input.compute_float_width(string.rep('w', 80), 60, 120)
      assert.is_true(width > 60)
    end)

    it('clamps to max columns', function()
      eq(input.compute_float_width(string.rep('w', 200), 60, 80), 78)
    end)
  end)
end)
