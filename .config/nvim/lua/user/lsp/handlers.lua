-- Jump directly to the first available definition every time.
vim.lsp.handlers['textDocument/definition'] = function(_, result)
  if not result or vim.tbl_isempty(result) then
    print '[LSP] Could not find definition'
    return
  end

  if vim.tbl_islist(result) then
    vim.lsp.util.jump_to_location(result[1], 'utf-8')
  else
    vim.lsp.util.jump_to_location(result, 'utf-8')
  end
end

vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
  update_in_insert = true,
  virtual_text = false,
  signs = true,
  underline = true,
})

local border = {
  '╔',
  '═',
  '╗',
  '║',
  '╝',
  '═',
  '╚',
  '║',
}

-- vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, {
--   -- border = 'rounded'
--   border = border,
-- })

-- vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, {
--   -- border = 'rounded'
--   border = border,
-- })

-- vim.lsp.handlers['window/showMessage'] = function(_, result, ctx)
--   local client = vim.lsp.get_client_by_id(ctx.client_id)
--   local lvl = ({
--     'ERROR',
--     'WARN',
--     'INFO',
--     'DEBUG',
--   })[result.type]
--   vim.notify({ result.message }, lvl, {
--     title = 'LSP | ' .. client.name,
--     timeout = 10000,
--     keep = function()
--       return lvl == 'ERROR' or lvl == 'WARN'
--     end,
--   })
-- end
