local actions = function()
  return {
    ['Format (<leader>lp)'] = function()
      require('user.lsp.formatting').format()
    end,
    ['Code Actions (<leader>la)'] = function()
      vim.lsp.buf.code_action()
    end,
    ['Code Lens (<leader>lx)'] = function()
      vim.lsp.codelens.run()
    end,
    ['Show Definition (gd)'] = function()
      vim.cmd 'Lspsaga peek_definition'
    end,
    ['Show Declaration (gD)'] = function()
      vim.lsp.buf.declaration()
    end,
    ['Show Type Definition (gy)'] = function()
      vim.lsp.buf.type_definition()
    end,
    ['Show Implementation (gi)'] = function()
      vim.lsp.buf.implementation()
    end,
    ['Find References (gr)'] = function()
      vim.cmd 'Lspsaga finder'
    end,
    ['Signature Help (<leader>lk)'] = function()
      vim.lsp.buf.signature_help()
    end,
    ['Signature Documentation (K)'] = function()
      -- vim.lsp.buf.hover()
      vim.cmd 'Lspsaga hover_doc'
    end,
    ['Rename symbol (<leader>lrn)'] = function()
      vim.cmd 'Lspsaga rename ++project'
    end,
    ['Diagnostics quickfix list (<leader>lq)'] = function()
      vim.diagnostic.setqflist()
    end,
    ['Clear Diagnostics'] = function()
      vim.diagnostic.reset()
    end,
    ['Delete Log'] = function()
      vim.fn.system { 'rm', '-rf', vim.lsp.get_log_path() }
    end,
    ['Add YAML Schema Modeline'] = function()
      require('user.additional-schemas').init()
    end,
  }
end

local M = {
  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },
  opts = {
    inlay_hints = { enabled = true },
    capabilities = {
      textDocument = {
        completion = {
          completionItem = {
            snippetSupport = true,
          },
        },
        -- codeAction = {
        --   dynamicRegistration = true,
        --   codeActionLiteralSupport = {
        --     codeActionKind = {
        --       valueSet = (function()
        --         local res = vim.tbl_values(vim.lsp.protocol.CodeActionKind)
        --         table.sort(res)
        --         return res
        --       end)(),
        --     },
        --   },
        -- },
        foldingRange = {
          dynamicRegistration = false,
          lineFoldingOnly = true,
        },
      },
    },
    setup = {
      tsserver = function(_, opts)
        require('typescript').setup {
          server = opts,
        }
        return true
      end,

      yamlls = function(_, opts)
        local yaml_cfg = require('yaml-companion').setup {
          schemas = opts.settings.yaml.schemas or {},
          builtin_matchers = {
            -- Detects Kubernetes files based on content
            kubernetes = { enabled = true },
          },
          lspconfig = opts,
        }
        require('lspconfig')['yamlls'].setup(yaml_cfg)
        return true
      end,

      helm_ls = function()
        local configs = require 'lspconfig.configs'
        local util = require 'lspconfig.util'

        if not configs.helm_ls then
          configs.helm_ls = {
            default_config = {
              cmd = { 'helm_ls', 'serve' },
              filetypes = { 'helm', 'gotmpl' },
              root_dir = function(fname)
                return util.root_pattern 'Chart.yaml'(fname)
              end,
            },
          }
        end
      end,
      docker_compose_language_service = function() end,
    },
  },
}

M.init = function()
  vim.keymap.set('n', '<leader>ls', function()
    _G.tmp_write { should_delete = false, new = false }
    -- load lsp
    require 'lspconfig'
  end)
end

