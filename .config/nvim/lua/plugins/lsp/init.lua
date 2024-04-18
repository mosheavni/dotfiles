local M = {
  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },
  opts = {
    inlay_hints = { enabled = true },
    setup = {
      tsserver = function(_, opts)
        require('typescript').setup {
          server = opts,
        }
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

M.init = require('user.lsp.config').init

M.config = function()
  require('user.lsp.config').setup()
  -- local function setup(server)
  --   local server_opts = vim.tbl_deep_extend('force', {
  --     capabilities = vim.deepcopy(capabilities),
  --   }, servers[server] or {})
  --
  --   if opts.setup[server] then
  --     if opts.setup[server](server, server_opts) then
  --       return
  --     end
  --   elseif opts.setup['*'] then
  --     if opts.setup['*'](server, server_opts) then
  --       return
  --     end
  --   end
  --   require('lspconfig')[server].setup(server_opts)
  -- end

  -- get all the servers that are available thourgh mason-lspconfig
  -- local have_mason, mlsp = pcall(require, 'mason-lspconfig')
  -- local all_mslp_servers = {}
  -- if have_mason then
  --   all_mslp_servers = vim.tbl_keys(require('mason-lspconfig.mappings.server').lspconfig_to_package)
  -- end
  --
  -- local ensure_installed = {} ---@type string[]
  -- for server, server_opts in pairs(servers) do
  --   if server_opts then
  --     server_opts = server_opts == true and {} or server_opts
  --     -- run manual setup if mason=false or if this is a server that cannot be installed with mason-lspconfig
  --     if server_opts.mason == false or not vim.tbl_contains(all_mslp_servers, server) then
  --       setup(server)
  --     else
  --       ensure_installed[#ensure_installed + 1] = server
  --     end
  --   end
  -- end
  --
  -- if have_mason then
  --   mlsp.setup { ensure_installed = ensure_installed, handlers = { setup } }
  -- end
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
      outline = {
        keys = {
          toggle_or_jump = '<CR>',
        },
      },
    },
    config = true,
  },
  {
    'folke/neodev.nvim',
    opts = {
      override = function(_, library)
        library.enabled = true
        library.plugins = true
      end,
    },
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
  { 'cuducos/yaml.nvim', ft = 'yaml' },
  {
    'phelipetls/jsonpath.nvim',
    ft = 'json',
    config = function()
      vim.api.nvim_buf_create_user_command(0, 'JsonPath', function()
        local json_path = require('jsonpath').get()
        local register = '+'
        vim.fn.setreg(register, json_path)
        vim.notify('Copied ' .. json_path .. ' to register ' .. register, vim.log.levels.INFO, { title = 'JsonPath' })
      end, {})
      require('user.menu').add_actions('JSON', {
        ['Copy Json Path to clipboard (:JsonPath)'] = function()
          vim.cmd [[JsonPath]]
        end,
      })
    end,
  },
  {
    'someone-stole-my-name/yaml-companion.nvim',
    ft = { 'yaml' },
    config = function()
      local nnoremap = require('user.utils').nnoremap
      nnoremap('<leader>cc', ":lua require('yaml-companion').open_ui_select()<cr>", true)
      require('user.menu').add_actions('YAML', {
        ['Change Schema'] = function()
          require('yaml-companion').open_ui_select()
        end,
      })
    end,
  },
  {
    'b0o/SchemaStore.nvim',
    ft = { 'yaml' },
  },
}

return {
  M,
  language_specific_plugins,
}
