-- pre-commit config: run all hooks from the git repo root.
return {
  ft = 'yaml.precommit',
  ---@type RunHandler
  handler = {
    resolve = function()
      local root = require('user.git').get_toplevel_sync()
      if root == '' then
        vim.notify('pre-commit: not inside a git repository', vim.log.levels.ERROR)
        return { spawn = false }
      end
      return {
        cmd = 'pre-commit run --all-files',
        spawn = true,
        cwd = root,
      }
    end,
  },
}
