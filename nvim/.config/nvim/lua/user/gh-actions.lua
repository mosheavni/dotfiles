local function git()
  return require 'user.git'
end

local M = {}

M.ZERO_SHA = '0000000000000000000000000000000000000000'

--- Minimal push payload for local `act` runs (super-linter, GitGuardian, etc.).
---@class GhActionsPushEvent
---@field repository { default_branch: string, full_name?: string }
---@field before string
---@field forced boolean

---@param info { default_branch: string, owner_repo?: string, before?: string }
---@return GhActionsPushEvent
function M.build_push_event(info)
  local event = {
    repository = {
      default_branch = info.default_branch,
    },
    before = info.before or M.ZERO_SHA,
    forced = false,
  }
  if info.owner_repo and info.owner_repo ~= '' then
    event.repository.full_name = info.owner_repo
  end
  return event
end

---@param event GhActionsPushEvent
---@param path string
function M.write_event_file(event, path)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
  local f = assert(io.open(path, 'w'))
  f:write(vim.json.encode(event))
  f:write '\n'
  f:close()
end

---@return string|nil before_sha
function M.get_push_before_sha_sync()
  local obj = vim.system({ 'git', 'rev-parse', 'HEAD~1' }, { text = true, cwd = git().get_toplevel_sync() }):wait()
  if obj.code == 0 and obj.stdout and vim.trim(obj.stdout) ~= '' then
    return vim.trim(obj.stdout)
  end
  return M.ZERO_SHA
end

---@param workflow_path string absolute path to a workflow file
---@return string|nil cmd shell command, nil when not in a git repo
function M.build_act_cmd(workflow_path)
  local repo_root = git().get_toplevel_sync()
  if repo_root == '' then
    vim.notify('gh-actions: not inside a git repository; cannot run act', vim.log.levels.ERROR)
    return nil
  end

  local default_branch = git().get_default_branch_sync()
  local owner_repo = git().get_owner_repo_sync()
  local before = M.get_push_before_sha_sync()

  local event = M.build_push_event {
    default_branch = default_branch,
    owner_repo = owner_repo,
    before = before,
  }

  local event_path = repo_root .. '/.github/.act-event.json'
  M.write_event_file(event, event_path)

  return table.concat({
    'act',
    '--defaultbranch=' .. default_branch,
    '--container-architecture linux/amd64',
    '-W ' .. vim.fn.shellescape(workflow_path),
    '-e ' .. vim.fn.shellescape(event_path),
  }, ' ')
end

---@param workflow_path string
---@param on_done fun(cmd: string|nil)
function M.resolve_act_cmd_async(workflow_path, on_done)
  on_done(M.build_act_cmd(workflow_path))
end

return M
