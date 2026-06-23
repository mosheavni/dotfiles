---@diagnostic disable: undefined-field, need-check-nil
--# selene: allow(undefined_variable)
local core = require 'user.navic_core'
local helpers = require 'tests.navic_helpers'
local eq = assert.are.same

describe('user.navic_core.find_in_symbols', function()
  it('returns empty table when no symbols', function()
    eq({}, core.find_in_symbols({}, 3, 0))
  end)

  it('returns empty when cursor outside all ranges', function()
    local symbols = { helpers.sym('myFunc', 12, 0, 0, 5, 0) }
    eq({}, core.find_in_symbols(symbols, 10, 0))
  end)

  it('finds symbol containing cursor', function()
    local symbols = { helpers.sym('myFunc', 12, 0, 0, 5, 0) }
    local result = core.find_in_symbols(symbols, 3, 0)
    eq(1, #result)
    assert.is_truthy(result[1]:find('myFunc', 1, true))
  end)

  it('finds nested child over parent', function()
    local child = helpers.sym('innerMethod', 6, 2, 2, 4, 3)
    local parent = helpers.sym('MyClass', 5, 0, 0, 10, 0, { child })
    local symbols = { parent }

    local result = core.find_in_symbols(symbols, 3, 5)
    eq(2, #result)
    assert.is_truthy(result[1]:find('MyClass', 1, true))
    assert.is_truthy(result[2]:find('innerMethod', 1, true))
  end)

  it('returns only parent when cursor not inside child', function()
    local child = helpers.sym('innerMethod', 6, 5, 0, 8, 0)
    local parent = helpers.sym('MyClass', 5, 0, 0, 10, 0, { child })
    local symbols = { parent }

    local result = core.find_in_symbols(symbols, 2, 0)
    eq(1, #result)
    assert.is_truthy(result[1]:find('MyClass', 1, true))
  end)

  it('picks correct sibling when multiple top-level symbols', function()
    local fn1 = helpers.sym('funcA', 12, 0, 0, 3, 0)
    local fn2 = helpers.sym('funcB', 12, 5, 0, 8, 0)
    local symbols = { fn1, fn2 }

    local r1 = core.find_in_symbols(symbols, 1, 0)
    local r2 = core.find_in_symbols(symbols, 6, 0)

    assert.is_truthy(r1[1]:find('funcA', 1, true))
    assert.is_truthy(r2[1]:find('funcB', 1, true))
  end)

  it('handles cursor on exact start line of range', function()
    local symbols = { helpers.sym('myFunc', 12, 3, 0, 6, 0) }
    local result = core.find_in_symbols(symbols, 3, 0)
    eq(1, #result)
    assert.is_truthy(result[1]:find('myFunc', 1, true))
  end)

  it('handles cursor on exact end line of range', function()
    local symbols = { helpers.sym('myFunc', 12, 3, 0, 6, 0) }
    local result = core.find_in_symbols(symbols, 6, 0)
    eq(1, #result)
    assert.is_truthy(result[1]:find('myFunc', 1, true))
  end)

  it('handles three levels of nesting', function()
    local inner = helpers.sym('loop', 12, 4, 4, 6, 4)
    local method = helpers.sym('doWork', 6, 2, 2, 8, 2, { inner })
    local class = helpers.sym('Worker', 5, 0, 0, 10, 0, { method })
    local symbols = { class }

    local result = core.find_in_symbols(symbols, 5, 6)
    eq(3, #result)
    assert.is_truthy(result[1]:find('Worker', 1, true))
    assert.is_truthy(result[2]:find('doWork', 1, true))
    assert.is_truthy(result[3]:find('loop', 1, true))
  end)
end)
