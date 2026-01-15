-- Cached config (shared with helm_ls.lua)
if _G.yaml_lsp_config then
  return _G.yaml_lsp_config
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
    'yaml.docker-compose',
    'yaml.gitlab',
    'yaml.helm-values',
    'yaml.ghaction',
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
  cluster_crds = {
    fallback = true,
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
