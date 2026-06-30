---@diagnostic disable: undefined-field
--# selene: allow(undefined_variable)
local conflicts = require 'user.conflicts'
local eq = assert.are.same

local function diff3_block()
  return {
    '<<<<<<< HEAD',
    'A NestJS-based subscriptions service — master side of the conflict demo.',
    '||||||| 34b4957',
    'A NestJS-based subscriptions service.',
    '=======',
    'A NestJS-based subscriptions service — branch side of the conflict demo.',
    '>>>>>>> test/neovim-git-conflict',
  }
end

local function two_way_block()
  return {
    '<<<<<<< HEAD',
    'ours',
    '=======',
    'theirs',
    '>>>>>>> branch',
  }
end

describe('user.conflicts', function()
  describe('parse_unmerged_paths', function()
    it('parses git diff --diff-filter=U output with line prefix', function()
      local output = '/repo/a.lua\n/repo/b.lua\n'
      eq(conflicts.parse_unmerged_paths(output), {
        ['/repo/a.lua'] = true,
        ['/repo/b.lua'] = true,
      })
    end)
  end)

  describe('find_conflict_bounds', function()
    local lines = diff3_block()

    it('finds block from any line inside the conflict', function()
      for cursor = 1, #lines do
        eq({ conflicts.find_conflict_bounds(lines, cursor) }, { 1, 7 })
      end
    end)

    it('returns nil outside a conflict', function()
      local padded = vim.list_extend({ 'before' }, lines)
      vim.list_extend(padded, { 'after' })
      assert.is_nil(conflicts.find_conflict_bounds(padded, 1))
      assert.is_nil(conflicts.find_conflict_bounds(padded, #padded))
    end)
  end)

  describe('parse_conflict_block', function()
    it('splits diff3 conflict into head and origin only', function()
      local lines = diff3_block()
      local head, origin = conflicts.parse_conflict_block(lines, 1, #lines)
      eq(head, { 'A NestJS-based subscriptions service — master side of the conflict demo.' })
      eq(origin, { 'A NestJS-based subscriptions service — branch side of the conflict demo.' })
    end)

    it('splits two-way conflict into head and origin', function()
      local lines = two_way_block()
      local head, origin = conflicts.parse_conflict_block(lines, 1, #lines)
      eq(head, { 'ours' })
      eq(origin, { 'theirs' })
    end)
  end)

  describe('apply_conflict_resolution', function()
    local lines = diff3_block()
    local head = 'A NestJS-based subscriptions service — master side of the conflict demo.'
    local origin = 'A NestJS-based subscriptions service — branch side of the conflict demo.'

    it('take_head from any cursor line in the block', function()
      for cursor = 1, #lines do
        local result = conflicts.apply_conflict_resolution(lines, cursor, 'head')
        eq(result, { head })
      end
    end)

    it('take_origin from any cursor line in the block', function()
      for cursor = 1, #lines do
        local result = conflicts.apply_conflict_resolution(lines, cursor, 'origin')
        eq(result, { origin })
      end
    end)

    it('take_both preserves head then origin', function()
      local result = conflicts.apply_conflict_resolution(lines, 3, 'both')
      eq(result, { head, origin })
    end)

    it('preserves surrounding lines', function()
      local padded = vim.list_extend({ 'before' }, lines)
      vim.list_extend(padded, { 'after' })
      local result = conflicts.apply_conflict_resolution(padded, 4, 'head')
      eq(result, { 'before', head, 'after' })
    end)
  end)

  describe('build_highlights', function()
    it('colors diff3 sections with standard diff groups', function()
      local lines = diff3_block()
      eq(conflicts.build_highlights(lines), {
        { line = 1, hl = 'DiffText' },
        { line = 2, hl = 'DiffText' },
        { line = 3, hl = 'DiffChange' },
        { line = 4, hl = 'DiffChange' },
        { line = 5, hl = 'NonText' },
        { line = 6, hl = 'DiffAdd' },
        { line = 7, hl = 'DiffAdd' },
      })
    end)

    it('colors two-way conflicts', function()
      local lines = two_way_block()
      eq(conflicts.build_highlights(lines), {
        { line = 1, hl = 'DiffText' },
        { line = 2, hl = 'DiffText' },
        { line = 3, hl = 'NonText' },
        { line = 4, hl = 'DiffAdd' },
        { line = 5, hl = 'DiffAdd' },
      })
    end)

    it('returns empty list when there are no conflicts', function()
      eq(conflicts.build_highlights { 'plain text' }, {})
    end)
  end)
end)
