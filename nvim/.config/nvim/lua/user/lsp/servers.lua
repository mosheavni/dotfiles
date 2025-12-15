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

  -- Custom hover for bashls with tldr integration
  vim.lsp.config('bashls', {
    on_attach = function(_, bufnr)
      -- Override K keymap for bashls to use custom hover
      vim.keymap.set('n', 'K', function()
        require('user.lsp.bashls-hover').hover()
      end, { buffer = bufnr, silent = true, desc = 'Hover with tldr' })
    end,
  })

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
      '.stylelua.toml',
      'stylua.toml',
      'stylelua.toml',
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
