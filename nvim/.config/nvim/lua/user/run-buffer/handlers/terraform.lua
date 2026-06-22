-- Terraform: run plan in the buffer directory (no file path appended).
local utils = require 'user.utils'

local M = {}

M.ft = 'terraform'

---@type RunHandler
M.handler = {
  resolve = function()
    return { cmd = utils.command_for_filetype 'terraform', spawn = true }
  end,
}

return M
