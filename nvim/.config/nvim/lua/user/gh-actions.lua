local M = {}

local ZERO_SHA = string.rep('0', 40)

--- Build the `act` command for a workflow file. Writes a minimal push event
--- to `<repo>/.github/.act-event.json` so super-linter, GitGuardian, etc. work.
---@param workflow_path string absolute path to a workflow file
---@return string|nil cmd nil when not in a git repository
function M.build_act_cmd(workflow_path)
  local git = require 'user.git'
  local repo_root = git.get_toplevel_sync()
  if repo_root == '' then
    vim.notify('gh-actions: not inside a git repository; cannot run act', vim.log.levels.ERROR)
    return nil
  end

  local default_branch = git.get_default_branch_sync()
  local owner_repo = git.get_owner_repo_sync()
  local event_path = repo_root .. '/.github/.act-event.json'

  local repository = { default_branch = default_branch }
  if owner_repo and owner_repo ~= '' then
    repository.full_name = owner_repo
  end

  local before = vim.system({ 'git', 'rev-parse', 'HEAD~1' }, { text = true, cwd = repo_root }):wait()
  local before_sha = before.code == 0 and vim.trim(before.stdout or '') or ''

  vim.fn.mkdir(vim.fn.fnamemodify(event_path, ':h'), 'p')
  local f = assert(io.open(event_path, 'w'))
  f:write(vim.json.encode {
    repository = repository,
    before = before_sha ~= '' and before_sha or ZERO_SHA,
    forced = false,
  }, '\n')
  f:close()

  return table.concat({
    'act',
    '--defaultbranch=' .. default_branch,
    '--container-architecture linux/amd64',
    '-W ' .. vim.fn.shellescape(workflow_path),
    '-e ' .. vim.fn.shellescape(event_path),
  }, ' ')
end

return M
