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
      '.git',
      '.luarc.json',
      '.luarc.jsonc',
      '.luacheckrc',
      '.stylua.toml',
      '.stylelua.toml',
      'stylua.toml',
      'stylelua.toml',
      'selene.toml',
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
        workspace = {
          library = {
            vim.env.VIMRUNTIME,
            '${3rd}/luv/library',
            '${3rd}/busted/library',
          },
          checkThirdParty = false,
        },
        telemetry = { enable = false },
      },
    },
  })

  vim.lsp.config('terraformls', {
    on_attach = function()
      require('user.terraform-docs').setup {}
      -- c.server_capabilities.semanticTokensProvider = {}
      vim.o.commentstring = '# %s'
    end,
  })

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
