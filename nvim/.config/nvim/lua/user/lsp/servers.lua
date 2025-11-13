local M = {}
M.setup = function()
  local capabilities = require('user.lsp.config').capabilities

  vim.lsp.config('*', { capabilities = capabilities })
  vim.lsp.enable {
    'bashls',
    'cssls',
    'cssmodules_ls',
    'docker_compose_language_service',
    'dockerls',
    'golangci_lint_ls',
    'groovyls',
    'helm_ls',
    'html',
    'jinja_lsp',
    'jsonls',
    'lua_ls',
    'pyright',
    'taplo',
    'terraformls',
    'vimls',
    'vtsls',
    'yamlls',
  }

  vim.lsp.config('jsonls', {
    settings = {
      json = {
        trace = {
          server = 'on',
        },
        schemas = require('schemastore').json.schemas(),
        validate = { enable = true },
      },
    },
  })

  vim.lsp.config('pyright', {
    settings = {
      organizeimports = {
        provider = 'isort',
      },
    },
  })

  vim.lsp.config('lua_ls', {
    root_markers = {
      '.luarc.json',
      '.luarc.jsonc',
      '.luacheckrc',
      '.stylua.toml',
      'stylua.toml',
      'selene.toml',
      'selene.yml',
    },

    settings = {
      Lua = {
        runtime = { version = 'LuaJIT' },
        completion = { callSnippet = 'Replace' },
        hint = { enable = true },
        diagnostics = {
          disable = { 'undefined-global' },
          globals = { 'vim' },
        },
      },
    },
  })

  vim.lsp.config('terraformls', {
    on_attach = function(c)
      require('treesitter-terraform-doc').setup {}
      -- c.server_capabilities.semanticTokensProvider = {}
      vim.o.commentstring = '# %s'
    end,
  })

  -- local yaml_cfg = {
  --   yaml = {
  --     format = {
  --       bracketSpacing = false,
  --     },
  --     -- schemas = require('schemastore').yaml.schemas(),
  --     -- schemas = vim.tbl_deep_extend('force', { [require('kubernetes').yamlls_schema()] = '*.yaml' }, require('schemastore').yaml.schemas()),
  --     schemaStore = {
  --       -- Must disable built-in schemaStore support to use
  --       -- schemas from SchemaStore.nvim plugin
  --       enable = false,
  --       -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
  --       url = '',
  --     },
  --     schemas = {},
  --   },
  -- }
  -- vim.lsp.config('yamlls', {
  --   capabilities = vim.tbl_deep_extend('force', capabilities, {
  --     textDocument = {
  --       foldingRange = {
  --         dynamicRegistration = true,
  --       },
  --     },
  --   }),
  -- })

  local yaml_cfg = require('user.lsp.yaml').setup { capabilities = capabilities }

  vim.lsp.config('helm_ls', {
    filetypes = { 'helm', 'gotmpl' },
    settings = {
      yamlls = {
        config = yaml_cfg.settings,
      },
    },
  })
end

return M
