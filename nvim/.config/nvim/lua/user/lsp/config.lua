local M = {
  diagnostic_signs = {
    [vim.diagnostic.severity.ERROR] = '✘',
    [vim.diagnostic.severity.WARN] = '',
    [vim.diagnostic.severity.HINT] = ' ',
    [vim.diagnostic.severity.INFO] = ' ',
  },
  capabilities = {
    textDocument = {
      completion = {
        completionItem = {
          snippetSupport = true,
        },
      },
      foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      },
    },
  },
}

M.setup = function()
  require('user.lsp.actions').setup()
  require('vim.lsp.log').set_format_func(vim.inspect)
  M.capabilities =
    vim.tbl_deep_extend('force', vim.lsp.protocol.make_client_capabilities(), require('cmp_nvim_lsp').default_capabilities(), M.capabilities or {}, {})

  -- Diagnostics
  vim.diagnostic.config {
    jump = { float = true },
    signs = { text = M.diagnostic_signs },
    virtual_text = { severity = { min = vim.diagnostic.severity.WARN } },
    virtual_lines = { current_line = true },
    float = { border = 'rounded', source = 'if_many' },
  }

  ---@diagnostic disable-next-line: missing-fields
  require('user.lsp.servers').setup()

  -- on attach
  local on_attach_aug = vim.api.nvim_create_augroup('UserLspAttach', { clear = true })
  vim.api.nvim_create_autocmd('LspAttach', {
    group = on_attach_aug,
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      local bufnr = ev.buf
      require 'user.lsp.keymaps'(bufnr)
      if client and client.server_capabilities.documentSymbolProvider then
        require('nvim-navic').attach(client, bufnr)
      end
    end,
  })
end

return M
