local default_on_attach = require 'user.lsp.on-attach'
require 'user.lsp.null-ls'
-- require('lsp_signature').setup {}
local util = require 'lspconfig.util'
local lsp_installer = require 'nvim-lsp-installer.servers'

-- Set formatting of lsp log
require('vim.lsp.log').set_format_func(vim.inspect)

local function ensure_server(name)
  local _, server = lsp_installer.get_server(name)
  if not server:is_installed() then
    server:install()
  end
  return server
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)

-- ansiblels
ensure_server('ansiblels'):setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}
-- ansblel
ensure_server('awk_ls'):setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}
-- bashls
ensure_server('bashls'):setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}
-- dockerls
ensure_server('dockerls'):setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}
-- eslint
ensure_server('eslint'):setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}
-- groovyls
ensure_server('groovyls'):setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}
-- html
ensure_server('html'):setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}
-- json
local jsonls = ensure_server 'jsonls'
jsonls:setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
  settings = {
    json = {
      trace = {
        server = 'on',
      },
      schemas = require('schemastore').json.schemas(),
    },
  },
}
-- python
ensure_server('pyright'):setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
  settings = {
    organizeimports = {
      provider = 'isort',
    },
  },
}
--lua
local luadev = require('lua-dev').setup {
  lspconfig = {
    on_attach = default_on_attach,
    settings = {
      Lua = {
        format = { enable = false },
        diagnostics = {
          globals = { 'vim' },
        },
        workspace = {
          -- library = vim.api.nvim_get_runtime_file('', true),
          library = {
            ['$VIMRUNTIME'] = true,
            -- add your config
            ['~/.config/nvim'] = true,
            -- add plugins
            ['~/.local/share/nvim/site/pack/packer/opt/*'] = true,
            ['~/.local/share/nvim/site/pack/packer/start/*'] = true,
          },
        },
      },
    },
  },
}
ensure_server('sumneko_lua'):setup(luadev)
--terraformls
ensure_server('terraformls'):setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
  root_dir = util.root_pattern '.terraform',
}
--tsserver
ensure_server('tsserver'):setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}

--vimls
ensure_server('vimls'):setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}

--jdtls
ensure_server('jdtls'):setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}
-- yaml
ensure_server('yamlls'):setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
  cmd = { 'node', '/Users/mavni/Repos/yaml-language-server/out/server/src/server.js', '--stdio' },
  on_init = function()
    require('user.select-schema').get_client()
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
          'rbac.y*ml',
          'service.y*ml',
          'service*account.y*ml',
          'storageclass.y*ml',
          'svc.y*ml',
        },
      },
    },
  },
}

-- general LSP config
-- show icons in the sidebar
local signs = {
  Error = ' ',
  Warn = ' ',
  Hint = ' ',
  Info = '',
}

for type, icon in pairs(signs) do
  local hl = 'DiagnosticSign' .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end
