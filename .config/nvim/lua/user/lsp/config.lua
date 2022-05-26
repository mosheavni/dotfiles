local on_attaches = require 'user.lsp.on-attach'
local lsp_status = require 'lsp-status'
local default_on_attach = on_attaches.default
local minimal_on_attach = on_attaches.minimal
require 'user.lsp.null-ls'
local nvim_lsp = require 'lspconfig'
require('nvim-lsp-installer').setup {}
local lsp_installer = require 'nvim-lsp-installer.servers'

-- Set formatting of lsp log
require('vim.lsp.log').set_format_func(vim.inspect)

local function ensure_server(name)
  local _, server = lsp_installer.get_server(name)
  ---@diagnostic disable-next-line: undefined-field
  if not server:is_installed() then
    ---@diagnostic disable-next-line: undefined-field
    server:install()
  end
  return nvim_lsp[name]
end

-- Capabilities
local capabilities = vim.lsp.protocol.make_client_capabilities()
if lsp_status then
  capabilities = vim.tbl_deep_extend('keep', capabilities, lsp_status.capabilities)
end
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.codeAction = {
  dynamicRegistration = true,
  codeActionLiteralSupport = {
    codeActionKind = {
      valueSet = (function()
        local res = vim.tbl_values(vim.lsp.protocol.CodeActionKind)
        table.sort(res)
        return res
      end)(),
    },
  },
}
capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)

-- ansiblels
---@diagnostic disable-next-line: undefined-field
ensure_server('ansiblels').setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}
-- ansblel
---@diagnostic disable-next-line: undefined-field
ensure_server('awk_ls').setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}
-- bashls
---@diagnostic disable-next-line: undefined-field
ensure_server('bashls').setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}
-- dockerls
---@diagnostic disable-next-line: undefined-field
ensure_server('dockerls').setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}
-- eslint
---@diagnostic disable-next-line: undefined-field
ensure_server('eslint').setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}
-- groovyls
---@diagnostic disable-next-line: undefined-field
ensure_server('groovyls').setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}
-- html
---@diagnostic disable-next-line: undefined-field
ensure_server('html').setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}
-- json
local jsonls = ensure_server 'jsonls'
---@diagnostic disable-next-line: undefined-field
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
---@diagnostic disable-next-line: undefined-field
ensure_server('pyright').setup {
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
  runtime_path = true,
  lspconfig = {
    capabilities = capabilities,
    on_attach = default_on_attach,
  },
}
---@diagnostic disable-next-line: undefined-field
ensure_server('sumneko_lua').setup(luadev)
--terraformls
---@diagnostic disable-next-line: undefined-field
ensure_server('terraformls').setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
  cmd = {
    'terraform-ls',
    'serve',
    '-log-file=/tmp/terraform-ls-{{pid}}.log',
    [[-tf-log-file='/tmp/terraform-exec-1-{{args}}.log']],
  },
}
--tsserver
---@diagnostic disable-next-line: undefined-field
ensure_server('tsserver').setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}

--vimls
---@diagnostic disable-next-line: undefined-field
ensure_server('vimls').setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}

--jdtls
---@diagnostic disable-next-line: undefined-field
ensure_server('jdtls').setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}
-- yaml
local clock = os.clock
local yaml_install_path = vim.fn.expand '~' .. '/Repos/yaml-language-server'
if vim.fn.empty(vim.fn.glob(yaml_install_path)) > 0 then
  local function sleep(n) -- seconds
    local t0 = clock()
    while clock() - t0 <= n do
    end
  end
  vim.fn.execute('!git clone https://github.com/redhat-developer/yaml-language-server.git ' .. yaml_install_path)
  vim.fn.execute('!yarn install --cwd ' .. yaml_install_path)
  sleep(5)
  vim.fn.execute('!cd ' .. yaml_install_path .. ' && yarn run build')
end
---@diagnostic disable-next-line: undefined-field
ensure_server('yamlls').setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
  cmd = { 'node', yaml_install_path .. '/out/server/src/server.js', '--stdio' },
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
