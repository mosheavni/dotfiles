local on_attaches = require 'user.lsp.on-attach'
local default_on_attach = on_attaches.default
local util = require 'lspconfig/util'
local lspconfig = require 'lspconfig'
local path = util.path
require 'user.lsp.null-ls'

-- mason and lspconfig
require('mason').setup()
require('mason.settings').set {
  ui = {
    border = 'rounded',
  },
}
require('mason-lspconfig').setup {
  automatic_installation = true,
}

-- Set formatting of lsp log
require('vim.lsp.log').set_format_func(vim.inspect)

-- Capabilities
local capabilities = vim.lsp.protocol.make_client_capabilities()
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

-- ansiblels
---@diagnostic disable-next-line: undefined-field
lspconfig.ansiblels.setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}
-- ansblel
---@diagnostic disable-next-line: undefined-field
lspconfig.awk_ls.setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}
-- bashls
---@diagnostic disable-next-line: undefined-field
lspconfig.bashls.setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}
-- dockerls
---@diagnostic disable-next-line: undefined-field
lspconfig.dockerls.setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}
-- eslint
---@diagnostic disable-next-line: undefined-field
lspconfig.eslint.setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}
-- groovyls
---@diagnostic disable-next-line: undefined-field
lspconfig.groovyls.setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}
-- html
---@diagnostic disable-next-line: undefined-field
lspconfig.html.setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}
-- json
lspconfig.jsonls.setup {
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
local function get_python_path(workspace)
  -- Use activated virtualenv.
  if vim.env.VIRTUAL_ENV then
    return path.join(vim.env.VIRTUAL_ENV, 'bin', 'python')
  end

  -- Find and use virtualenv in workspace directory.
  for _, pattern in ipairs { '*', '.*' } do
    local match = vim.fn.glob(path.join(workspace, pattern, '.python-version'))
    if match ~= '' then
      return path.join(path.dirname(match), 'bin', 'python')
    end
  end

  -- Fallback to system Python.
  return exepath 'python3' or exepath 'python' or 'python'
end

---@diagnostic disable-next-line: undefined-field
lspconfig.pyright.setup {
  before_init = function(_, config)
    config.settings.python.pythonPath = get_python_path(config.root_dir)
  end,
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
    settings = {
      Lua = {
        hint = {
          enable = true,
        },
      },
    },
  },
}
---@diagnostic disable-next-line: undefined-field
lspconfig.sumneko_lua.setup(luadev)
--terraformls
---@diagnostic disable-next-line: undefined-field
lspconfig.terraformls.setup {
  on_attach = function(c, b)
    require('treesitter-terraform-doc').setup()
    default_on_attach(c, b)
  end,
  capabilities = capabilities,
}
--tsserver
---@diagnostic disable-next-line: undefined-field
lspconfig.tsserver.setup {
  capabilities = capabilities,
  -- Needed for inlayHints. Merge this table with your settings or copy
  init_options = require('nvim-lsp-ts-utils').init_options,
  on_attach = function(client, bufnr)
    local ts_utils = require 'nvim-lsp-ts-utils'

    -- defaults
    ts_utils.setup {
      debug = false,
      disable_commands = false,
      enable_import_on_completion = true,

      -- import all
      import_all_timeout = 5000, -- ms
      -- lower numbers = higher priority
      import_all_priorities = {
        same_file = 1, -- add to existing import statement
        local_files = 2, -- git files or files with relative path markers
        buffer_content = 3, -- loaded buffer content
        buffers = 4, -- loaded buffer names
      },
      import_all_scan_buffers = 100,
      import_all_select_source = false,
      -- if false will avoid organizing imports
      always_organize_imports = true,

      -- filter diagnostics
      filter_out_diagnostics_by_severity = {},
      filter_out_diagnostics_by_code = {},

      -- inlay hints
      auto_inlay_hints = true,
      inlay_hints_highlight = 'Comment',
      inlay_hints_priority = 200, -- priority of the hint extmarks
      inlay_hints_throttle = 150, -- throttle the inlay hint request
      inlay_hints_format = { -- format options for individual hint kind
        Type = {},
        Parameter = {},
        Enum = {},
        -- Example format customization for `Type` kind:
        -- Type = {
        --     highlight = "Comment",
        --     text = function(text)
        --         return "->" .. text:sub(2)
        --     end,
        -- },
      },

      -- update imports on file move
      update_imports_on_move = true,
      require_confirmation_on_move = false,
      watch_dir = nil,
      ebug = true,
    }

    -- required to fix code action ranges and filter diagnostics
    ts_utils.setup_client(client)

    -- no default maps, so you may want to define some here
    local opts = { silent = true }
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gs', ':TSLspOrganize<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gr', ':TSLspRenameFile<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gi', ':TSLspImportAll<CR>', opts)
    default_on_attach(client, bufnr)
  end,
}

--vimls
---@diagnostic disable-next-line: undefined-field
lspconfig.vimls.setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}

--jdtls
---@diagnostic disable-next-line: undefined-field
lspconfig.jdtls.setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
}
-- yaml
local yaml_cfg = require('yaml-companion').setup {
  builtin_matchers = {
    -- Detects Kubernetes files based on content
    kubernetes = { enabled = true },
  },
  lspconfig = {
    on_attach = function(c, b)
      if vim.bo[b].buftype ~= '' or vim.bo[b].filetype == 'helm' or vim.bo[b].filetype == 'yaml.gotexttmpl' then
        vim.diagnostic.disable(b)
        vim.defer_fn(function()
          vim.diagnostic.reset(nil, b)
        end, 1000)
      end
      default_on_attach(c, b)
    end,
    capabilities = capabilities,
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
            'hpa.y*ml',
            'rbac.y*ml',
            'service.y*ml',
            'service*account.y*ml',
            'storageclass.y*ml',
            'svc.y*ml',
          },
        },
      },
    },
  },
}
lspconfig.yamlls.setup(yaml_cfg)
