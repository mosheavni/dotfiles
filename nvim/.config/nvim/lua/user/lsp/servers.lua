local M = {}
M.setup = function()
  local capabilities = require('user.lsp.config').capabilities
  local lspconfig = require 'lspconfig'

  lspconfig['bashls'].setup { capabilities = capabilities }
  lspconfig['cssls'].setup { capabilities = capabilities }
  lspconfig['cssmodules_ls'].setup { capabilities = capabilities }
  lspconfig['dockerls'].setup { capabilities = capabilities }
  lspconfig['vtsls'].setup { capabilities = capabilities }
  lspconfig['docker_compose_language_service'].setup { capabilities = capabilities }
  lspconfig['groovyls'].setup { capabilities = capabilities }
  lspconfig['html'].setup { capabilities = capabilities }
  lspconfig['vimls'].setup { capabilities = capabilities }
  lspconfig['taplo'].setup { capabilities = capabilities }
  lspconfig['jsonls'].setup {
    capabilities = capabilities,
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

  lspconfig['pyright'].setup {
    capabilities = capabilities,
    settings = {
      organizeimports = {
        provider = 'isort',
      },
    },
  }

  lspconfig['lua_ls'].setup {
    capabilities = capabilities,
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

  lspconfig['terraformls'].setup {
    on_attach = function(c)
      require('treesitter-terraform-doc').setup {}
      c.server_capabilities.semanticTokensProvider = {}
      vim.o.commentstring = '# %s'
    end,
    capabilities = capabilities,
  }

  local yaml_cfg = require('user.lsp.yaml').setup { capabilities = capabilities }

  lspconfig['helm_ls'].setup {
    capabilities = capabilities,
    filetypes = { 'helm', 'gotmpl' },
    settings = {
      yamlls = {
        config = yaml_cfg.settings,
      },
    },
  }
end

return M
