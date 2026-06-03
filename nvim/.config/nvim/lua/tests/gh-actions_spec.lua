---@diagnostic disable: undefined-field, invisible
local eq = assert.are.same
local gh = require 'user.gh-actions'

describe('user.gh-actions', function()
  describe('build_push_event', function()
    it('includes repository default branch and push metadata', function()
      eq(gh.build_push_event {
        default_branch = 'master',
        owner_repo = 'user/repo',
        before = 'abc123',
      }, {
        repository = {
          default_branch = 'master',
          full_name = 'user/repo',
        },
        before = 'abc123',
        forced = false,
      })
    end)

    it('defaults before to the zero sha', function()
      eq(gh.build_push_event { default_branch = 'main' }.before, gh.ZERO_SHA)
    end)

    it('omits full_name when owner_repo is missing', function()
      local event = gh.build_push_event { default_branch = 'main' }
      eq(event.repository.full_name, nil)
    end)
  end)

  describe('write_event_file', function()
    it('writes valid JSON', function()
      local path = vim.fn.tempname() .. '.json'
      gh.write_event_file(gh.build_push_event { default_branch = 'master' }, path)
      local f = assert(io.open(path, 'r'))
      local contents = f:read '*a'
      f:close()
      os.remove(path)
      eq(vim.json.decode(contents), gh.build_push_event { default_branch = 'master' })
    end)
  end)

  describe('build_act_cmd', function()
    local original_git
    local original_gh

    before_each(function()
      original_git = package.loaded['user.git']
      original_gh = package.loaded['user.gh-actions']
      package.loaded['user.gh-actions'] = nil
    end)

    after_each(function()
      package.loaded['user.git'] = original_git
      package.loaded['user.gh-actions'] = original_gh
    end)

    it('builds act with default branch, workflow path, and event file', function()
      package.loaded['user.git'] = {
        get_toplevel_sync = function()
          return '/repo'
        end,
        get_default_branch_sync = function()
          return 'master'
        end,
        get_owner_repo_sync = function()
          return 'user/repo'
        end,
      }

      local gh_mod = require 'user.gh-actions'
      gh_mod.get_push_before_sha_sync = function()
        return gh_mod.ZERO_SHA
      end
      local event_path
      gh_mod.write_event_file = function(_event, path)
        event_path = path
      end
      local cmd = gh_mod.build_act_cmd '/repo/.github/workflows/lint.yml'
      assert.is_not_nil(cmd)
      assert.matches('act ', cmd)
      assert.matches('--defaultbranch=master', cmd)
      assert.matches('--container%-architecture linux/amd64', cmd)
      assert.matches("-W '/repo/%.github/workflows/lint%.yml'", cmd)
      assert.matches("-e '/repo/%.github/%.act%-event%.json'", cmd)
      eq(event_path, '/repo/.github/.act-event.json')
    end)

    it('returns nil outside a git repository', function()
      package.loaded['user.git'] = {
        get_toplevel_sync = function()
          return ''
        end,
      }
      local gh_mod = require 'user.gh-actions'
      eq(gh_mod.build_act_cmd '/tmp/lint.yml', nil)
    end)
  end)
end)