M.config = function(_, opts)
  require('user.menu').add_actions('LSP', actions())
  require('user.lsp.handlers').setup()

  -- Set formatting of lsp log
  require('vim.lsp.log').set_format_func(vim.inspect)

  -- general LSP config
  -- show icons in the sidebar
  local signs = {
    Error = '',
    Warn = ' ',
    Hint = ' ',
    Info = ' ',
  }

  for type, icon in pairs(signs) do
    local hl = 'DiagnosticSign' .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
  end

  local servers = require 'user.lsp.servers'
  ------------------
  -- Capabilities --
  ------------------
  local capabilities = vim.tbl_deep_extend(
    'force',
    {},
    vim.lsp.protocol.make_client_capabilities(),
    has_cmp and cmp_nvim_lsp.default_capabilities() or {},
    opts.capabilities or {}
  )

  -----------------
  -- Diagnostics --
  -----------------
  vim.diagnostic.config {
    update_in_insert = false,
    -- underline = {
    --   severity = { max = vim.diagnostic.severity.INFO },
    -- },
    virtual_text = {
      severity = { min = vim.diagnostic.severity.WARN },
    },
    float = { border = require('user.utils').float_border },
  }

  local function setup(server)
    local server_opts = vim.tbl_deep_extend('force', {
      capabilities = vim.deepcopy(capabilities),
    }, servers[server] or {})

    if opts.setup[server] then
      if opts.setup[server](server, server_opts) then
        return
      end
    elseif opts.setup['*'] then
      if opts.setup['*'](server, server_opts) then
        return
      end
    end
    require('lspconfig')[server].setup(server_opts)
  end

  -- get all the servers that are available thourgh mason-lspconfig
  local have_mason, mlsp = pcall(require, 'mason-lspconfig')
  local all_mslp_servers = {}
  if have_mason then
    all_mslp_servers = vim.tbl_keys(require('mason-lspconfig.mappings.server').lspconfig_to_package)
  end

  local ensure_installed = {} ---@type string[]
  for server, server_opts in pairs(servers) do
    if server_opts then
      server_opts = server_opts == true and {} or server_opts
      -- run manual setup if mason=false or if this is a server that cannot be installed with mason-lspconfig
      if server_opts.mason == false or not vim.tbl_contains(all_mslp_servers, server) then
        setup(server)
      else
        ensure_installed[#ensure_installed + 1] = server
      end
    end
  end

  if have_mason then
    mlsp.setup { ensure_installed = ensure_installed, handlers = { setup } }
  end
end

M.dependencies = {
  'nvimtools/none-ls.nvim',
  'folke/lsp-colors.nvim',
  {
    'williamboman/mason.nvim',
    cmd = 'Mason',
    keys = { { '<leader>cm', '<cmd>Mason<cr>', desc = 'Mason' } },
    build = ':MasonUpdate',
    opts = {
      ui = {
        border = require('user.utils').float_border,
      },
    },
  },
  'williamboman/mason-lspconfig.nvim',
  'nanotee/nvim-lsp-basics',
  {
    'j-hui/fidget.nvim',
    config = function()
      require('fidget').setup {
        progress = {
          display = {
            progress_icon = { pattern = 'moon', period = 1 },
          },
        },
      }
    end,
  },
  {
    'nvimdev/lspsaga.nvim',
    opts = {
      finder = {
        keys = {
          edit = '<CR>',
          vsplit = '<C-v>',
          split = '<C-x>',
        },
      },
      definition = {
        keys = {
          edit = '<CR>',
          vsplit = '<C-v>',
          split = '<C-x>',
        },
      },

      lightbulb = {
        enable = false,
        sign = false,
      },
      symbol_in_winbar = {
        enable = true,
        hide_keyword = false,
      },
    },
    config = true,
  },
}

local language_specific_plugins = {
  {
    'mfussenegger/nvim-jdtls',
    ft = { 'java' },
  },
  {
    'jose-elias-alvarez/typescript.nvim',
    ft = { 'typescript', 'typescriptreact', 'typescript.tsx', 'javascript' },
  },
  {
    'someone-stole-my-name/yaml-companion.nvim',
    ft = { 'yaml' },
    config = function()
      local nnoremap = require('user.utils').nnoremap
      nnoremap('<leader>cc', ":lua require('yaml-companion').open_ui_select()<cr>", true)
    end,
  },
  {
    'b0o/SchemaStore.nvim',
    ft = { 'yaml' },
  },
  {
    'folke/neodev.nvim',
    ft = { 'lua' },
    opts = {
      override = function(_, library)
        library.enabled = true
        library.plugins = true
      end,
    },
  },
}

return {
  M,
  language_specific_plugins,
}
