function _G.lsp_tmp_write(should_delete)
  local tmp = vim.fn.tempname()
  vim.cmd(string.format('write %s', tmp))
  vim.cmd 'edit'
  -- Create autocmd to delete the file on exit
  if should_delete then
    vim.api.nvim_create_autocmd({ 'VimLeavePre' }, {
      buffer = 0,
      command = 'delete("' .. tmp .. '")',
    })
  end
  return tmp
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

        -- Make sure helm_ls is installed
        -- require '.core.helm-ls-downloader'
        return true
      end,
      docker_compose_language_service = function() end,
    },
  },
  dependencies = {
    'nvimtools/none-ls.nvim',
    'mfussenegger/nvim-jdtls',
    'folke/lsp-colors.nvim',
    'williamboman/mason-lspconfig.nvim',
    'nanotee/nvim-lsp-basics',
    {
      'j-hui/fidget.nvim',
      tag = 'legacy',
      config = function()
        require('fidget').setup {
          text = {
            spinner = 'moon',
          },
        }
      end,
    },
    'b0o/SchemaStore.nvim',
    { 'folke/neodev.nvim', opts = {} },
    {
      'someone-stole-my-name/yaml-companion.nvim',
      config = function()
        local nnoremap = require('user.utils').nnoremap
        nnoremap('<leader>cc', ":lua require('yaml-companion').open_ui_select()<cr>", true)
      end,
    },
    'jose-elias-alvarez/typescript.nvim',
    {
      'nvimdev/lspsaga.nvim',
      opts = {
        finder_action_keys = {
          edit = '<CR>',
          vsplit = '<C-v>',
          split = '<C-x>',
          quit = 'q',
        },
        code_action_lightbulb = {
          enable = false,
        },
        symbol_in_winbar = {
          enable = true,
          hide_keyword = false,
        },
      },
      config = true,
    },
  },
}

M.init = function()
  vim.keymap.set('n', '<leader>ls', function()
    _G.lsp_tmp_write(true)
  end)

  vim.keymap.set('n', '<leader>ls', function()
    _G.lsp_tmp_write(false)
  end)
end

M.config = function(_, opts)
  require('plugins.lsp.handlers').setup()

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

  local servers = require 'plugins.lsp.servers'
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

local Mason = {
  'williamboman/mason.nvim',
  cmd = 'Mason',
  keys = { { '<leader>cm', '<cmd>Mason<cr>', desc = 'Mason' } },
  build = ':MasonUpdate',
  opts = {
    ui = {
      border = require('user.utils').float_border,
    },
  },
}

return { M, Mason }
