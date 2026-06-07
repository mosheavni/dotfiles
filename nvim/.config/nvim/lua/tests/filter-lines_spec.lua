---@diagnostic disable: undefined-field
--# selene: allow(undefined_variable)
local filter_lines = require 'user.filter-lines'
local eq = assert.are.same

describe('user.filter-lines', function()
  local sample = {
    'foo bar',
    'baz qux',
    'foo again',
    'nothing here',
  }

  describe('select_lines', function()
    it('keeps only matching lines (delete all but)', function()
      eq(filter_lines.select_lines(sample, 'foo', true), { 'foo bar', 'foo again' })
    end)

    it('removes matching lines (delete all)', function()
      eq(filter_lines.select_lines(sample, 'foo', false), { 'baz qux', 'nothing here' })
    end)

    it('returns empty when nothing matches and keeping matches', function()
      eq(filter_lines.select_lines(sample, 'missing', true), {})
    end)

    it('returns all lines when nothing matches and removing matches', function()
      eq(filter_lines.select_lines(sample, 'missing', false), sample)
    end)
  end)

  describe('line_matches', function()
    it('treats pattern as literal (very nomagic)', function()
      assert.is_true(filter_lines.line_matches('foo.bar', 'line foo.bar end'))
      assert.is_false(filter_lines.line_matches('foo.bar', 'line fooXbar end'))
    end)
  end)
end)
