local lister = require 'user.lister'

local function qf_texts()
  return vim.tbl_map(function(item)
    return item.text
  end, vim.fn.getqflist())
end

describe('user.lister', function()
  before_each(function()
    lister.reset_history()
    vim.fn.setqflist {}
  end)

  describe('matches', function()
    it('matches text with =~# semantics', function()
      assert.is_true(lister.matches('hello world', 'world', false))
      assert.is_false(lister.matches('hello world', 'World', false))
    end)

    it('inverts with bang semantics', function()
      assert.is_true(lister.matches('hello world', 'foo', true))
      assert.is_false(lister.matches('hello world', 'world', true))
    end)
  end)

  describe('filter', function()
    it('Qgrep narrows quickfix by message', function()
      vim.fn.setqflist {
        { filename = '/a', lnum = 1, text = 'foo bar' },
        { filename = '/b', lnum = 2, text = 'baz qux' },
      }
      lister.filter('foo', 'text', false)
      assert.are.same({ 'foo bar' }, qf_texts())
    end)

    it('Qgrep! excludes matching messages', function()
      vim.fn.setqflist {
        { filename = '/a', lnum = 1, text = 'foo bar' },
        { filename = '/b', lnum = 2, text = 'baz qux' },
      }
      lister.filter('foo', 'text', true)
      assert.are.same({ 'baz qux' }, qf_texts())
    end)

    it('Qfilter narrows quickfix by filename via bufname', function()
      vim.fn.setqflist {
        { filename = '/proj/src/a.lua', lnum = 1, text = 'x' },
        { filename = '/proj/test/a_spec.lua', lnum = 2, text = 'y' },
      }
      lister.filter('_spec', 'file', false)
      assert.are.same({ 'y' }, qf_texts())
    end)

    it('Qgrep keeps lines where text contains vim.pack but path does not', function()
      vim.fn.setqflist {
        { filename = '/proj/lua/plugins/foo.lua', lnum = 1, text = 'vim.pack.add {' },
        { filename = '/proj/lua/other/bar.lua', lnum = 2, text = 'vim.cmd.colorscheme' },
      }
      lister.filter('vim.pack', 'file', false)
      assert.are.same({}, qf_texts())
      vim.fn.setqflist {
        { filename = '/proj/lua/plugins/foo.lua', lnum = 1, text = 'vim.pack.add {' },
        { filename = '/proj/lua/other/bar.lua', lnum = 2, text = 'vim.cmd.colorscheme' },
      }
      lister.filter('vim.pack', 'text', false)
      assert.are.same({ 'vim.pack.add {' }, qf_texts())
    end)
  end)

  describe('history', function()
    it('undo restores quickfix state before the last filter', function()
      vim.fn.setqflist {
        { filename = '/a', lnum = 1, text = 'foo bar' },
        { filename = '/b', lnum = 2, text = 'baz qux' },
      }
      lister.filter('foo', 'text', false)
      assert.are.same({ 'foo bar' }, qf_texts())
      lister.undo()
      assert.are.same({ 'foo bar', 'baz qux' }, qf_texts())
    end)

    it('redo restores quickfix state after undo', function()
      vim.fn.setqflist {
        { filename = '/a', lnum = 1, text = 'foo bar' },
        { filename = '/b', lnum = 2, text = 'baz qux' },
      }
      lister.filter('foo', 'text', false)
      lister.undo()
      lister.redo()
      assert.are.same({ 'foo bar' }, qf_texts())
    end)

    it('new filter after undo drops redo branch', function()
      vim.fn.setqflist {
        { filename = '/a', lnum = 1, text = 'foo bar' },
        { filename = '/b', lnum = 2, text = 'baz qux' },
        { filename = '/c', lnum = 3, text = 'foo baz' },
      }
      lister.filter('foo', 'text', false)
      lister.filter('bar', 'text', false)
      assert.are.same({ 'foo bar' }, qf_texts())
      lister.undo()
      assert.are.same({ 'foo bar', 'foo baz' }, qf_texts())
      lister.filter('baz', 'text', false)
      assert.are.same({ 'foo baz' }, qf_texts())
      assert.is_false(lister.redo())
      assert.are.same({ 'foo baz' }, qf_texts())
    end)
  end)
end)
