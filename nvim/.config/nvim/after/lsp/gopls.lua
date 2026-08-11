-- Replaces what go.nvim used to provide: `gofumpt` styling (built into gopls,
-- so no gofumpt binary needed) and import organizing on save (the
-- `source.organizeImports` code action, which replaces the goimports binary).
-- Formatting itself goes through conform's `lsp_format = 'fallback'`, since
-- `go` is deliberately absent from its `formatters_by_ft`.
local function organize_imports(bufnr)
  local client = vim.lsp.get_clients({ bufnr = bufnr, name = 'gopls' })[1]
  if not client then
    return
  end
  local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
  ---@diagnostic disable-next-line: inject-field
  params.context = { only = { 'source.organizeImports' }, diagnostics = {} }
  local resp = client:request_sync('textDocument/codeAction', params, 1000, bufnr)
  for _, action in ipairs(resp and resp.result or {}) do
    if action.edit then
      vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
    end
  end
end

vim.api.nvim_create_autocmd('BufWritePre', {
  group = vim.api.nvim_create_augroup('GoOrganizeImports', { clear = true }),
  pattern = '*.go',
  callback = function(ev)
    organize_imports(ev.buf)
  end,
})

return {
  settings = {
    gopls = {
      gofumpt = true,
    },
  },
}
