local on_windows = vim.loop.os_uname().version:match 'Windows'

local function join_paths(...)
  local path_sep = on_windows and '\\' or '/'
  local result = table.concat({ ... }, path_sep)
  return result
end

vim.cmd [[set runtimepath=$VIMRUNTIME]]

local temp_dir = vim.loop.os_getenv 'TEMP' or '/tmp'

vim.cmd('set packpath=' .. join_paths(temp_dir, 'nvim', 'site'))

local package_root = join_paths(temp_dir, 'nvim', 'site', 'pack')
local install_path = join_paths(package_root, 'packer', 'start', 'packer.nvim')
local compile_path = join_paths(install_path, 'plugin', 'packer_compiled.lua')

local function load_plugins()
  require('packer').startup {
    {
      'wbthomason/packer.nvim',
      'neovim/nvim-lspconfig',
      'hrsh7th/nvim-cmp', -- auto completion
      'hrsh7th/cmp-nvim-lsp',
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
      'nvim-treesitter/nvim-treesitter',
    },
    config = {
      package_root = package_root,
      compile_path = compile_path,
    },
  }
end

_G.load_config = function()
  vim.lsp.set_log_level 'trace'
  if vim.fn.has 'nvim-0.5.1' == 1 then
    require('vim.lsp.log').set_format_func(vim.inspect)
  end
  local nvim_lsp = require 'lspconfig'
  local on_attach = function(client, bufnr)
    print('On Attach ' .. client.name)
    local function buf_set_keymap(...)
      vim.api.nvim_buf_set_keymap(bufnr, ...)
    end

    local function buf_set_option(...)
      vim.api.nvim_buf_set_option(bufnr, ...)
    end

    buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings.
    local opts = { noremap = true, silent = true }
    buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
    buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
    buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', '<space>e', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
    buf_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
    buf_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
    buf_set_keymap('n', '<space>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)
    buf_set_keymap('n', '<space>p', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
  end

  -- load treesitter
  require('nvim-treesitter.configs').setup {
    highlight = { enable = true },
  }

  -- Set up completion
  local cmp = require 'cmp'
  cmp.setup {
    snippet = {
      expand = function(args)
        require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
      end,
    },
    window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert {
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.abort(),
      ['<CR>'] = cmp.mapping.confirm { select = true }, -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    },
    sources = cmp.config.sources {
      { name = 'nvim_lsp' },
      { name = 'luasnip' }, -- For luasnip users.
    },
  }

  -- Set up capabilities
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)

  -- Add the server that troubles you here
  local name = 'yamlls'
  local yaml_install_path = vim.fn.expand '~' .. '/Repos/yaml-language-server'
  local cmd = { 'node', yaml_install_path .. '/out/server/src/server.js', '--stdio' }
  if not name then
    print 'You have not defined a server name, please edit minimal_init.lua'
  end
  if not nvim_lsp[name].document_config.default_config.cmd and not cmd then
    print [[You have not defined a server default cmd for a server
      that requires it please edit minimal_init.lua]]
  end

  nvim_lsp[name].setup {
    cmd = cmd,
    on_attach = on_attach,
    capabilities = capabilities,
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
  }

  print [[You can find your log at $HOME/.cache/nvim/lsp.log. Please paste in a github issue under a details tag as described in the issue template.]]
end

if vim.fn.isdirectory(install_path) == 0 then
  vim.fn.system { 'git', 'clone', 'https://github.com/wbthomason/packer.nvim', install_path }
  load_plugins()
  require('packer').sync()
  vim.cmd [[autocmd User PackerComplete ++once lua load_config()]]
else
  load_plugins()
  require('packer').sync()
  _G.load_config()
end
