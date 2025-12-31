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
    local default_opts = {
      what = 'file',
      remote_patterns = {
        { '^(https?://.*)%.git$', '%1' },
        { '^git@(.+):(.+)%.git$', 'https://%1/%2' },
        { '^git@(.+):(.+)$', 'https://%1/%2' },
        { '^git@(.+)/(.+)$', 'https://%1/%2' },
        { '^ssh://git@(.*)$', 'https://%1' },
        { '^ssh://([^:/]+)(:%d+)/(.*)$', 'https://%1/%3' },
        { '^ssh://([^/]+)/(.*)$', 'https://%1/%2' },
        { 'ssh%.dev%.azure%.com/v3/(.*)/(.*)$', 'dev.azure.com/%1/_git/%2' },
        { '^https://%w*@(.*)', 'https://%1' },
        { '^git@(.*)', 'https://%1' },
        { ':%d+', '' },
        { '%.git$', '' },
      },
      url_patterns = {
        ['github%.com'] = {
          branch = '/tree/{branch}',
          file = '/blob/{branch}/{file}#L{line_start}-L{line_end}',
          commit = '/commit/{commit}',
        },
        ['gitlab%.com'] = {
          branch = '/-/tree/{branch}',
          file = '/-/blob/{branch}/{file}#L{line_start}-L{line_end}',
          commit = '/-/commit/{commit}',
        },
        ['bitbucket%.org'] = {
          branch = '/src/{branch}',
          file = '/src/{branch}/{file}#lines-{line_start}-L{line_end}',
          commit = '/commits/{commit}',
        },
      },
    }

    it('builds GitHub file URL', function()
      local repo = 'https://github.com/user/repo'
      local fields = {
        branch = 'main',
        file = 'src/test.lua',
        line_start = 10,
        line_end = 20,
      }
      local url = gitbrowse.get_url(repo, fields, default_opts)
      eq(url, 'https://github.com/user/repo/blob/main/src/test.lua#L10-L20')
    end)

    it('builds GitHub branch URL', function()
      local repo = 'https://github.com/user/repo'
      local fields = { branch = 'develop' }
      local opts = vim.tbl_extend('force', default_opts, { what = 'branch' })
      local url = gitbrowse.get_url(repo, fields, opts)
      eq(url, 'https://github.com/user/repo/tree/develop')
    end)

    it('builds GitHub commit URL', function()
      local repo = 'https://github.com/user/repo'
      local fields = { commit = 'abc123def456' }
      local opts = vim.tbl_extend('force', default_opts, { what = 'commit' })
      local url = gitbrowse.get_url(repo, fields, opts)
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
      local url = gitbrowse.get_url(repo, fields, default_opts)
      eq(url, 'https://gitlab.com/user/repo/-/blob/main/src/test.lua#L5-L15')
    end)

    it('builds GitLab branch URL', function()
      local repo = 'https://gitlab.com/user/repo'
      local fields = { branch = 'feature/test' }
      local opts = vim.tbl_extend('force', default_opts, { what = 'branch' })
      local url = gitbrowse.get_url(repo, fields, opts)
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
      local url = gitbrowse.get_url(repo, fields, default_opts)
      eq(url, 'https://bitbucket.org/user/repo/src/main/src/test.lua#lines-1-L10')
    end)

    it('returns repo URL for unknown remote', function()
      local repo = 'https://unknown.com/user/repo'
      local fields = { branch = 'main' }
      local url = gitbrowse.get_url(repo, fields, default_opts)
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
      local url = gitbrowse.get_url(repo, fields, default_opts)
      eq(url, 'https://github.com/user/repo/blob/main/test.lua#L42-L42')
    end)
  end)
end)
