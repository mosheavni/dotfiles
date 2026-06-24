-- Plain yaml: `kubectl apply --dry-run` when `vim.b.is_kubernetes`, else `yq`.
local utils = require 'user.utils'

return {
  ft = 'yaml',
  ---@type RunHandler
  handler = {
    resolve = function(ctx)
      local cmd = utils.command_for_filetype 'yaml' .. ' ' .. ctx.file_name
      if vim.b.is_kubernetes then
        cmd = 'kubectl apply --dry-run=client -f ' .. vim.fn.shellescape(ctx.file_name)
      end
      return { cmd = cmd, spawn = true }
    end,
  },
}
