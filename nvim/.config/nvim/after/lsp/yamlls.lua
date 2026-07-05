-- Cached config (shared with helm_ls.lua)
if _G.yaml_lsp_config then
  return _G.yaml_lsp_config
end

vim.pack.add { 'https://github.com/b0o/SchemaStore.nvim' }

local yamlc_dev = vim.fn.expand '~/Repos/yaml-companion.nvim'
if vim.fn.isdirectory(yamlc_dev) == 1 then
  vim.opt.runtimepath:prepend(yamlc_dev)
else
  vim.pack.add { 'https://github.com/mosheavni/yaml-companion.nvim' }
end

local capabilities = vim.tbl_deep_extend('force', require('user.lsp.config').capabilities, {
  textDocument = {
    foldingRange = {
      dynamicRegistration = true,
    },
  },
})

local k8s_schemas = {
  {
    name = 'Kubernetes 1.29.9',
    uri = 'https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.29.9-standalone-strict/all.json',
  },
}

local yaml_lspconfig = {
  filetypes = {
    'yaml',
    'yaml.chart',
    'yaml.docker-compose',
    'yaml.ghaction',
    'yaml.gitlab',
    'yaml.helm-values',
    'yaml.precommit',
  },
  capabilities = capabilities,
  settings = {
    yaml = {
      kubernetesCRDStore = {
        enable = true,
      },
      format = {
        bracketSpacing = false,
      },
      schemas = require('schemastore').yaml.schemas(),
      schemaStore = {
        enable = false,
        url = '',
      },
    },
  },
}

local all_schemas = {}
vim.list_extend(all_schemas, k8s_schemas)
vim.list_extend(all_schemas, require('schemastore').json.schemas())

local yaml_cfg = require('yaml-companion').setup {
  modeline = {
    auto_add = {
      on_attach = true,
    },
  },
  -- Cluster CRD features
  cluster_crds = {
    enabled = false, -- Enable cluster CRD features
    fallback = true, -- Auto-fallback to cluster when Datree doesn't have schema
    auto_apply = 'modeline',
    cache_ttl = 86400, -- Cache expiration in seconds (default: 24h, 0 = never expire)
  },

  builtin_matchers = {
    kubernetes = { enabled = true },
  },
  schemas = all_schemas,
  lspconfig = yaml_lspconfig,
}

-- Cache for helm_ls.lua
_G.yaml_lsp_config = yaml_cfg

-- Menu actions
require('user.menu').add_actions('YAML', {
  ['Auto add CRD schema modelines'] = function()
    require('yaml-companion').add_crd_modelines()
  end,
})

return yaml_cfg
