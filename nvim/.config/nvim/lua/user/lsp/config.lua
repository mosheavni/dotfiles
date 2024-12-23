local M = {
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

M.setup_capabilities = function()
  ------------------
  -- Capabilities --
  ------------------
  local cmp_default_capabilities = require('cmp_nvim_lsp').default_capabilities()
  -- local cmp_default_capabilities = require('blink.cmp').get_lsp_capabilities()

  M.capabilities = vim.tbl_deep_extend('force', vim.lsp.protocol.make_client_capabilities(), cmp_default_capabilities, M.capabilities or {}, {})
end

M.diagnostic_signs = {
  [vim.diagnostic.severity.ERROR] = '✘',
  [vim.diagnostic.severity.WARN] = '',
  [vim.diagnostic.severity.HINT] = ' ',
  [vim.diagnostic.severity.INFO] = ' ',
}

M.diagnostics = function()
  -----------------
  -- Diagnostics --
  -----------------
  -- show icons in the sidebar
  vim.diagnostic.config {
    jump = { float = true },
    signs = { text = M.diagnostic_signs },
    update_in_insert = false,
    virtual_text = {
      severity = { min = vim.diagnostic.severity.WARN },
    },
    float = { border = 'rounded' },
  }
end

M.init = function()
  _G.start_ls = function()
    local ft = vim.api.nvim_get_option_value('filetype', { buf = 0 })
    local file_name = _G.tmp_write { should_delete = false, new = false, ft = ft }
    -- load lsp
    require 'lspconfig'
    return file_name
  end
  vim.keymap.set('n', '<leader>ls', _G.start_ls)
  require('user.menu').add_actions('LSP', {
    ['Start LSP (<leader>ls)'] = function()
      _G.start_ls()
    end,
  })
end

M.setup = function()
  require('user.lsp.actions').setup()

  -- Set formatting of lsp log
  require('vim.lsp.log').set_format_func(vim.inspect)

  -- set up capabilities
  M.setup_capabilities()

  -- set up diagnostics configuration
  M.diagnostics()

  -- set up mason to install lsp servers
  require('mason-lspconfig').setup { automatic_installation = true }

  -- setup lsp servers
  require('user.lsp.servers').setup()
end

return M
