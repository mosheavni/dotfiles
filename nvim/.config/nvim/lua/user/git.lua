local utils = require 'user.utils'
local M = {}

M.prnt = function(message, error)
  vim.schedule(function()
    utils.pretty_print(message, 'Git Actions', '', error and vim.log.levels.ERROR, error and 7000 or 3000)
  end)
end

M.get_fugitive_buffer = function()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local bufname = vim.api.nvim_buf_get_name(buf)
    if vim.startswith(bufname, 'fugitive://') and string.find(bufname, '.git//') then
      return buf
    end
  end
  return nil
end

M.reload_fugitive_index = function()
  vim.schedule(function()
    local buf = M.get_fugitive_buffer()
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_call(buf, vim.cmd.edit)
    end
  end)
end

local function with_ui_select(items, opts, cb, auto_select)
  auto_select = auto_select == nil and true or auto_select
  if #items == 1 and auto_select then
    return cb(items[1])
  end
  vim.schedule(function()
    vim.ui.select(items, opts, function(selection)
      if not selection then
        return M.prnt 'Canceled.'
      end
      cb(selection)
    end)
  end)
end

local function run_git(args, msg, cb)
  if msg then
    M.prnt(msg)
  end
  vim.system({ 'git', unpack(args) }, { text = true }, function(obj)
    local code, stdout, stderr = obj.code, vim.trim(obj.stdout or ''), vim.trim(obj.stderr or '')
    if code ~= 0 then
      M.prnt(('Error!\n%s%s'):format(stderr and stderr .. '\n' or '', stdout or ''), true)
    elseif msg then
      M.prnt(('Success!\n%s%s'):format(stderr and stderr .. '\n' or '', stdout or ''))
    end
    if cb and type(cb) == 'function' then
      cb(stdout)
    end
    M.reload_fugitive_index()
  end)
end

local function run_git_sync(args, msg)
  if msg then
    M.prnt(msg)
  end
  return vim.system({ 'git', unpack(args) }, { text = true }):wait()
end

-------------------
-- Git Functions --
-------------------

M.get_branch = function(cb)
  run_git({ 'branch', '--show-current' }, nil, function(branch)
    local branch = vim.trim(branch)
    if branch == '' then
      M.get_short_commit(function(commit_hash)
        M.prnt('No branch found, using commit hash: ' .. commit_hash)
        cb(commit_hash)
      end)
    else
      cb(vim.trim(branch))
    end
  end)
end

M.get_branch_sync = function()
  local branch = vim.trim(run_git_sync({ 'branch', '--show-current' }, nil).stdout)
  if branch == '' then
    return M.get_short_commit_sync()
  else
    return branch
  end
end

M.get_short_commit = function(cb)
  run_git({ 'rev-parse', '--short', 'HEAD' }, nil, function(commit_hash)
    cb(vim.trim(commit_hash))
  end)
end

M.get_short_commit_sync = function()
  return vim.trim(run_git_sync({ 'rev-parse', '--short', 'HEAD' }, nil).stdout)
end

M.get_remotes = function(cb)
  run_git({ 'remote', '-v' }, nil, function(obj)
    local remotes = {}
    for _, v in ipairs(vim.split(obj, '\n')) do
      local l = v:match '(.-)%s+%(fetch%)'
      if l then
        local splited = vim.split(l, '\t')
        remotes[splited[1]] = splited[2]
      end
    end
    cb(remotes)
  end)
end

M.get_tags = function(cb)
  run_git({ 'tag' }, nil, function(tags)
    cb(vim.split(tags, '\n'))
  end)
end

M.get_branches = function(remote_name, cb)
  run_git({ 'ls-remote', '--heads', remote_name or 'origin' }, nil, function(obj)
    local branches = {}
    for _, line in ipairs(vim.split(obj, '\n')) do
      table.insert(branches, string.match(line, 'refs/heads/(.*)$'))
    end
    cb(branches)
  end)
end

M.get_branches_sync = function(remote_name)
  local obj = run_git_sync { 'ls-remote', '--heads', remote_name or 'origin' }
  local branches = {}
  for _, line in ipairs(vim.split(obj.stdout, '\n')) do
    table.insert(branches, string.match(line, 'refs/heads/(.*)$'))
  end
  return branches
end

M.get_toplevel = function(cb)
  run_git({ 'rev-parse', '--show-toplevel' }, nil, function(toplevel)
    cb(vim.trim(toplevel))
  end)
end

M.get_toplevel_sync = function()
  local toplevel = run_git_sync({ 'rev-parse', '--show-toplevel' }, nil).stdout or ''
  return vim.trim(toplevel)
end

M.checkout = function(branch_name)
  run_git({ 'checkout', branch_name }, 'Checking out ' .. branch_name)
end

M.push = function(cb)
  M.get_branch(function(branch)
    run_git({ 'push', '-u', 'origin', branch }, 'Pushing to ' .. branch .. '...', cb)
  end)
end

M.pull = function(cb)
  M.get_branch(function(branch)
    run_git({ 'pull' }, 'Pulling from ' .. branch .. '...', cb)
  end)
end

M.pull_remote_branch = function(remote_name, branch_name)
  run_git({ 'pull', remote_name, branch_name }, 'Pulling ' .. remote_name .. '/' .. branch_name)
end

M.merge_remote_branch = function(remote_name, branch_name)
  run_git({ 'merge', remote_name .. '/' .. branch_name }, 'Merging ' .. remote_name .. '/' .. branch_name)
end

