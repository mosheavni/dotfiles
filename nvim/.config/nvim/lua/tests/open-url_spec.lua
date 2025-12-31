---@diagnostic disable: undefined-field
--# selene: allow(undefined_variable)
local open_url = require 'user.open-url'
local eq = assert.are.same

describe('user.open-url', function()
  describe('url_prefix', function()
    it('has default GitHub prefix', function()
      eq(open_url.url_prefix, 'https://github.com')
    end)

    it('can be changed', function()
      local original = open_url.url_prefix
      open_url.url_prefix = 'https://gitlab.com'
      eq(open_url.url_prefix, 'https://gitlab.com')
      open_url.url_prefix = original
    end)
  end)

  describe('remove_quotes', function()
    it('removes double quotes', function()
      local result = open_url.remove_quotes('"https://github.com/user/repo"')
      eq(result, 'https://github.com/user/repo')
    end)

    it('removes single quotes', function()
      local result = open_url.remove_quotes("'user/repo'")
      eq(result, 'user/repo')
    end)

    it('leaves unquoted strings unchanged', function()
      local result = open_url.remove_quotes('user/repo')
      eq(result, 'user/repo')
    end)

    it('handles empty string', function()
      local result = open_url.remove_quotes('')
      eq(result, '')
    end)
  end)

  describe('is_http_url', function()
    it('recognizes HTTPS URLs', function()
      assert.is_true(open_url.is_http_url('https://github.com/user/repo'))
    end)

    it('recognizes HTTP URLs', function()
      assert.is_true(open_url.is_http_url('http://example.com'))
    end)

    it('recognizes URLs with paths', function()
      assert.is_true(open_url.is_http_url('https://github.com/user/repo/blob/main/README.md'))
    end)

    it('rejects user/repo pattern', function()
      assert.is_false(open_url.is_http_url('user/repo'))
    end)

    it('rejects plain text', function()
      assert.is_false(open_url.is_http_url('just text'))
    end)
  end)

  describe('is_user_repo', function()
    it('recognizes user/repo pattern', function()
      assert.is_true(open_url.is_user_repo('user/repo'))
    end)

    it('recognizes user/repo with branch', function()
      assert.is_true(open_url.is_user_repo('user/repo@main'))
    end)

    it('recognizes user/repo.nvim', function()
      assert.is_true(open_url.is_user_repo('neovim/nvim-lspconfig'))
    end)

    it('recognizes https URLs (they contain /)', function()
      assert.is_true(open_url.is_user_repo('https://github.com/user/repo'))
    end)

    it('rejects single words', function()
      assert.is_false(open_url.is_user_repo('repo'))
    end)
  end)

  describe('parse_user_repo', function()
    it('returns repo and empty suffix for simple user/repo', function()
      local repo, suffix = open_url.parse_user_repo('user/repo')
      eq(repo, 'user/repo')
      eq(suffix, '')
    end)

    it('parses user/repo@branch correctly', function()
      local repo, suffix = open_url.parse_user_repo('user/repo@develop')
      eq(repo, 'user/repo')
      eq(suffix, '/tree/develop')
    end)

    it('parses user/repo@feature/test correctly', function()
      local repo, suffix = open_url.parse_user_repo('user/repo@feature/test')
      eq(repo, 'user/repo')
      eq(suffix, '/tree/feature/test')
    end)

    it('handles repo with dots', function()
      local repo, suffix = open_url.parse_user_repo('user/repo.nvim')
      eq(repo, 'user/repo.nvim')
      eq(suffix, '')
    end)

    it('handles repo with hyphens', function()
      local repo, suffix = open_url.parse_user_repo('user-name/repo-name')
      eq(repo, 'user-name/repo-name')
      eq(suffix, '')
    end)
  end)

  describe('build_github_url', function()
    it('builds URL without suffix', function()
      local url = open_url.build_github_url('user/repo')
      eq(url, 'https://github.com/user/repo')
    end)

    it('builds URL with suffix', function()
      local url = open_url.build_github_url('user/repo', '/tree/main')
      eq(url, 'https://github.com/user/repo/tree/main')
    end)

    it('respects custom url_prefix', function()
      local original = open_url.url_prefix
      open_url.url_prefix = 'https://gitlab.com'
      local url = open_url.build_github_url('user/repo')
      eq(url, 'https://gitlab.com/user/repo')
      open_url.url_prefix = original
    end)
  end)

  describe('extract_links_from_lines', function()
    it('extracts HTTPS URLs from lines', function()
      local lines = { 'Check out https://github.com/user/repo for more info' }
      local links = open_url.extract_links_from_lines(lines)
      eq(#links, 1)
      eq(links[1].line, 1)
      eq(links[1].link, 'https://github.com/user/repo')
    end)

    it('extracts multiple URLs from multiple lines', function()
      local lines = {
        'See https://github.com/a/b for details',
        'Also check http://example.com/path',
      }
      local links = open_url.extract_links_from_lines(lines)
      eq(#links, 2)
      eq(links[1].line, 1)
      eq(links[1].link, 'https://github.com/a/b')
      eq(links[2].line, 2)
      eq(links[2].link, 'http://example.com/path')
    end)

    it('handles URLs with underscores', function()
      local lines = { 'Link: https://example.com/my_path/file_name' }
      local links = open_url.extract_links_from_lines(lines)
      eq(#links, 1)
      eq(links[1].link, 'https://example.com/my_path/file_name')
    end)

    it('handles URLs with dots in path', function()
      local lines = { 'File: https://example.com/path/file.txt' }
      local links = open_url.extract_links_from_lines(lines)
      eq(#links, 1)
      eq(links[1].link, 'https://example.com/path/file.txt')
    end)

    it('handles empty lines', function()
      local lines = { '' }
      local links = open_url.extract_links_from_lines(lines)
      eq(#links, 0)
    end)

    it('handles lines with no URLs', function()
      local lines = { 'This is just plain text without any links' }
      local links = open_url.extract_links_from_lines(lines)
      eq(#links, 0)
    end)

    it('handles multiple URLs in a single line', function()
      local lines = { 'Check https://github.com/a/b and http://example.com/path' }
      local links = open_url.extract_links_from_lines(lines)
      eq(#links, 2)
      eq(links[1].link, 'https://github.com/a/b')
      eq(links[2].link, 'http://example.com/path')
    end)
  end)

  describe('process_url', function()
    it('returns HTTPS URLs unchanged', function()
      local url = open_url.process_url('https://github.com/user/repo')
      eq(url, 'https://github.com/user/repo')
    end)

    it('returns HTTP URLs unchanged', function()
      local url = open_url.process_url('http://example.com')
      eq(url, 'http://example.com')
    end)

    it('converts user/repo to GitHub URL', function()
      local url = open_url.process_url('user/repo')
      eq(url, 'https://github.com/user/repo')
    end)

    it('converts user/repo@branch to GitHub URL with tree path', function()
      local url = open_url.process_url('user/repo@main')
      eq(url, 'https://github.com/user/repo/tree/main')
    end)

    it('removes quotes from URLs', function()
      local url = open_url.process_url('"https://github.com/user/repo"')
      eq(url, 'https://github.com/user/repo')
    end)

    it('removes quotes from user/repo', function()
      local url = open_url.process_url("'user/repo'")
      eq(url, 'https://github.com/user/repo')
    end)

    it('returns nil for non-URL strings', function()
      local url = open_url.process_url('just-a-word')
      eq(url, nil)
    end)

    it('handles complex user/repo patterns', function()
      local url = open_url.process_url('neovim/nvim-lspconfig')
      eq(url, 'https://github.com/neovim/nvim-lspconfig')
    end)
  end)
end)
