-- Jump directly to the first available definition every time.
vim.lsp.handlers["textDocument/definition"] = function(_, result)
  if not result or vim.tbl_isempty(result) then
    print "[LSP] Could not find definition"
    return
  end

  if vim.tbl_islist(result) then
    vim.lsp.util.jump_to_location(result[1], "utf-8")
  else
    vim.lsp.util.jump_to_location(result, "utf-8")
  end
end

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.handlers["textDocument/publishDiagnostics"], {
  signs = {
    severity_limit = "Error",
  },
  underline = {
    severity_limit = "Warning",
  },
  virtual_text = true,
})

vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
  underline = true,
  update_in_insert = true,
  virtual_text = false,
  signs = true,
})

local severity = {
  "error",
  "warn",
  "info",
  "info", -- map both hint and info to info?
}
vim.lsp.handlers["window/showMessage"] = function(_, method, params, _)
  vim.notify(method.message, severity[params.type])
end
