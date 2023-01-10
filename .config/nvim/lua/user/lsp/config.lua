local on_attaches = require 'user.lsp.on-attach'
local default_on_attach = on_attaches.default
-- }
require('mason.settings').set {
  ui = {
    border = 'rounded',
  },
}
require('mason-lspconfig').setup {
  automatic_installation = true,
}
-- Set formatting of lsp log
require('vim.lsp.log').set_format_func(vim.inspect)

-- Capabilities
local capabilities = require('cmp_nvim_lsp').default_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.codeAction = {
  dynamicRegistration = true,
  codeActionLiteralSupport = {
    codeActionKind = {
      valueSet = (function()
        local res = vim.tbl_values(vim.lsp.protocol.CodeActionKind)
        table.sort(res)
        return res
      end)(),
    },
  },
}

-- general LSP config
-- show icons in the sidebar
local signs = {
  Error = '',
  Warn = ' ',
  Hint = ' ',
  Info = ' ',
}

for type, icon in pairs(signs) do
  local hl = 'DiagnosticSign' .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

-- LSPConfig after everything
local lspconfig = require 'lspconfig'
local util = require 'lspconfig/util'
local path = util.path

-- ansiblels
lspconfig.ansiblels.setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}

-- awk
lspconfig.awk_ls.setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}

-- bashls
lspconfig.bashls.setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}

-- cssls
lspconfig.cssls.setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}

-- cssmodules_ls
lspconfig.cssmodules_ls.setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}

-- dockerls
lspconfig.dockerls.setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}

-- groovyls
lspconfig.groovyls.setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}

-- html
lspconfig.html.setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}

-- json
lspconfig.jsonls.setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
  settings = {
    json = {
      trace = {
        server = 'on',
      },
      schemas = require('schemastore').json.schemas(),
    },
  },
}

-- python
local function get_python_path(workspace)
  -- Use activated virtualenv.
  if vim.env.VIRTUAL_ENV then
    return path.join(vim.env.VIRTUAL_ENV, 'bin', 'python')
  end

  -- Find and use virtualenv in workspace directory.
  for _, pattern in ipairs { '*', '.*' } do
    local match = vim.fn.glob(path.join(workspace, pattern, '.python-version'))
    if match ~= '' then
      return path.join(path.dirname(match), 'bin', 'python')
    end
  end

  -- Fallback to system Python.
  return exepath 'python3' or exepath 'python' or 'python'
end

lspconfig.pyright.setup {
  before_init = function(_, config)
    config.settings.python.pythonPath = get_python_path(config.root_dir)
  end,
  on_attach = default_on_attach,
  capabilities = capabilities,
  settings = {
    organizeimports = {
      provider = 'isort',
    },
  },
}

--lua
--settings = {
lspconfig.sumneko_lua.setup {
  capabilities = capabilities,
  on_attach = default_on_attach,
  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using (most likely LuaJIT)
        version = 'LuaJIT',
      },
      completion = {
        callSnippet = 'Replace',
      },
      hint = {
        enable = true,
      },
      diagnostics = {
        disable = { 'undefined-global' },
        globals = { 'vim' },
      },
      telemetry = { enable = false },
    },
  },
}

--terraformls
lspconfig.terraformls.setup {
  on_attach = function(c, b)
    require('treesitter-terraform-doc').setup()
    default_on_attach(c, b)
  end,
  capabilities = capabilities,
}

--tsserver
-- lspconfig.tsserver.setup {
--   on_attach = default_on_attach,
--   capabilities = capabilities,
-- }

require('typescript').setup {
  server = {
    init_options = {
      preferences = {
        allowRenameOfImportPath = true,
        importModuleSpecifierEnding = 'auto',
        importModuleSpecifierPreference = 'non-relative',
        includeCompletionsForImportStatements = true,
        includeCompletionsForModuleExports = true,
        quotePreference = 'single',
      },
    },
    on_attach = default_on_attach,
    capabilities = capabilities,
  },
}

--vimls
lspconfig.vimls.setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}

--jdtls
lspconfig.jdtls.setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}

-- yaml
local yaml_cfg = require('yaml-companion').setup {
  builtin_matchers = {
    -- Detects Kubernetes files based on content
    kubernetes = { enabled = true },
  },
  lspconfig = {
    on_attach = function(c, b)
      local filetype = vim.api.nvim_buf_get_option(b, 'filetype')
      local buftype = vim.api.nvim_buf_get_option(b, 'buftype')
      if buftype ~= '' or filetype == 'helm' or filetype == 'yaml.gotexttmpl' then
        vim.diagnostic.disable(b)
        vim.defer_fn(function()
          vim.diagnostic.reset(nil, b)
        end, 1000)
      end
      default_on_attach(c, b)
    end,
    capabilities = capabilities,
    settings = {
      redhat = { telemetry = { enabled = false } },
      yaml = {
        validate = true,
        format = { enable = true },
        hover = true,
        trace = { server = 'debug' },
        completion = true,
        schemaStore = {
          enable = true,
          url = 'https://www.schemastore.org/api/json/catalog.json',
        },
        schemas = {
          kubernetes = {
            '*role*.y*ml',
            'deploy.y*ml',
            'deployment.y*ml',
            'ingress.y*ml',
            'kubectl-edit-*',
            'pdb.y*ml',
            'pod.y*ml',
            'hpa.y*ml',
            'rbac.y*ml',
            'service.y*ml',
            'service*account.y*ml',
            'storageclass.y*ml',
            'svc.y*ml',
          },
        },
      },
    },
  },
}
lspconfig.yamlls.setup(yaml_cfg)
