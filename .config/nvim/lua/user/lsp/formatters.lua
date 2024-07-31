local h = require 'null-ls.helpers'
local null_ls = require 'null-ls'

local M = {}

M.hclfmt = {
  name = 'hclfmt',
  method = null_ls.methods.FORMATTING,
  filetypes = { 'hcl' },
  generator = h.formatter_factory {
    command = 'terragrunt',
    args = { 'hclfmt', '--terragrunt-hclfmt-file', '$FILENAME' },
    to_temp_file = true,
  },
  factory = h.formatter_factory,
}

return M
