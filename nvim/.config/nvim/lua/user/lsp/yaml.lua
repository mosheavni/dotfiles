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
  local yaml_lspconfig = {
    cmd = { 'yaml-language-server', '--stdio' },
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
  return yaml_cfg
end

return M
