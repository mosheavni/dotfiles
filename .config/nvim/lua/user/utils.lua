local M = {}
M.autocmd = vim.api.nvim_create_autocmd

--Creates an augroup while clearing previous
--- @param name string #The name of the augroup.
M.augroup = function(name)
  return vim.api.nvim_create_augroup(name, { clear = true })
end
M.map_opts = {
  no_remap = { noremap = true },
  silent = { silent = true },
  no_remap_expr = { expr = true, noremap = true },
  no_remap_expr_silent = { expr = true, noremap = true, silent = true },
  no_remap_silent = { silent = true, noremap = true },
  remap = { noremap = false },
}

M.keymap = vim.keymap.set

return M
