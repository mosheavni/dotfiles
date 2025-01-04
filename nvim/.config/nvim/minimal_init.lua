local function join_paths(...)
  local path_sep = '/'
  local result = table.concat({ ... }, path_sep)
  return result
end

local temp_dir = vim.uv.os_getenv 'TEMP' or '/tmp'
local package_root = join_paths(temp_dir, 'nvim', 'site', 'lazy')
local lazypath = join_paths(temp_dir, 'nvim', 'site') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  vim
    .system({
      'git',
      'clone',
      '--filter=blob:none',
      '--single-branch',
      'https://github.com/folke/lazy.nvim.git',
      lazypath,
    }, { text = true })
    :wait()
end
vim.opt.runtimepath:prepend(lazypath)

_G.load_config = function()
  vim.lsp.set_log_level 'trace'
  require('vim.lsp.log').set_format_func(vim.inspect)
  local nvim_lsp = require 'lspconfig'
  local on_attach = function(client, bufnr)
    print('On Attach ' .. client.name)
    local function buf_set_keymap(...)
      vim.api.nvim_buf_set_keymap(bufnr, ...)
    end

    vim.api.nvim_set_option_value('omnifunc', 'v:lua.vim.lsp.omnifunc', { buf = bufnr })

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
      { name = 'cmp_tabnine', priority = 80 },
    },
  }
  local tabnine = require 'cmp_tabnine.config'
  tabnine:setup {
    max_lines = 500,
    max_num_results = 5,
    sort = true,
  }

  -- Set up capabilities
  local capabilities = require('cmp_nvim_lsp').default_capabilities()

  -- Add the server that troubles you here
  local name = 'terraformls'
  -- local cmd = { 'node', yaml_install_path .. '/out/server/src/server.js', '--stdio' }
  if not name then
    print 'You have not defined a server name, please edit minimal_init.lua'
  end
  if not nvim_lsp[name].document_config.default_config.cmd then
    print [[You have not defined a server default cmd for a server
      that requires it please edit minimal_init.lua]]
  end

  nvim_lsp[name].setup {
    cmd = { '/Users/mavni/.local/share/nvim/mason/bin/terraform-ls', 'serve' },
    on_attach = on_attach,
    capabilities = capabilities,
    -- on_init = function()
    --   require('user.select-schema').get_client()
    -- end,
    -- settings = {
    --   redhat = { telemetry = { enabled = false } },
    --   yaml = {
    --     validate = true,
    --     format = { enable = true },
    --     hover = true,
    --     trace = { server = 'debug' },
    --     completion = true,
    --     schemaStore = {
    --       enable = true,
    --       url = 'https://www.schemastore.org/api/json/catalog.json',
    --     },
    --     schemas = {
    --       kubernetes = {
    --         '*role*.y*ml',
    --         'deploy.y*ml',
    --         'deployment.y*ml',
    --         'ingress.y*ml',
    --         'kubectl-edit-*',
    --         'pdb.y*ml',
    --         'pod.y*ml',
    --         'hpa.y*ml',
    --         'rbac.y*ml',
    --         'service.y*ml',
    --         'service*account.y*ml',
    --         'storageclass.y*ml',
    --         'svc.y*ml',
    --       },
    --     },
    --   },
    -- },
  }

  print [[You can find your log at $HOME/.cache/nvim/lsp.log. Please paste in a github issue under a details tag as described in the issue template.]]
end

require('lazy').setup({
  'habamax/vim-habamax',
  'neovim/nvim-lspconfig',
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      { 'tzachar/cmp-tabnine', build = './install.sh' },
      'saadparwaiz1/cmp_luasnip',
    },
  },
  'L3MON4D3/LuaSnip',
  'nvim-treesitter/nvim-treesitter',
  config = function()
    local configs = require 'nvim-treesitter.configs'
    configs.setup {
      ensure_installed = 'all',
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
    }
  end,
}, {
  root = package_root,
})
_G.load_config()

vim.cmd [[colorscheme habamax]]
