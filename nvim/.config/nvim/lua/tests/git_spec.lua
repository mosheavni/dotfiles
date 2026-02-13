---@diagnostic disable: undefined-field, invisible
--# selene: allow(undefined_variable)
local eq = assert.are.same
local git = require 'user.git'

describe('user.git', function()
  describe('git.extract_owner_repo (URL parsing for gh api)', function()
    it('parses SSH URL with .git extension', function()
      local result = git.extract_owner_repo 'git@github.com:user/repo.git'
      eq(result, 'user/repo')
    end)

    it('parses SSH URL without .git extension', function()
      local result = git.extract_owner_repo 'git@github.com:user/repo'
      eq(result, 'user/repo')
    end)

    it('parses HTTPS URL with .git extension', function()
      local result = git.extract_owner_repo 'https://github.com/user/repo.git'
      eq(result, 'user/repo')
    end)

    it('parses HTTPS URL without .git extension', function()
      local result = git.extract_owner_repo 'https://github.com/user/repo'
      eq(result, 'user/repo')
    end)

    it('parses GitLab SSH URL', function()
      local result = git.extract_owner_repo 'git@gitlab.com:organization/project.git'
      eq(result, 'organization/project')
    end)

    it('parses GitLab HTTPS URL', function()
      local result = git.extract_owner_repo 'https://gitlab.com/organization/project'
      eq(result, 'organization/project')
    end)

    it('handles repos with hyphens', function()
      local result = git.extract_owner_repo 'git@github.com:my-org/my-repo.git'
      eq(result, 'my-org/my-repo')
    end)

    it('handles repos with underscores', function()
      local result = git.extract_owner_repo 'git@github.com:my_org/my_repo.git'
      eq(result, 'my_org/my_repo')
    end)

    it('handles repos with numbers', function()
      local result = git.extract_owner_repo 'git@github.com:user123/repo456.git'
      eq(result, 'user123/repo456')
    end)

    it('handles enterprise GitHub URLs', function()
      local result = git.extract_owner_repo 'git@github.mycompany.com:team/project.git'
      eq(result, 'team/project')
    end)

    it('handles HTTPS with username prefix', function()
      local result = git.extract_owner_repo 'https://username@github.com/user/repo.git'
      eq(result, 'user/repo')
    end)
  end)

  describe('git.parse_symbolic_ref', function()
    it('parses main branch from symbolic-ref output', function()
      local result = git.parse_symbolic_ref('refs/remotes/origin/main\n', 'origin')
      eq(result, 'main')
    end)

    it('parses master branch from symbolic-ref output', function()
      local result = git.parse_symbolic_ref('refs/remotes/origin/master\n', 'origin')
      eq(result, 'master')
    end)

    it('parses develop branch from symbolic-ref output', function()
      local result = git.parse_symbolic_ref('refs/remotes/origin/develop\n', 'origin')
      eq(result, 'develop')
    end)

    it('handles branch names with slashes', function()
      local result = git.parse_symbolic_ref('refs/remotes/origin/feature/branch\n', 'origin')
      eq(result, 'feature/branch')
    end)

    it('handles different remote names', function()
      local result = git.parse_symbolic_ref('refs/remotes/upstream/main\n', 'upstream')
      eq(result, 'main')
    end)

    it('trims whitespace from output', function()
      local result = git.parse_symbolic_ref('  refs/remotes/origin/main  \n', 'origin')
      eq(result, 'main')
    end)

    it('returns nil for non-matching output', function()
      local result = git.parse_symbolic_ref('not a valid ref', 'origin')
      assert.is_nil(result)
    end)

    it('returns nil for empty output', function()
      local result = git.parse_symbolic_ref('', 'origin')
      assert.is_nil(result)
    end)

    it('defaults remote to origin', function()
      local result = git.parse_symbolic_ref('refs/remotes/origin/main\n')
      eq(result, 'main')
    end)
  end)

  describe('get_default_branch fallback logic', function()
    it('filters common branches from available branches', function()
      local branches = { 'main', 'master', 'develop', 'feature/test', 'bugfix/issue' }
      local common = { 'main', 'master', 'develop' }
      local choices = vim.tbl_filter(function(b)
        return vim.tbl_contains(branches, b)
      end, common)
      eq(choices, { 'main', 'master', 'develop' })
    end)

    it('returns all branches when no common branches exist', function()
      local branches = { 'trunk', 'release', 'staging' }
      local common = { 'main', 'master', 'develop' }
      local choices = vim.tbl_filter(function(b)
        return vim.tbl_contains(branches, b)
      end, common)
      if #choices == 0 then
        choices = branches
      end
      eq(choices, { 'trunk', 'release', 'staging' })
    end)

    it('returns partial common branches when some exist', function()
      local branches = { 'main', 'staging', 'production' }
      local common = { 'main', 'master', 'develop' }
      local choices = vim.tbl_filter(function(b)
        return vim.tbl_contains(branches, b)
      end, common)
      eq(choices, { 'main' })
    end)
  end)

  describe('git.extract_owner_repo edge cases', function()
    it('handles Bitbucket SSH URL', function()
      local result = git.extract_owner_repo 'git@bitbucket.org:workspace/repo.git'
      eq(result, 'workspace/repo')
    end)

    it('handles Azure DevOps SSH URL', function()
      local result = git.extract_owner_repo 'git@ssh.dev.azure.com:v3/org/project/repo'
      eq(result, 'org/project/_git/repo')
    end)

    it('handles URL with port number', function()
      local result = git.extract_owner_repo 'ssh://git@github.com:22/user/repo.git'
      eq(result, 'user/repo')
    end)

    it('handles nested groups (GitLab subgroups)', function()
      local result = git.extract_owner_repo 'git@gitlab.com:group/subgroup/repo.git'
      eq(result, 'group/subgroup/repo')
    end)

    it('returns nil for invalid URL', function()
      local result = git.extract_owner_repo 'not-a-url'
      assert.is_nil(result)
    end)

    it('returns nil for empty string', function()
      local result = git.extract_owner_repo ''
      assert.is_nil(result)
    end)
  end)

  -- Integration tests (run against this repo)
  describe('integration: sync functions', function()
    it('get_branch_sync returns current branch', function()
      local branch = git.get_branch_sync()
      assert.is_not_nil(branch)
      assert.is_true(#branch > 0)
    end)

    it('get_toplevel_sync returns repo root', function()
      local toplevel = git.get_toplevel_sync()
      assert.is_not_nil(toplevel)
      assert.is_true(toplevel:match 'dotfiles$' ~= nil)
    end)

    it('get_branches_sync returns branches from origin', function()
      local branches = git.get_branches_sync 'origin'
      assert.is_not_nil(branches)
      assert.is_true(#branches > 0)
      -- This repo should have master branch
      assert.is_true(vim.tbl_contains(branches, 'master'))
    end)

    it('get_short_commit_sync returns valid hash', function()
      local hash = git.get_short_commit_sync()
      assert.is_not_nil(hash)
      assert.is_true(hash:match '^%x+$' ~= nil, 'Should be hex characters')
      assert.is_true(#hash >= 7, 'Should be at least 7 chars')
    end)
  end)

  describe('integration: async functions', function()
    it('get_default_branch returns master for this repo', function()
      local done = false
      local result_branch = nil

      git.get_default_branch('origin', function(branch)
        result_branch = branch
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)

      assert.is_true(done, 'Callback should have been called')
      eq(result_branch, 'master')
    end)

    it('get_remotes includes origin', function()
      local done = false
      local result_remotes = nil

      git.get_remotes(function(remotes)
        result_remotes = remotes
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)

      assert.is_true(done, 'Callback should have been called')
      assert.is_not_nil(result_remotes.origin)
      assert.is_true(result_remotes.origin:match 'dotfiles' ~= nil)
    end)

    it('get_branch returns current branch', function()
      local done = false
      local result_branch = nil

      git.get_branch(function(branch)
        result_branch = branch
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)

      assert.is_true(done, 'Callback should have been called')
      assert.is_not_nil(result_branch)
      assert.is_true(#result_branch > 0)
    end)

    it('get_branches returns branches for origin', function()
      local done = false
      local result_branches = nil

      git.get_branches('origin', function(branches)
        result_branches = branches
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)

      assert.is_true(done, 'Callback should have been called')
      assert.is_not_nil(result_branches)
      assert.is_true(#result_branches > 0)
      assert.is_true(vim.tbl_contains(result_branches, 'master'))
    end)
  end)
end)
