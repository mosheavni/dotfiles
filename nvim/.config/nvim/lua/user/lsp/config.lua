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

M.init = function()
  _G.start_ls = function(with_file)
    local file_name = nil
    if with_file == true then
      local ft = vim.api.nvim_get_option_value('filetype', { buf = 0 })
      file_name = _G.tmp_write { should_delete = false, new = false, ft = ft }
    end
    -- load lsp
    require 'lspconfig'
    return file_name
  end
  vim.keymap.set('n', '<leader>ls', function()
    _G.start_ls(false)
  end)
  vim.keymap.set('n', '<leader>lS', function()
    _G.start_ls(true)
  end)
  require('user.menu').add_actions('LSP', {
    ['Start LSP (<leader>ls)'] = function()
      _G.start_ls()
    end,
  })
end

M.setup = function()
  require('user.lsp.actions').setup()
  require('vim.lsp.log').set_format_func(vim.inspect)
  M.capabilities =
    vim.tbl_deep_extend('force', vim.lsp.protocol.make_client_capabilities(), require('cmp_nvim_lsp').default_capabilities(), M.capabilities or {}, {})

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

      -- Diagnostics
      if vim.g.dignostics_configured then
        return
      end
      vim.g.dignostics_configured = true
      vim.diagnostic.config {
        -- jump = {on_jump = { float = true }},
        signs = { text = M.diagnostic_signs },
        virtual_text = { severity = { min = vim.diagnostic.severity.WARN } },
        virtual_lines = { current_line = true },
        float = { border = 'rounded', source = 'if_many' },
      }
    end,
  })
end

return M
