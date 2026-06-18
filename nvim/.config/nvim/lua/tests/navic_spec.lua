---@diagnostic disable: undefined-field, need-check-nil
--# selene: allow(undefined_variable)
local navic = require 'user.navic'
local eq = assert.are.same

local function sym(name, kind, sl, sc, el, ec, children)
  return {
    name = name,
    kind = kind,
    range = {
      start = { line = sl, character = sc },
      ['end'] = { line = el, character = ec },
    },
    children = children or {},
  }
end

describe('user.navic', function()
  describe('_render_part', function()
    it('renders function symbol with icon and name', function()
      local s = sym('myFunc', 12, 0, 0, 5, 0)
      local rendered = navic._render_part(s)
      assert.is_truthy(rendered:find('myFunc', 1, true))
      assert.is_truthy(rendered:find('NavicIconsFunction', 1, true))
      assert.is_truthy(rendered:find('NavicText', 1, true))
    end)

    it('renders class symbol with Class highlight group', function()
      local s = sym('MyClass', 5, 0, 0, 20, 0)
      local rendered = navic._render_part(s)
      assert.is_truthy(rendered:find('NavicIconsClass', 1, true))
      assert.is_truthy(rendered:find('MyClass', 1, true))
    end)

    it('falls back to Text for unknown kind', function()
      local s = sym('unknown', 99, 0, 0, 5, 0)
      local rendered = navic._render_part(s)
      assert.is_truthy(rendered:find('NavicIconsText', 1, true))
      assert.is_truthy(rendered:find('unknown', 1, true))
    end)
  end)

  describe('_find_in_symbols', function()
    it('returns empty table when no symbols', function()
      eq({}, navic._find_in_symbols({}, 3, 0))
    end)

    it('returns empty when cursor outside all ranges', function()
      local symbols = { sym('myFunc', 12, 0, 0, 5, 0) }
      eq({}, navic._find_in_symbols(symbols, 10, 0))
    end)

    it('finds symbol containing cursor', function()
      local symbols = { sym('myFunc', 12, 0, 0, 5, 0) }
      local result = navic._find_in_symbols(symbols, 3, 0)
      eq(1, #result)
      assert.is_truthy(result[1]:find('myFunc', 1, true))
    end)

    it('finds nested child over parent', function()
      local child = sym('innerMethod', 6, 2, 2, 4, 3)
      local parent = sym('MyClass', 5, 0, 0, 10, 0, { child })
      local symbols = { parent }

      local result = navic._find_in_symbols(symbols, 3, 5)
      eq(2, #result)
      assert.is_truthy(result[1]:find('MyClass', 1, true))
      assert.is_truthy(result[2]:find('innerMethod', 1, true))
    end)

    it('returns only parent when cursor not inside child', function()
      local child = sym('innerMethod', 6, 5, 0, 8, 0)
      local parent = sym('MyClass', 5, 0, 0, 10, 0, { child })
      local symbols = { parent }

      local result = navic._find_in_symbols(symbols, 2, 0)
      eq(1, #result)
      assert.is_truthy(result[1]:find('MyClass', 1, true))
    end)

    it('picks correct sibling when multiple top-level symbols', function()
      local fn1 = sym('funcA', 12, 0, 0, 3, 0)
      local fn2 = sym('funcB', 12, 5, 0, 8, 0)
      local symbols = { fn1, fn2 }

      local r1 = navic._find_in_symbols(symbols, 1, 0)
      local r2 = navic._find_in_symbols(symbols, 6, 0)

      assert.is_truthy(r1[1]:find('funcA', 1, true))
      assert.is_truthy(r2[1]:find('funcB', 1, true))
    end)

    it('handles cursor on exact start line of range', function()
      local symbols = { sym('myFunc', 12, 3, 0, 6, 0) }
      local result = navic._find_in_symbols(symbols, 3, 0)
      eq(1, #result)
      assert.is_truthy(result[1]:find('myFunc', 1, true))
    end)

    it('handles cursor on exact end line of range', function()
      local symbols = { sym('myFunc', 12, 3, 0, 6, 0) }
      local result = navic._find_in_symbols(symbols, 6, 0)
      eq(1, #result)
      assert.is_truthy(result[1]:find('myFunc', 1, true))
    end)

    it('handles three levels of nesting', function()
      local inner = sym('loop', 12, 4, 4, 6, 4)
      local method = sym('doWork', 6, 2, 2, 8, 2, { inner })
      local class = sym('Worker', 5, 0, 0, 10, 0, { method })
      local symbols = { class }

      local result = navic._find_in_symbols(symbols, 5, 6)
      eq(3, #result)
      assert.is_truthy(result[1]:find('Worker', 1, true))
      assert.is_truthy(result[2]:find('doWork', 1, true))
      assert.is_truthy(result[3]:find('loop', 1, true))
    end)
  end)
end)
