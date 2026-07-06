-- Terraform: run plan in the buffer directory (no file path appended).
-- A terragrunt.hcl next to the buffer means the directory is terragrunt-managed.
local utils = require 'user.utils'

return {
  ft = 'terraform',
  ---@type RunHandler
  handler = {
    resolve = function(ctx)
      local dir = vim.fs.dirname(ctx.file_name)
      if vim.uv.fs_stat(dir .. '/terragrunt.hcl') then
        return { cmd = 'terragrunt plan', spawn = true }
      end
      return { cmd = utils.command_for_filetype 'terraform', spawn = true }
    end,
  },
}
