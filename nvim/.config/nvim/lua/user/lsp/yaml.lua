local M = {
  k8s_schemas = {
    {
      name = 'Kubernetes 1.29.9',
      uri = 'https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.29.9-standalone-strict/all.json',
    },
  },
  all_schemas = {},
  yaml_cfg = {},
}

M.setup = function(opts)
  local capabilities = vim.tbl_deep_extend('force', opts.capabilities or require('user.lsp.config').capabilities, {
    textDocument = {
      foldingRange = {
        dynamicRegistration = true,
      },
    },
  })
  local yaml_lspconfig = {
    filetypes = {
      'yaml',
      'yaml.docker-compose',
      'yaml.gitlab',
      'yaml.helm-values',
      'yaml.ghaction',
    },

    capabilities = capabilities,

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
  local yaml_cfg = require('yaml-companion').setup {
    modeline = {
      auto_add = {
        on_attach = true,
      },
    },
    cluster_crds = {
      fallback = true, -- Auto-fallback to cluster when Datree fails
    },
    -- log_level = 'debug',
    builtin_matchers = {
      -- Detects Kubernetes files based on content
      kubernetes = { enabled = true },
    },
    schemas = M.all_schemas,
    lspconfig = yaml_lspconfig,
  }
  vim.lsp.config('yamlls', yaml_cfg)
  M.yaml_cfg = yaml_cfg

  -- add actions
  require('user.menu').add_actions('YAML', {
    ['Auto add CRD schema modelines'] = function()
      require('yaml-companion').add_crd_modelines()
    end,
  })

  return yaml_cfg
end

return M
