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
  local cmp_default_capabilities = require('cmp_nvim_lsp').default_capabilities()
  M.capabilities = vim.tbl_deep_extend('force', vim.lsp.protocol.make_client_capabilities(), cmp_default_capabilities, M.capabilities or {}, {})

  -- Diagnostics
  vim.diagnostic.config {
    jump = { float = true },
    signs = { text = M.diagnostic_signs },
    virtual_text = { severity = { min = vim.diagnostic.severity.WARN } },
    float = { border = 'rounded', source = 'if_many' },
  }

  require('mason-lspconfig').setup { automatic_installation = true }
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

      if client.server_capabilities.code_lens then
        vim.api.nvim_create_autocmd({ 'BufEnter', 'InsertLeave', 'InsertEnter' }, {
          desc = 'Auto show code lenses',
          group = on_attach_aug,
          buffer = bufnr,
          command = 'silent! lua vim.lsp.codelens.refresh({bufnr=' .. bufnr .. '})',
        })
      end
      -- if client.server_capabilities.document_highlight then
      --   -- Highlight text at cursor position
      --   vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
      --     desc = 'Highlight references to current symbol under cursor',
      --     group = on_attach_aug,
      --     buffer = bufnr,
      --     command = 'silent! lua vim.lsp.buf.document_highlight()',
      --   })
      -- end
    end,
  })
end

return M
