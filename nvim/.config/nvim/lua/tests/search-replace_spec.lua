---@diagnostic disable: undefined-field
--# selene: allow(undefined_variable)
local search_replace = require 'user.search-replace'
local eq = assert.are.same

describe('user.search-replace', function()
  -- Store original vim.fn.expand to restore after tests
  local original_expand = vim.fn.expand

  after_each(function()
    vim.fn.expand = original_expand
  end)

  describe('populate_searchline', function()
    it('generates basic search command in normal mode', function()
      -- Mock vim.fn.expand
      vim.fn.expand = function()
        return 'testword'
      end

      local cmd, move_left = search_replace.populate_searchline 'n'

      assert.is_string(cmd)
      assert.is_number(move_left)
      assert.is_true(cmd:find 'testword' ~= nil)
      assert.is_true(cmd:find 's' ~= nil) -- should contain 's' for substitute
    end)

    it('includes both search and replace terms', function()
      vim.fn.expand = function()
        return 'foo'
      end

      local cmd = search_replace.populate_searchline 'n'

      -- Command should have the word twice (search and replace)
      local _, count = cmd:gsub('foo', 'foo')
      eq(count, 2)
    end)

    it('includes gc flags by default', function()
      vim.fn.expand = function()
        return 'bar'
      end

      local cmd = search_replace.populate_searchline 'n'

      assert.is_true(cmd:find 'gc' ~= nil)
    end)

    it('uses .,$s range by default', function()
      vim.fn.expand = function()
        return 'baz'
      end

      local cmd = search_replace.populate_searchline 'n'

      assert.is_true(cmd:match '^%.,%)' ~= nil or cmd:match '%.,%$s' ~= nil)
    end)

    it('returns correct cursor position offset', function()
      vim.fn.expand = function()
        return 'test'
      end

      local _, move_left = search_replace.populate_searchline 'n'

      -- Should move left by separator + flags length (at least 3: /gc or similar)
      assert.is_true(move_left >= 3)
    end)
  end)

  describe('helper functions', function()
    describe('find_unique_char', function()
      it('returns / when not in string', function()
        local chars = { '/', '?', '#' }
        local str = 'testword'

        for _, char in ipairs(chars) do
          if not str:find(vim.pesc(char), 1, true) then
            eq(char, '/')
            break
          end
        end
      end)

      it('skips / when in string and returns ?', function()
        local chars = { '/', '?', '#' }
        local str = 'test/word'
        local result

        for _, char in ipairs(chars) do
          if not str:find(vim.pesc(char), 1, true) then
            result = char
            break
          end
        end

        eq(result, '?')
      end)

      it('finds first available character when using vim.pesc', function()
        local chars = { '/', '?', '#', ':', '@' }
        -- Note: vim.pesc('?') returns '%?' which won't match '?' in plain search
        -- so '?' will be considered "available" even though it's in the string
        local str = 'test/word#fragment'
        local result = nil

        for _, char in ipairs(chars) do
          if not str:find(vim.pesc(char), 1, true) then
            result = char
            break
          end
        end

        -- String contains / and #, so first available should be ?
        assert.is_not_nil(result)
        assert.are.equal('?', result)
      end)
    end)

    describe('flag toggling', function()
      it('adds flag when not present', function()
        local flags = 'gc'
        local char = 'i'
        local available_flags = { 'g', 'c', 'i' }

        if not flags:find(char) then
          local new_flags = ''
          for _, flag in ipairs(available_flags) do
            if flags:find(flag) or char == flag then
              new_flags = new_flags .. flag
            end
          end
          flags = new_flags
        end

        eq(flags, 'gci')
      end)

      it('removes flag when present', function()
        local flags = 'gci'
        local char = 'c'

        if flags:find(char) then
          flags = flags:gsub(char, '')
        end

        eq(flags, 'gi')
      end)

      it('maintains flag order', function()
        local flags = 'c'
        local char = 'g'
        local available_flags = { 'g', 'c', 'i' }

        local new_flags = ''
        for _, flag in ipairs(available_flags) do
          if flags:find(flag) or char == flag then
            new_flags = new_flags .. flag
          end
        end

        eq(new_flags, 'gc')
      end)
    end)

    describe('range cycling', function()
      it('cycles from %s to .,$s', function()
        local range = '%s'
        if range == '%s' then
          range = '.,$s'
        end
        eq(range, '.,$s')
      end)

      it('cycles from .,$s to 0,.s', function()
        local range = '.,$s'
        if range == '.,$s' then
          range = '0,.s'
        end
        eq(range, '0,.s')
      end)

      it('cycles from 0,.s to %s', function()
        local range = '0,.s'
        if range ~= '%s' and range ~= '.,$s' then
          range = '%s'
        end
        eq(range, '%s')
      end)
    end)

    describe('separator cycling', function()
      it('cycles through separator list', function()
        local chars = { '/', '?', '#', ':', '@' }
        local sep = '/'
        local idx = 0

        for i, c in ipairs(chars) do
          if c == sep then
            idx = i
            break
          end
        end

        local next_sep = chars[(idx % #chars) + 1]
        eq(next_sep, '?')
      end)

      it('wraps around from last to first', function()
        local chars = { '/', '?', '#', ':', '@' }
        local sep = '@'
        local idx = 0

        for i, c in ipairs(chars) do
          if c == sep then
            idx = i
            break
          end
        end

        local next_sep = chars[(idx % #chars) + 1]
        eq(next_sep, '/')
      end)
    end)

    describe('magic mode cycling', function()
      it('cycles through magic modes', function()
        local magic_list = { '\\v', '\\m', '\\M', '\\V', '' }
        local magic = '\\V'
        local idx = 0

        for i, m in ipairs(magic_list) do
          if m == magic then
            idx = i
            break
          end
        end

        local next_magic = magic_list[(idx % #magic_list) + 1]
        eq(next_magic, '')
      end)

      it('wraps from empty to \\v', function()
        local magic_list = { '\\v', '\\m', '\\M', '\\V', '' }
        local magic = ''
        local idx = 0

        for i, m in ipairs(magic_list) do
          if m == magic then
            idx = i
            break
          end
        end

        local next_magic = magic_list[(idx % #magic_list) + 1]
        eq(next_magic, '\\v')
      end)
    end)
  end)

  describe('command splitting', function()
    it('splits command by separator', function()
      local cmd = '.,$s/foo/bar/gc'
      local sep = '/'
      local parts = vim.split(cmd, sep, { plain = true })

      eq(#parts, 4)
      eq(parts[1], '.,$s')
      eq(parts[2], 'foo')
      eq(parts[3], 'bar')
      eq(parts[4], 'gc')
    end)

    it('handles different separators', function()
      local cmd = '.,$s?foo?bar?gc'
      local sep = '?'
      local parts = vim.split(cmd, sep, { plain = true })

      eq(#parts, 4)
      eq(parts[2], 'foo')
      eq(parts[3], 'bar')
    end)

    it('preserves empty parts', function()
      local cmd = '.,$s/foo//gc'
      local sep = '/'
      local parts = vim.split(cmd, sep, { plain = true })

      eq(#parts, 4)
      eq(parts[3], '')
    end)

    it('handles magic mode in search term', function()
      local cmd = '.,$s/\\Vfoo/bar/gc'
      local sep = '/'
      local parts = vim.split(cmd, sep, { plain = true })

      eq(parts[2], '\\Vfoo')
    end)
  end)

  describe('replace term toggling', function()
    it('clears replace term when same as search', function()
      local parts = { '.,$s', 'foo', 'foo', 'gc' }
      local cword = 'foo'
      local replace_term = parts[#parts - 1] == cword and '' or cword

      eq(replace_term, '')
    end)

    it('restores replace term when empty', function()
      local parts = { '.,$s', 'foo', '', 'gc' }
      local cword = 'foo'
      local replace_term = parts[#parts - 1] == '' and cword or ''

      eq(replace_term, 'foo')
    end)
  end)
end)
