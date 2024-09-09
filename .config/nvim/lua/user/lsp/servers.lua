local M = {}
M.setup = function()
  local on_attaches = require 'user.lsp.on-attach'
  local default_on_attach = on_attaches.default
  local capabilities = require('user.lsp.config').capabilities

  require('lspconfig')['bashls'].setup {
    on_attach = default_on_attach,
    capabilities = capabilities,
  }

  require('lspconfig')['cssls'].setup {
    on_attach = default_on_attach,
    capabilities = capabilities,
  }

  require('lspconfig')['cssmodules_ls'].setup {
    on_attach = default_on_attach,
    capabilities = capabilities,
  }

  require('lspconfig')['dockerls'].setup {
    on_attach = default_on_attach,
    capabilities = capabilities,
  }

  require('lspconfig')['docker_compose_language_service'].setup {
    on_attach = default_on_attach,
    capabilities = capabilities,
  }

  require('lspconfig')['groovyls'].setup {
    on_attach = default_on_attach,
    capabilities = capabilities,
  }

  require('lspconfig')['html'].setup {
    on_attach = default_on_attach,
    capabilities = capabilities,
  }

  require('lspconfig')['jsonls'].setup {
    on_attach = default_on_attach,
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

  require('lspconfig')['pyright'].setup {
    on_attach = default_on_attach,
    capabilities = capabilities,
    settings = {
      organizeimports = {
        provider = 'isort',
      },
    },
  }

  require('lspconfig')['lua_ls'].setup {
    on_attach = default_on_attach,
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

  require('lspconfig')['terraformls'].setup {
    on_attach = function(c, b)
      require('treesitter-terraform-doc').setup {}
      default_on_attach(c, b)
      c.server_capabilities.semanticTokensProvider = {}
      vim.o.commentstring = '# %s'
    end,
    capabilities = capabilities,
  }

  require('lspconfig')['vimls'].setup {
    on_attach = default_on_attach,
    capabilities = capabilities,
  }

  require('lspconfig')['taplo'].setup {
    on_attach = default_on_attach,
    capabilities = capabilities,
  }

  require('lspconfig')['helm_ls'].setup {
    on_attach = default_on_attach,
    capabilities = capabilities,
    filetypes = { 'helm', 'gotmpl' },
  }

  require('user.lsp.yaml').setup {
    capabilities = capabilities,
    on_attach = default_on_attach,
  }

  -- golang
  require('lspconfig').gopls.setup {
    capabilities = capabilities,
    on_attach = default_on_attach,
  }
end

return M
