local on_attaches = require 'plugins.lsp.on-attach'
local default_on_attach = on_attaches.default
local util = require 'lspconfig/util'
local path = util.path

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

local M = {
  -- ansiblels
  ansiblels = {
    on_attach = default_on_attach,
  },

  -- awk
  awk_ls = {
    on_attach = default_on_attach,
  },

  -- bashls
  bashls = {
    on_attach = default_on_attach,
  },

  -- cssls
  cssls = {
    on_attach = default_on_attach,
  },

  -- cssmodules_ls
  cssmodules_ls = {
    on_attach = default_on_attach,
  },

  -- dockerls
  dockerls = {
    on_attach = default_on_attach,
  },

  -- groovyls
  groovyls = {
    on_attach = default_on_attach,
  },

  -- html
  html = {
    on_attach = default_on_attach,
  },

  -- json
  jsonls = {
    on_attach = default_on_attach,
    settings = {
      json = {
        trace = {
          server = 'on',
        },
        schemas = require('schemastore').json.schemas(),
      },
    },
  },

  -- python

  pyright = {
    before_init = function(_, config)
      config.settings.python.pythonPath = get_python_path(config.root_dir)
    end,
    on_attach = default_on_attach,
    settings = {
      organizeimports = {
        provider = 'isort',
      },
    },
  },

  --lua
  --settings = {
  lua_ls = {
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
        workspace = {
          -- Make the server aware of Neovim runtime files
          library = vim.api.nvim_get_runtime_file('', true),
          checkThirdParty = false,
        },
        telemetry = { enable = false },
      },
    },
  },

  --terraformls
  terraformls = {
    on_attach = function(c, b)
      require('treesitter-terraform-doc').setup {}
      default_on_attach(c, b)
    end,
    cmd = { 'terraform-ls', 'serve', '-log-file=/tmp/terraform-ls-{{pid}}.log' },
  },

  --tsserver
  tsserver = {
    init_options = {
      preferences = {
        allowRenameOfImportPath = true,
        disableSuggestions = true,
        importModuleSpecifierEnding = 'auto',
        importModuleSpecifierPreference = 'non-relative',
        includeCompletionsForImportStatements = true,
        includeCompletionsForModuleExports = true,
        quotePreference = 'single',
      },
    },
    on_attach = default_on_attach,
  },

  --vimls
  vimls = {
    on_attach = default_on_attach,
  },

  --jdtls
  jdtls = {
    on_attach = default_on_attach,
  },

  --helm_ls
  helm_ls = {
    on_attach = default_on_attach,
  },

  --yamlls
  yamlls = {
    on_attach = function(c, b)
      local filetype = vim.api.nvim_buf_get_option(b, 'filetype')
      local buftype = vim.api.nvim_buf_get_option(b, 'buftype')
      local disabled_fts = { 'helm', 'yaml.gotexttmpl', 'gotmpl' }
      if buftype ~= '' or filetype == '' or vim.tbl_contains(disabled_fts, filetype) then
        vim.diagnostic.disable(b)
        vim.defer_fn(function()
          vim.diagnostic.reset(nil, b)
        end, 1000)
      end
      default_on_attach(c, b)
    end,
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

return M
