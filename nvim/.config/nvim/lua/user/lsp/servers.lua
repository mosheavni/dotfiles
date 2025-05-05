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
    'gopls',
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
      },
    },
  })

  vim.lsp.config('terraformls', {
    on_attach = function(c)
      require('treesitter-terraform-doc').setup {}
      c.server_capabilities.semanticTokensProvider = {}
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
