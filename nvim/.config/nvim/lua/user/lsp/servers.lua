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
    'user_lsp',
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
      '.luacheckrc',
      '.stylua.toml',
      'stylua.toml',
      'selene.toml',
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
