-- Terraform: run plan in the buffer directory (no file path appended).
local utils = require 'user.utils'

return {
  ft = 'terraform',
  ---@type RunHandler
  handler = {
    resolve = function()
      return { cmd = utils.command_for_filetype 'terraform', spawn = true }
    end,
  },
}
