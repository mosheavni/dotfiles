---@diagnostic disable: undefined-field, invisible
local eq = assert.are.same

describe('user.gh-actions', function()
  local original_git
  local tmp_repo

  before_each(function()
    original_git = package.loaded['user.git']
    package.loaded['user.gh-actions'] = nil
    tmp_repo = vim.fn.tempname()
    vim.fn.mkdir(tmp_repo, 'p')
  end)

  after_each(function()
    package.loaded['user.git'] = original_git
    package.loaded['user.gh-actions'] = nil
    vim.fn.delete(tmp_repo, 'rf')
  end)

  describe('build_act_cmd', function()
    it('builds act command and writes a push event JSON file', function()
      package.loaded['user.git'] = {
        get_toplevel_sync = function()
          return tmp_repo
        end,
        get_default_branch_sync = function()
          return 'master'
        end,
        get_owner_repo_sync = function()
          return 'user/repo'
        end,
      }

      local workflow = tmp_repo .. '/.github/workflows/lint.yml'
      local cmd = require('user.gh-actions').build_act_cmd(workflow)

      assert.is_not_nil(cmd)
      assert.matches('^act ', cmd)
      assert.matches('--defaultbranch=master', cmd)
      assert.matches('--container%-architecture linux/amd64', cmd)
      assert.matches("-W '" .. vim.pesc(workflow) .. "'", cmd)

      local event_path = tmp_repo .. '/.github/.act-event.json'
      assert.matches("-e '" .. vim.pesc(event_path) .. "'", cmd)

      local f = assert(io.open(event_path, 'r'))
      local event = vim.json.decode(f:read '*a')
      f:close()

      eq(event.repository.default_branch, 'master')
      eq(event.repository.full_name, 'user/repo')
      eq(event.forced, false)
      eq(event.before, string.rep('0', 40)) -- tmp dir is not a git repo
    end)

    it('omits full_name when owner_repo is missing', function()
      package.loaded['user.git'] = {
        get_toplevel_sync = function()
          return tmp_repo
        end,
        get_default_branch_sync = function()
          return 'main'
        end,
        get_owner_repo_sync = function()
          return nil
        end,
      }

      require('user.gh-actions').build_act_cmd(tmp_repo .. '/.github/workflows/x.yml')

      local f = assert(io.open(tmp_repo .. '/.github/.act-event.json', 'r'))
      local event = vim.json.decode(f:read '*a')
      f:close()

      eq(event.repository.full_name, nil)
      eq(event.repository.default_branch, 'main')
    end)

    it('returns nil outside a git repository', function()
      package.loaded['user.git'] = {
        get_toplevel_sync = function()
          return ''
        end,
      }
      eq(require('user.gh-actions').build_act_cmd '/tmp/lint.yml', nil)
    end)
  end)
end)
