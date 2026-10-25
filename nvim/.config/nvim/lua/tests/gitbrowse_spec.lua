---@diagnostic disable: undefined-field, invisible
--# selene: allow(undefined_variable)
local gitbrowse = require 'user.gitbrowse'
local eq = assert.are.same

describe('user.gitbrowse', function()
  describe('get_repo', function()
    it('handles HTTPS URLs with .git extension', function()
      local url = gitbrowse.get_repo 'https://github.com/user/repo.git'
      eq(url, 'https://github.com/user/repo')
    end)

    it('handles HTTPS URLs without .git extension', function()
      local url = gitbrowse.get_repo 'https://github.com/user/repo'
      eq(url, 'https://github.com/user/repo')
    end)

    it('converts SSH git@ URLs to HTTPS', function()
      local url = gitbrowse.get_repo 'git@github.com:user/repo.git'
      eq(url, 'https://github.com/user/repo')
    end)

    it('converts SSH git@ URLs without .git', function()
      local url = gitbrowse.get_repo 'git@github.com:user/repo'
      eq(url, 'https://github.com/user/repo')
    end)

    it('handles ssh:// protocol', function()
      local url = gitbrowse.get_repo 'ssh://git@github.com/user/repo'
      eq(url, 'https://github.com/user/repo')
    end)

    it('handles ssh:// with port', function()
      local url = gitbrowse.get_repo 'ssh://git@gitlab.com:2222/user/repo.git'
      eq(url, 'https://gitlab.com/user/repo')
    end)

    it('handles Azure DevOps SSH URLs', function()
      local url = gitbrowse.get_repo 'ssh.dev.azure.com/v3/org/project/repo'
      eq('https://dev.azure.com/org/project/_git/repo', url)
    end)

    it('handles HTTPS with username', function()
      local url = gitbrowse.get_repo 'https://username@github.com/user/repo.git'
      eq(url, 'https://github.com/user/repo')
    end)

    it('handles GitLab URLs', function()
      local url = gitbrowse.get_repo 'git@gitlab.com:user/repo.git'
      eq(url, 'https://gitlab.com/user/repo')
    end)

    it('handles Bitbucket URLs', function()
      local url = gitbrowse.get_repo 'git@bitbucket.org:user/repo.git'
      eq(url, 'https://bitbucket.org/user/repo')
    end)
  end)

  describe('get_url', function()
    it('builds GitHub file URL', function()
      local repo = 'https://github.com/user/repo'
      local fields = {
        branch = 'main',
        file = 'src/test.lua',
        line_start = 10,
        line_end = 20,
      }
      local url = gitbrowse.get_url(repo, fields)
      eq(url, 'https://github.com/user/repo/blob/main/src/test.lua#L10-L20')
    end)

    it('builds GitHub branch URL', function()
      local repo = 'https://github.com/user/repo'
      local fields = { branch = 'develop' }
      local url = gitbrowse.get_url(repo, fields, { what = 'branch' })
      eq(url, 'https://github.com/user/repo/tree/develop')
    end)

    it('builds GitHub commit URL', function()
      local repo = 'https://github.com/user/repo'
      local fields = { commit = 'abc123def456' }
      local url = gitbrowse.get_url(repo, fields, { what = 'commit' })
      eq(url, 'https://github.com/user/repo/commit/abc123def456')
    end)

    it('builds GitLab file URL', function()
      local repo = 'https://gitlab.com/user/repo'
      local fields = {
        branch = 'main',
        file = 'src/test.lua',
        line_start = 5,
        line_end = 15,
      }
      local url = gitbrowse.get_url(repo, fields)
      eq(url, 'https://gitlab.com/user/repo/-/blob/main/src/test.lua#L5-L15')
    end)

    it('builds GitLab branch URL', function()
      local repo = 'https://gitlab.com/user/repo'
      local fields = { branch = 'feature/test' }
      local url = gitbrowse.get_url(repo, fields, { what = 'branch' })
      eq(url, 'https://gitlab.com/user/repo/-/tree/feature/test')
    end)

    it('builds Bitbucket file URL', function()
      local repo = 'https://bitbucket.org/user/repo'
      local fields = {
        branch = 'main',
        file = 'src/test.lua',
        line_start = 1,
        line_end = 10,
      }
      local url = gitbrowse.get_url(repo, fields)
      eq(url, 'https://bitbucket.org/user/repo/src/main/src/test.lua#lines-1-L10')
    end)

    it('returns repo URL for unknown remote', function()
      local repo = 'https://unknown.com/user/repo'
      local fields = { branch = 'main' }
      local url = gitbrowse.get_url(repo, fields)
      eq(url, 'https://unknown.com/user/repo')
    end)

    it('handles single line selection', function()
      local repo = 'https://github.com/user/repo'
      local fields = {
        branch = 'main',
        file = 'test.lua',
        line_start = 42,
        line_end = 42,
      }
      local url = gitbrowse.get_url(repo, fields)
      eq(url, 'https://github.com/user/repo/blob/main/test.lua#L42-L42')
    end)

    it('builds GitHub file URL without line anchor when no line is set', function()
      local repo = 'https://github.com/user/repo'
      local fields = {
        branch = 'main',
        file = 'src/test.lua',
      }
      local url = gitbrowse.get_url(repo, fields)
      eq(url, 'https://github.com/user/repo/blob/main/src/test.lua')
    end)

    it('builds GitLab file URL without line anchor when no line is set', function()
      local repo = 'https://gitlab.com/user/repo'
      local fields = {
        branch = 'main',
        file = 'src/test.lua',
      }
      local url = gitbrowse.get_url(repo, fields)
      eq(url, 'https://gitlab.com/user/repo/-/blob/main/src/test.lua')
    end)

    it('builds Bitbucket file URL without line anchor when no line is set', function()
      local repo = 'https://bitbucket.org/user/repo'
      local fields = {
        branch = 'main',
        file = 'src/test.lua',
      }
      local url = gitbrowse.get_url(repo, fields)
      eq(url, 'https://bitbucket.org/user/repo/src/main/src/test.lua')
    end)
  end)

  describe('blame_hash', function()
    it('extracts the 7-char hash from a blame line', function()
      eq(gitbrowse.blame_hash 'd4d38871   3 (Moshe Avni 2026-03-29 13:05:49 +0300   1) # CLAUDE.md', 'd4d3887')
    end)

    it('strips the boundary commit prefix', function()
      eq(gitbrowse.blame_hash '^d4d3887 (Moshe Avni 2026-03-29 13:05:49 +0300 1) # CLAUDE.md', 'd4d3887')
    end)

    it('returns nil for uncommitted lines', function()
      assert.is_nil(gitbrowse.blame_hash '00000000 zsh/.zshrc (Not Committed Yet 2026-10-25 12:43:11 +0200 117) foo')
    end)

    it('returns nil when the line has no hash', function()
      assert.is_nil(gitbrowse.blame_hash '')
      assert.is_nil(gitbrowse.blame_hash '# not a hash')
    end)
  end)

  describe('open', function()
    local orig_notify

    before_each(function()
      orig_notify = vim.notify
    end)

    after_each(function()
      vim.notify = orig_notify
    end)

    it('notifies a string and does not raise when the commit is invalid', function()
      local msgs = {}
      vim.notify = function(msg)
        msgs[#msgs + 1] = msg
      end
      local ok, err = pcall(gitbrowse.open, { what = 'commit', commit = '0000000', notify = false, open = function() end })
      eq(ok, true, err)
      eq(#msgs, 1)
      eq(type(msgs[1]), 'string')
      assert.is_truthy(msgs[1]:find('Invalid commit hash', 1, true))
    end)
  end)
end)
