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

  -- on attach
  local on_attach_aug = vim.api.nvim_create_augroup('UserLspAttach', { clear = true })
  vim.api.nvim_create_autocmd('LspAttach', {
    group = on_attach_aug,
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      local bufnr = ev.buf
      if client and client.server_capabilities.documentSymbolProvider then
        require('nvim-navic').attach(client, bufnr)
      end

      -- Mappings
      if vim.b[bufnr].lsp_keymaps_configured then
        return
      end
      vim.b[bufnr].lsp_keymaps_configured = true
      require 'user.lsp.keymaps'(bufnr)

      -- Diagnostics
      if vim.g.diagnostics_configured then
        return
      end
      vim.g.diagnostics_configured = true
      vim.diagnostic.config {
        severity_sort = true,
        signs = { text = M.diagnostic_signs },
        virtual_text = { current_line = false, severity = { min = vim.diagnostic.severity.WARN } },
        virtual_lines = { current_line = true },
        float = { border = 'rounded', source = true },
      }
    end,
  })

  -- for statusline
  local lsp_statusline_aug = vim.api.nvim_create_augroup('UserLspStatusline', { clear = true })
  vim.api.nvim_create_autocmd({ 'LspAttach', 'LspDetach' }, {
    group = lsp_statusline_aug,
    callback = function(ev)
      local bufnr = ev.buf
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return
        end
        vim.b[bufnr].attached_lsp = vim.tbl_map(function(client_l)
          return client_l.name
        end, vim.lsp.get_clients { bufnr = bufnr })
        vim.cmd 'redrawstatus'
      end)
    end,
  })

  require('user.lsp.actions').setup()
  require('user.lsp.servers').setup()
end

return M
