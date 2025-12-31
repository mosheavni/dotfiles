---@diagnostic disable: undefined-field
--# selene: allow(undefined_variable)
local Hints = require 'user.hints'

describe('user.hints', function()
  describe('new', function()
    it('creates a hints instance', function()
      local hints = Hints.new('Test Title', {
        { key = 'a', desc = 'Action A' },
        { key = 'b', desc = 'Action B' },
      })

      assert.is_table(hints)
      assert.is_function(hints.show)
      assert.is_function(hints.close)
      assert.is_function(hints.toggle)
    end)

    it('handles empty hints config', function()
      local hints = Hints.new('Empty', {})

      assert.is_table(hints)
      assert.is_function(hints.show)
    end)

    it('handles single hint', function()
      local hints = Hints.new('Single', {
        { key = 'x', desc = 'Single action' },
      })

      assert.is_table(hints)
      assert.is_function(hints.show)
    end)

    it('handles hints with varying key lengths', function()
      local hints = Hints.new('Variable Keys', {
        { key = 'a', desc = 'Short' },
        { key = 'abc', desc = 'Medium' },
        { key = 'abcdef', desc = 'Long' },
      })

      assert.is_table(hints)
      assert.is_function(hints.show)
    end)

    it('handles hints with special characters in descriptions', function()
      local hints = Hints.new('Special Chars', {
        { key = 'a', desc = 'Action with → arrow' },
        { key = 'b', desc = 'Action with / slash' },
        { key = 'c', desc = 'Action with "quotes"' },
      })

      assert.is_table(hints)
    end)

    it('handles long descriptions', function()
      local hints = Hints.new('Long Descriptions', {
        { key = 'a', desc = 'This is a very long description that might wrap or extend beyond normal bounds' },
      })

      assert.is_table(hints)
    end)

    it('handles multiple hints with same key length', function()
      local hints = Hints.new('Same Length', {
        { key = 'aa', desc = 'First' },
        { key = 'bb', desc = 'Second' },
        { key = 'cc', desc = 'Third' },
      })

      assert.is_table(hints)
    end)

    it('handles hints with unicode characters', function()
      local hints = Hints.new('Unicode', {
        { key = '🔥', desc = 'Fire action' },
        { key = '✓', desc = 'Check action' },
      })

      assert.is_table(hints)
    end)
  end)
end)
