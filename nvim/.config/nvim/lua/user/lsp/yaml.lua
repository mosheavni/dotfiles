local M = {
  k8s_schemas = {
    {
      name = 'Kubernetes 1.29.9',
      uri = 'https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.29.9-standalone-strict/all.json',
    },
  },
  all_schemas = {},
}

M.setup = function(opts)
  local capabilities = opts.capabilities or require('user.lsp.config').capabilities
  local on_attach = opts.on_attach or require('user.lsp.on-attach').default
  local yaml_lspconfig = {
    cmd = { 'yaml-language-server', '--stdio' },
    on_attach = function(c, b)
      local filetype = vim.api.nvim_get_option_value('filetype', { buf = b })
      local buftype = vim.api.nvim_get_option_value('buftype', { buf = b })
      local disabled_fts = { 'helm', 'yaml.gotexttmpl', 'gotmpl' }
      if buftype ~= '' or filetype == '' or vim.tbl_contains(disabled_fts, filetype) then
        vim.diagnostic.enable(false, b)
        vim.defer_fn(function()
          vim.diagnostic.reset(nil, b)
        end, 1000)
      end
      on_attach(c, b)
    end,
    capabilities = vim.tbl_deep_extend('force', capabilities, {
      textDocument = {
        foldingRange = {
          dynamicRegistration = true,
        },
      },
    }),
    settings = {
      yaml = {
        format = {
          bracketSpacing = false,
        },
        schemas = require('schemastore').yaml.schemas(),
        schemaStore = {
          -- Must disable built-in schemaStore support to use
          -- schemas from SchemaStore.nvim plugin
          enable = false,
          -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
          url = '',
        },
      },
    },
  }
  -- Merge the lists
  vim.list_extend(M.all_schemas, M.k8s_schemas)
  vim.list_extend(M.all_schemas, require('schemastore').json.schemas())
  -- vim.list_extend(M.all_schemas, require('user.additional-schemas').crds_as_schemas())
  local yaml_cfg = require('yaml-companion').setup {
    builtin_matchers = {
      -- Detects Kubernetes files based on content
      kubernetes = { enabled = true },
    },
    schemas = M.all_schemas,
    lspconfig = yaml_lspconfig,
  }
  require('lspconfig')['yamlls'].setup(yaml_cfg)
end

return M
