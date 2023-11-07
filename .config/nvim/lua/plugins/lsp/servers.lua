local on_attaches = require 'plugins.lsp.on-attach'
local default_on_attach = on_attaches.default

local M = {
  ansiblels = {
    on_attach = default_on_attach,
  },

  awk_ls = {
    on_attach = default_on_attach,
  },

  bashls = {
    on_attach = default_on_attach,
  },

  cssls = {
    on_attach = default_on_attach,
  },

  cssmodules_ls = {
    on_attach = default_on_attach,
  },

  dockerls = {
    on_attach = default_on_attach,
  },

  docker_compose_language_service = {
    on_attach = default_on_attach,
  },

  groovyls = {
    on_attach = default_on_attach,
  },

  html = {
    on_attach = default_on_attach,
  },

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

  pyright = {
    on_attach = default_on_attach,
    settings = {
      organizeimports = {
        provider = 'isort',
      },
    },
  },

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
          library = {},
          checkThirdParty = false,
        },
        telemetry = { enable = false },
      },
    },
  },

  terraformls = {
    on_attach = function(c, b)
      require('treesitter-terraform-doc').setup {}
      default_on_attach(c, b)
      c.server_capabilities.semanticTokensProvider = nil
    end,
  },

  tsserver = {
    settings = {
      preferences = {
        allowRenameOfImportPath = true,
        disableSuggestions = false,
        importModuleSpecifierEnding = 'auto',
        importModuleSpecifierPreference = 'non-relative',
        includeCompletionsForImportStatements = true,
        includeCompletionsForModuleExports = true,
        quotePreference = 'single',
      },
      -- specify some or all of the following settings if you want to adjust the default behavior
      javascript = {
        inlayHints = {
          includeInlayEnumMemberValueHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayParameterNameHints = 'all', -- 'none' | 'literals' | 'all';
          includeInlayParameterNameHintsWhenArgumentMatchesName = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayVariableTypeHints = true,
        },
      },
      typescript = {
        inlayHints = {
          includeInlayEnumMemberValueHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayParameterNameHints = 'all', -- 'none' | 'literals' | 'all';
          includeInlayParameterNameHintsWhenArgumentMatchesName = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayVariableTypeHints = true,
        },
      },
    },
    on_attach = default_on_attach,
  },

  vimls = {
    on_attach = default_on_attach,
  },

  jdtls = {
    on_attach = function(c, b)
      require('jdtls.setup').add_commands()
      require('jdtls').setup_dap()
      require('lsp-status').register_progress()
      default_on_attach(c, b)
    end,
    settings = {
      filetypes = { 'kotlin', 'java' },
      workspace = { checkThirdParty = false },
    },
  },

  helm_ls = {
    on_attach = default_on_attach,
  },

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
