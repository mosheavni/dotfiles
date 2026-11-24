local git = require 'user.git'
local M = {}

--- Show a GitHub PR's "Files changed" in Diffview, inside the local worktree of its branch (~/Repos/<repo>), in its wezterm tab.
---@param url string e.g. https://github.com/org/repo/pull/301
M.diff_pr = function(url)
  local repo = url:match 'github%.com/[^/]+/([^/]+)/pull/%d+'
  local main = repo and vim.fn.expand('~/Repos/' .. repo)
  if not repo or vim.fn.isdirectory(main) == 0 then
    return git.prnt('Not a PR URL of a repo under ~/Repos: ' .. url, true)
  end
  git.prnt('Opening PR diff: ' .. url)
  vim.system({ 'gh', 'pr', 'view', url, '--json', 'headRefName,baseRefName', '-q', '.headRefName + " " + .baseRefName' }, { text = true }, function(res)
    vim.schedule(function()
      local branch, base = vim.trim(res.stdout or ''):match '^(%S+) (%S+)$'
      if res.code ~= 0 or not branch then
        return git.prnt('gh pr view failed: ' .. vim.trim(res.stderr or ''), true)
      end
      local dir = vim.iter(git.get_worktree_branches_sync(main)):find(function(_, b)
        return b == branch
      end)
      if not dir then
        return git.prnt(('No worktree of %s has branch %s'):format(repo, branch), true)
      end
      git.run_git({ 'fetch', 'origin' }, nil, function(_, code)
        if code == 0 then
          vim.schedule(function()
            require('user.projects').open_project(dir, ('DiffviewOpen origin/%s..HEAD'):format(base))
          end)
        end
      end, { cwd = dir })
    end)
  end)
end

return M
