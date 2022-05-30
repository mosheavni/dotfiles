local M = {}

local path_hl_group = 'WinBarPath'
local modified_hl_group = 'WinBarModified'

vim.api.nvim_set_hl(0, path_hl_group, { bg = '#dedede', fg = '#363636' })
vim.api.nvim_set_hl(0, modified_hl_group, { bg = '#dedede', fg = '#ff3838' })

function M.eval()
  local file_path = vim.api.nvim_eval_statusline('%f', {}).str
  local modified = vim.api.nvim_eval_statusline('%M', {}).str == '+' and ' [+]' or ''

  file_path = file_path:gsub('/', ' ➤ ')

  return '%=%#' .. path_hl_group .. '#' .. file_path .. '%*' .. '%#' .. modified_hl_group .. '#' .. modified .. '%*'
end

return M
