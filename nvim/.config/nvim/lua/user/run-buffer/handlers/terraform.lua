-- Terraform: `terraform plan` without appending the file path.
local utils = require 'user.utils'

local M = {}

M.ft = 'terraform'

---@type RunHandler
M.handler = {
  resolve = function(ctx, on_done)
    on_done(utils.command_for_filetype(ctx.ft), false)
  end,
}

return M
