local M = {}
M.autocmd = vim.api.nvim_create_autocmd
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

M.keymap = vim.api.nvim_set_keymap
M.buf_keymap = vim.api.nvim_buf_set_keymap

return M
