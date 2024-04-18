local M = {
  capabilities = {
    textDocument = {
      completion = {
        completionItem = {
          snippetSupport = true,
        },
      },
      -- codeAction = {
      --   dynamicRegistration = true,
      --   codeActionLiteralSupport = {
      --     codeActionKind = {
      --       valueSet = (function()
      --         local res = vim.tbl_values(vim.lsp.protocol.CodeActionKind)
      --         table.sort(res)
      --         return res
      --       end)(),
      --     },
      --   },
      -- },
      foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      },
    },
  },
  all_mason_lsp_servers = {},
}

M.setup_capabilities = function()
  ------------------
  -- Capabilities --
  ------------------
  M.capabilities = vim.tbl_deep_extend(
    'force',
    {},
    vim.lsp.protocol.make_client_capabilities(),
    -- TODO: fix cmp capabilities
    has_cmp and cmp_nvim_lsp.default_capabilities() or {},
    M.capabilities or {}
  )
end

M.diagnostics = function()
  -----------------
  -- Diagnostics --
  -----------------
  -- show icons in the sidebar
  local signs = {
    [vim.diagnostic.severity.ERROR] = '✘',
    [vim.diagnostic.severity.WARN] = '',
    [vim.diagnostic.severity.HINT] = ' ',
    [vim.diagnostic.severity.INFO] = ' ',
  }
  vim.diagnostic.config {
    signs = { text = signs },
    update_in_insert = false,
    virtual_text = {
      severity = { min = vim.diagnostic.severity.WARN },
    },
    float = { border = require('user.utils').float_border },
  }
end

M.get_mason_lspconfig = function()
  local have_mason, _ = pcall(require, 'mason-lspconfig')
  if have_mason then
    M.all_mason_lsp_servers = vim.tbl_keys(require('mason-lspconfig.mappings.server').lspconfig_to_package)
  end
end

M.init = function()
  local start_ls = function()
    _G.tmp_write { should_delete = false, new = false }
    -- load lsp
    require 'lspconfig'
  end
  vim.keymap.set('n', '<leader>ls', start_ls)
  require('user.menu').add_actions('LSP', {
    ['Start LSP (<leader>ls)'] = function()
      start_ls()
    end,
  })
end

M.setup = function()
  require('user.lsp.actions').setup()
  require('user.lsp.handlers').setup()

  -- set lsp window border style
  require('lspconfig.ui.windows').default_options.border = require('user.utils').borders.single_rounded

  -- Set formatting of lsp log
  require('vim.lsp.log').set_format_func(vim.inspect)

  -- set up capabilities
  M.setup_capabilities()

  -- set up diagnostics configuration
  M.diagnostics()

  -- get all the servers that are available thourgh mason-lspconfig
  M.get_mason_lspconfig()

  -- setup lsp servers
  require('user.lsp.servers').setup()
end

return M