M.create_pull_request = function()
  M.get_remotes(function(git_remotes)
    local git_remote_url = git_remotes['origin']
    local prefix = git_remote_url:match '^%w+' == 'git' and 'git@' or 'https://'
    local git_name, project, repo = git_remote_url:match(('^' .. prefix .. '(%w+).com.*[:/](.+)/(.+)%.git'))
    local pr_link = git_name == 'gitlab' and '-/merge_requests/new?merge_request[source_branch]=' or 'pull/new/'

    M.get_branch(function(branch_name)
      local url = ('https://%s.com/%s/%s/%s%s'):format(git_name, project, repo, pr_link, branch_name)
      vim.ui.open(url)
    end)
  end)
end

M.create_new_branch = function(branch_opts)
  if branch_opts.args ~= '' then
    return run_git({ 'checkout', '-b', branch_opts.args }, 'Creating new branch ' .. branch_opts.args)
  end
  vim.ui.input({ prompt = 'Enter new branch name❯ ' }, function(input)
    if not input then
      return M.prnt 'Canceled.'
    end
    if not input:match '^[a-zA-Z0-9_-]+$' then
      return M.prnt('Invalid branch name', vim.log.levels.ERROR)
    end
    run_git({ 'checkout', '-b', input }, 'Creating new branch: ' .. input)
  end)
end

M.fetch_all = function()
  run_git({ 'fetch', '--all', '--tags' }, 'Fetching all remotes and tags')
end

M.soft_revert = function(marker)
  run_git({ 'reset', '--soft', marker or 'HEAD^' }, 'Soft reverting to ' .. (marker or 'HEAD^'))
end

M.set_upstream_head = function()
  M.ui_select_remotes(function(remote_name)
    M.get_branch(function(branch_name)
      run_git({
        'branch',
        '--set-upstream-to',
        remote_name .. '/' .. branch_name,
      }, 'Setting upstream to ' .. remote_name .. '/' .. branch_name)
    end)
  end)
end

M.first_commit = function()
  M.get_branch(function(branch)
    run_git({ 'commit', '--quiet', '-m', branch }, 'Committing: ' .. branch, function()
      run_git({ 'push', '-u', 'origin', branch }, 'Pushing: ' .. branch, M.create_pull_request)
    end)
  end)
end

M.enter_wip = function()
  local msg = string.format('%s work in progress %s', utils.random_emoji(), vim.fn.strftime '%c')
  run_git({ 'commit', '--quiet', '-m', msg }, 'Committing: ' .. msg, M.push)
end

---------------
-- UI Select --
---------------
M.ui_select_remotes = function(cb)
  M.get_remotes(function(remotes)
    local remote_list = vim.tbl_keys(remotes)
    with_ui_select(remote_list, { title = 'Remotes', prompt = 'Select remote❯ ' }, cb)
  end)
end

M.ui_select_tags = function(cb)
  M.get_tags(function(tags)
    with_ui_select(tags, { title = 'Tags', prompt = 'Select tag❯ ' }, cb, false)
  end)
end

M.ui_select_branches = function(remote_name, cb)
  M.get_branches(remote_name, function(branches)
    with_ui_select(branches, { title = 'Branches', prompt = 'Select branch❯ ' }, cb, false)
  end)
end

M.ui_select_pull_remote_branch = function()
  M.ui_select_remotes(function(remote_name)
    M.ui_select_branches(remote_name, function(branch_name)
      M.pull_remote_branch(remote_name, branch_name)
    end)
  end)
end

M.ui_select_merge_remote_branch = function()
  M.ui_select_remotes(function(remote_name)
    M.ui_select_branches(remote_name, function(branch_name)
      M.merge_remote_branch(remote_name, branch_name)
    end)
  end)
end

M.ui_select_create_tag = function()
  vim.defer_fn(function()
    vim.ui.input({ prompt = 'Enter tag name❯ ' }, function(tag_name)
      if not tag_name then
        return M.prnt 'Canceled.'
      end
      run_git({ 'tag', tag_name }, 'Creating tag: ' .. tag_name, function()
        with_ui_select({ 'Yes', 'No' }, { prompt = 'Push❯ ' }, function(choice)
          if choice == 'Yes' then
            M.prnt('Pushing tag ' .. tag_name .. '...')
            run_git({ 'push', '--tags' }, nil, function()
              M.prnt('Tag ' .. tag_name .. ' created and pushed.')
            end)
          else
            M.prnt('Tag ' .. tag_name .. ' created.')
          end
        end)
      end)
    end)
  end, 100)
end

M.ui_select_rename_branch = function(branch_name, cb)
  -- require('fzf-lua.utils').fzf_exit()
  vim.defer_fn(function()
    vim.ui.input({ prompt = 'Enter new branch name❯ ', default = branch_name }, function(new_name)
      if not new_name then
        return M.prnt 'Canceled.'
      end
      run_git({ 'branch', '-m', branch_name, new_name }, 'Renaming branch: ' .. branch_name .. ' to ' .. new_name, cb)
    end)
  end, 100)
end

M.ui_select_delete_tag = function()
  M.ui_select_tags(function(tag)
    M.prnt('Deleting tag ' .. tag .. ' locally...')
    run_git({ 'tag', '-d', tag }, nil, function()
      with_ui_select({ 'Yes', 'No' }, { prompt = 'Delete tag ' .. tag .. ' from remote❯ ' }, function(choice)
        if choice == 'Yes' then
          M.ui_select_remotes(function(remote)
            M.prnt('Deleting tag ' .. tag .. ' from remote ' .. remote .. '...')
            run_git({ 'push', remote, ':refs/tags/' .. tag }, nil, function()
              M.prnt('Tag ' .. tag .. ' deleted from local and remote.')
            end)
          end)
        else
          M.prnt('Tag ' .. tag .. ' deleted only locally.')
        end
      end)
    end)
  end)
end

return M
