---@diagnostic disable: undefined-field, need-check-nil
--# selene: allow(undefined_variable)
local present = require 'user.present'
local eq = assert.are.same

describe('user.present', function()
  local test_dir = '/tmp/nvim_present_test'

  before_each(function()
    vim.fn.mkdir(test_dir, 'p')
    -- Reset state
    present.state.active = false
    present.state.slides = {}
    present.state.current = 1
  end)

  after_each(function()
    vim.fn.delete(test_dir, 'rf')
  end)

  describe('discover_slides', function()
    it('finds and sorts markdown files', function()
      vim.fn.writefile({ '# Slide 1' }, test_dir .. '/01.md')
      vim.fn.writefile({ '# Slide 2' }, test_dir .. '/02.md')
      vim.fn.writefile({ '# Slide 10' }, test_dir .. '/10.md')

      local slides = present._discover_slides(test_dir)

      eq(3, #slides)
      assert.is_true(slides[1]:match '01.md$' ~= nil)
      assert.is_true(slides[2]:match '02.md$' ~= nil)
      assert.is_true(slides[3]:match '10.md$' ~= nil)
    end)

    it('returns empty list for empty directory', function()
      local slides = present._discover_slides(test_dir)
      eq(0, #slides)
    end)

    it('ignores non-markdown files', function()
      vim.fn.writefile({ '# Slide 1' }, test_dir .. '/01.md')
      vim.fn.writefile({ 'text' }, test_dir .. '/notes.txt')
      vim.fn.writefile({ 'code' }, test_dir .. '/script.lua')

      local slides = present._discover_slides(test_dir)

      eq(1, #slides)
      assert.is_true(slides[1]:match '01.md$' ~= nil)
    end)
  end)

  describe('navigation', function()
    before_each(function()
      present.state.slides = { '/tmp/1.md', '/tmp/2.md', '/tmp/3.md' }
      present.state.current = 1
      present.state.active = true
    end)

    it('next() advances to next slide', function()
      -- Mock show_slide to avoid UI operations
      local original = present.show_slide
      present.show_slide = function() end

      present.next()
      eq(2, present.state.current)

      present.show_slide = original
    end)

    it('next() wraps from last to first', function()
      present.state.current = 3
      local original = present.show_slide
      present.show_slide = function() end

      present.next()
      eq(1, present.state.current)

      present.show_slide = original
    end)

    it('prev() goes to previous slide', function()
      present.state.current = 2
      local original = present.show_slide
      present.show_slide = function() end

      present.prev()
      eq(1, present.state.current)

      present.show_slide = original
    end)

    it('prev() wraps from first to last', function()
      present.state.current = 1
      local original = present.show_slide
      present.show_slide = function() end

      present.prev()
      eq(3, present.state.current)

      present.show_slide = original
    end)

    it('navigates through all slides in sequence', function()
      local original = present.show_slide
      present.show_slide = function() end

      -- Start at 1, go through all slides
      eq(1, present.state.current)
      present.next()
      eq(2, present.state.current)
      present.next()
      eq(3, present.state.current)
      present.next()
      eq(1, present.state.current) -- wrapped

      present.show_slide = original
    end)
  end)
end)
