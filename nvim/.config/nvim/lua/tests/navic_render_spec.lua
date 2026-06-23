---@diagnostic disable: undefined-field, need-check-nil
--# selene: allow(undefined_variable)
local core = require 'user.navic_core'
local helpers = require 'tests.navic_helpers'
local eq = assert.are.same

describe('user.navic_core.render_part', function()
  it('renders function symbol with icon and name', function()
    local s = helpers.sym('myFunc', 12, 0, 0, 5, 0)
    local rendered = core.render_part(s)
    assert.is_truthy(rendered:find('myFunc', 1, true))
    assert.is_truthy(rendered:find('NavicIconsFunction', 1, true))
    assert.is_truthy(rendered:find('NavicText', 1, true))
  end)

  it('renders class symbol with Class highlight group', function()
    local s = helpers.sym('MyClass', 5, 0, 0, 20, 0)
    local rendered = core.render_part(s)
    assert.is_truthy(rendered:find('NavicIconsClass', 1, true))
    assert.is_truthy(rendered:find('MyClass', 1, true))
  end)

  it('falls back to Text for unknown kind', function()
    local s = helpers.sym('unknown', 99, 0, 0, 5, 0)
    local rendered = core.render_part(s)
    assert.is_truthy(rendered:find('NavicIconsText', 1, true))
    assert.is_truthy(rendered:find('unknown', 1, true))
  end)

  it('escapes percent signs in symbol names', function()
    local s = helpers.sym('foo%bar', 12, 0, 0, 5, 0)
    local rendered = core.render_part(s)
    assert.is_truthy(rendered:find('foo%%bar', 1, true))
    assert.is_falsy(rendered:find('foo%bar', 1, true))
  end)
end)

describe('user.navic_core.safe_name', function()
  it('escapes percent signs', function()
    eq('foo%%bar', core.safe_name 'foo%bar')
  end)

  it('replaces newlines with spaces', function()
    eq('foo bar', core.safe_name 'foo\nbar')
  end)
end)
