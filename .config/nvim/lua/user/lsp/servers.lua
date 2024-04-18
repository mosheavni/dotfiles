local M = {}
M.setup = function()
  local on_attaches = require 'user.lsp.on-attach'
  local default_on_attach = on_attaches.default
  require('lspconfig')['ansiblels'].setup {
    on_attach = default_on_attach,
  }

  require('lspconfig')['bashls'].setup {
    on_attach = default_on_attach,
  }

  require('lspconfig')['cssls'].setup {
    on_attach = default_on_attach,
  }

  require('lspconfig')['cssmodules_ls'].setup {
    on_attach = default_on_attach,
  }

  require('lspconfig')['dockerls'].setup {
    on_attach = default_on_attach,
  }

  require('lspconfig')['docker_compose_language_service'].setup {
    on_attach = default_on_attach,
  }

  require('lspconfig')['groovyls'].setup {
    on_attach = default_on_attach,
  }

  require('lspconfig')['html'].setup {
    on_attach = default_on_attach,
  }

  require('lspconfig')['jsonls'].setup {
    on_attach = default_on_attach,
    settings = {
      json = {
        trace = {
          server = 'on',
        },
        schemas = require('schemastore').json.schemas(),
        validate = { enable = true },
      },
    },
  }

  require('lspconfig')['pyright'].setup {
    on_attach = default_on_attach,
    settings = {
      organizeimports = {
        provider = 'isort',
      },
    },
  }

  require('lspconfig')['lua_ls'].setup {
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
        -- workspace = {
        --   -- Make the server aware of Neovim runtime files
        --   library = {},
        --   checkThirdParty = false,
        -- },
        -- telemetry = { enable = false },
      },
    },
  }

  require('lspconfig')['terraformls'].setup {
    on_attach = function(c, b)
      require('treesitter-terraform-doc').setup {}
      default_on_attach(c, b)
      c.server_capabilities.semanticTokensProvider = {}
    end,
  }

  require('lspconfig')['tsserver'].setup {
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
  }

  require('lspconfig')['vimls'].setup {
    on_attach = default_on_attach,
  }

  require('lspconfig')['jdtls'].setup {
    on_attach = function(c, b)
      require('jdtls').setup_dap()
      default_on_attach(c, b)
    end,
    settings = {
      filetypes = { 'kotlin', 'java' },
      workspace = { checkThirdParty = false },
    },
  }

  require('lspconfig')['helm_ls'].setup {
    on_attach = default_on_attach,
  }

  local yaml_cfg = require('yaml-companion').setup {
    builtin_matchers = {
      -- Detects Kubernetes files based on content
      kubernetes = { enabled = true },
    },
    lspconfig = {
      on_attach = function(c, b)
        local filetype = vim.api.nvim_get_option_value('filetype', { buf = b })
        local buftype = vim.api.nvim_get_option_value('buftype', { buf = b })
        local disabled_fts = { 'helm', 'yaml.gotexttmpl', 'gotmpl' }
        if buftype ~= '' or filetype == '' or vim.tbl_contains(disabled_fts, filetype) then
          vim.diagnostic.disable(b)
          vim.defer_fn(function()
            vim.diagnostic.reset(nil, b)
          end, 1000)
        end
        default_on_attach(c, b)
      end,
    },
  }
  require('lspconfig')['yamlls'].setup(yaml_cfg)
end

return M
