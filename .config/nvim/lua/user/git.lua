local utils = require 'user.utils'
local M = {}

M.prnt = function(message, error)
  local timeout = 3000
  local level
  if error then
    timeout = 7000
    level = vim.log.levels.ERROR
  end
  vim.schedule(function()
    utils.pretty_print(message, 'Git Actions', '', level, timeout)
  end)
end

M.reload_fugitive_index = function()
  vim.schedule(function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local bufname = vim.api.nvim_buf_get_name(buf)
      if vim.startswith(bufname, 'fugitive://') and string.find(bufname, '.git//') then
        vim.api.nvim_buf_call(buf, function()
          vim.cmd.edit() -- refresh the buffer
        end)
      end
    end
  end)
end

local function with_ui_select(items, opts, cb)
  if #items == 1 then
    cb(items[1])
  end
  vim.schedule(function()
    vim.ui.select(items, opts, function(selection)
      if not selection then
        M.prnt 'Canceled.'
        return
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
    local code, stdout, stderr = obj.code, obj.stdout, obj.stderr
    stdout = vim.trim(stdout or '') or nil
    stderr = vim.trim(stderr or '') or nil
    if code ~= 0 then
      local new_msg = 'Error!'
      if stderr then
        new_msg = new_msg .. '\n' .. stderr
      end
      if stdout then
        new_msg = new_msg .. '\n' .. stdout
      end
      M.prnt(new_msg, true)
      M.reload_fugitive_index()
      return
    end
    if msg then
      local new_msg = 'Success!'
      if stdout then
        new_msg = new_msg .. '\n' .. stdout
      end
      M.prnt(new_msg)
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
    cb(vim.trim(branch))
  end)
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
  if not remote_name then
    remote_name = 'origin'
  end
  run_git({ 'ls-remote', '--heads', remote_name }, nil, function(obj)
    local branches = {}
    for _, line in ipairs(vim.split(obj, '\n')) do
      table.insert(branches, string.match(line, 'refs/heads/(.*)$'))
    end
    cb(branches)
  end)
end

M.get_branches_sync = function(remote_name)
  if not remote_name then
    remote_name = 'origin'
  end
  local obj = run_git_sync { 'ls-remote', '--heads', remote_name }
  local branches = {}
  for _, line in ipairs(vim.split(obj.stdout, '\n')) do
    table.insert(branches, string.match(line, 'refs/heads/(.*)$'))
  end
  return branches
end

M.push = function(cb)
  M.get_branch(function(branch)
    run_git({ 'push', 'origin', branch }, 'Pushing to ' .. branch .. '...', function(obj)
      if cb then
        cb(obj)
      end
    end)
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
    local prefix = git_remote_url:match '^%w+'
    prefix = prefix == 'git' and 'git@' or 'https://'
    local git_name, project, repo, _ = git_remote_url:match(('^' .. prefix .. '(%w+).com[:/](.+)/(.+)%.git'))
    local pr_link = git_name == 'gitlab' and '-/merge_requests/new?merge_request[source_branch]=' or 'pull/new/'

    M.get_branch(function(branch_name)
      vim.print('git_name: ' .. git_name .. ' project: ' .. project .. ' repo: ' .. repo .. ' pr_link: ' .. pr_link .. ' branch_name: ' .. branch_name)
      local url = string.format('https://%s.com/%s/%s/%s%s', git_name, project, repo, pr_link, branch_name)
      vim.print('Opening ' .. url)
      vim.ui.open(url)
    end)
  end)
end

M.create_new_branch = function(branch_opts)
  if branch_opts.args ~= '' then
    return run_git({ 'checkout', '-b', branch_opts.args }, 'Creating new branch ' .. branch_opts.args)
  end
  vim.ui.input({ prompt = 'Enter new branch name: ' }, function(input)
    if not input then
      return
    end
    -- validate branch name regex in lua
    if not string.match(input, '^[a-zA-Z0-9_-]+$') then
      return vim.notify('Invalid branch name', vim.log.levels.ERROR)
    end
    run_git({ 'checkout', '-b', input }, 'Creating new branch: ' .. input)
  end)
end

M.fetch_all = function()
  run_git({ 'fetch', '--all', '--tags' }, 'Fetching all remotes and tags')
end

M.soft_revert = function(marker)
  if not marker then
    marker = 'HEAD^'
  end
  run_git({ 'reset', '--soft', marker }, 'Soft reverting to ' .. marker)
end

M.set_upstream_head = function()
  M.ui_select_remotes(function(remote_name)
    M.get_branch(function(branch_name)
      run_git({ 'branch', '--set-upstream-to', remote_name .. '/' .. branch_name }, 'Setting upstream to ' .. remote_name .. '/' .. branch_name)
    end)
  end)
end

M.first_commit = function()
  M.get_branch(function(branch)
    run_git({ 'commit', '--quiet', '-m', branch }, 'Committing: ' .. branch, function()
      run_git({ 'push', '-u', 'origin', branch }, 'Pushing: ' .. branch, function()
        M.create_pull_request()
      end)
    end)
  end)
end

M.enter_wip = function()
  local emoji = utils.random_emoji()
  local now = vim.fn.strftime '%c'
  local msg = string.format('%s work in progress %s', emoji, now)
  run_git({ 'commit', '--quiet', '-m', msg }, 'Committing: ' .. msg, function()
    M.push()
  end)
end

---------------
-- UI Select --
---------------
M.ui_select_remotes = function(cb)
  M.get_remotes(function(remotes)
    local remote_list = {}
    for k, _ in pairs(remotes) do
      table.insert(remote_list, k)
    end
    with_ui_select(remote_list, { prompt = 'Select remote: ' }, cb)
  end)
end

M.ui_select_tags = function(cb)
  M.get_tags(function(tags)
    with_ui_select(tags, { prompt = 'Select tag: ' }, cb)
  end)
end

M.ui_select_branches = function(remote_name, cb)
  M.get_branches(remote_name, function(branches)
    with_ui_select(branches, { prompt = 'Select branch: ' }, cb)
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
  vim.ui.input({ prompt = 'Enter tag name: ' }, function(tag_name)
    if not tag_name then
      M.prnt 'Canceled.'
    end
    run_git({ 'tag', tag_name }, 'Creating tag: ' .. tag_name, function()
      with_ui_select({ 'Yes', 'No' }, { prompt = 'Push?' }, function(choice)
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
end

M.ui_select_delete_tag = function()
  M.ui_select_tags(function(tag)
    M.prnt('Deleting tag ' .. tag .. ' locally...')
    run_git({ 'tag', '-d', tag }, nil, function()
      with_ui_select({ 'Yes', 'No' }, { prompt = 'Delete tag ' .. tag .. ' from remote?' }, function(choice)
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
