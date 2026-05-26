vim.pack.add {
  'https://github.com/MunifTanjim/nui.nvim',
  'https://github.com/ray-x/guihua.lua',
  'https://github.com/mason-org/mason.nvim',
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/j-hui/fidget.nvim',
  'https://github.com/SmiteshP/nvim-navic',
  'https://github.com/phelipetls/jsonpath.nvim',
  'https://github.com/folke/lazydev.nvim',
  'https://github.com/DrKJeff16/wezterm-types',
  'https://github.com/b0o/SchemaStore.nvim',
  'https://github.com/ray-x/go.nvim',
  'https://github.com/milisims/nvim-luaref',
}

local yamlc_dev = vim.fn.expand '~/Repos/yaml-companion.nvim'
if vim.env.YAMLC_DEV == 'true' and vim.fn.isdirectory(yamlc_dev) == 1 then
  vim.opt.runtimepath:prepend(yamlc_dev)
else
  vim.pack.add { 'https://github.com/mosheavni/yaml-companion.nvim' }
end

return function()
  require('mason').setup {
    ui = { border = 'rounded' },
  }

  local packages = {
    'actionlint',
    'bash-debug-adapter',
    'bash-language-server',
    'black',
    'cbfmt',
    'checkmake',
    'codespell',
    'css-lsp',
    'cssmodules-language-server',
    'debugpy',
    'docker-compose-language-service',
    'dockerfile-language-server',
    'eslint_d',
    'gitleaks',
    'golangci-lint',
    'golangci-lint-langserver',
    'groovy-language-server',
    'hadolint',
    'helm-ls',
    'html-lsp',
    'isort',
    'jinja-lsp',
    'json-lsp',
    'lua-language-server',
    'markdownlint',
    'npm-groovy-lint',
    'prettierd',
    'proselint',
    'pyright',
    'ruff',
    'selene',
    'shellcheck',
    'shfmt',
    'stylua',
    'terraform-ls',
    'tombi',
    'trivy',
    'typescript-language-server',
    'vim-language-server',
    'vint',
    'vtsls',
    'write-good',
    'yaml-language-server',
  }
  local mr = require 'mason-registry'
  for _, package in ipairs(packages) do
    if not mr.is_installed(package) then
      vim.notify('Installing ' .. package .. ' via Mason')
      mr.get_package(package):install()
    end
  end

  vim.keymap.set('n', '<leader>cm', '<cmd>Mason<cr>', { desc = 'Mason' })

  require('user.lsp.config').setup()

  require('fidget').setup {
    progress = {
      display = {
        progress_icon = { pattern = 'moon', period = 1 },
      },
    },
  }

  local navic = require 'nvim-navic'
  navic.setup { highlight = true }
  vim.o.winbar = "%{%v:lua.require'nvim-navic'.get_location()%}"

  vim.api.nvim_create_user_command('JsonPath', function()
    local json_path = require('jsonpath').get()
    vim.fn.setreg('+', json_path)
    vim.notify('Copied ' .. json_path .. ' to register +', vim.log.levels.INFO, { title = 'JsonPath' })
  end, {})
  require('user.menu').add_actions('JSON', {
    ['Copy Json Path to clipboard (:JsonPath)'] = function()
      vim.cmd [[JsonPath]]
    end,
  })

  vim.keymap.set('n', '<leader>cs', function()
    require('yaml-companion').open_ui_select()
  end, { remap = false, silent = true })
  vim.api.nvim_create_user_command('YamlYankKey', function()
    local info = require('yaml-companion').get_key_at_cursor()
    if info and info.key then
      vim.fn.setreg('+', info.key)
      vim.notify('Copied: ' .. info.key)
    end
  end, {})
  require('user.menu').add_actions('YAML', {
    ['Change Schema'] = function()
      require('yaml-companion').open_ui_select()
    end,
    ['Copy Yaml Key at Cursor to clipboard (:YamlYankKey)'] = function()
      vim.cmd [[YamlYankKey]]
    end,
  })

  require('lazydev').setup {
    library = {
      { path = 'wezterm-types', mods = { 'wezterm' } },
      { path = 'plenary.nvim', words = { 'describe', 'assert' } },
      { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      { path = '${3rd}/busted/library', words = { 'describe', 'it', 'assert' } },
      { path = '${3rd}/luassert/library', words = { 'assert' } },
    },
  }

  require('go').setup {
    lsp_cfg = true,
    lsp_gofumpt = true,
    lsp_inlay_hints = { enable = false },
    dap_vt = true,
  }
  local format_sync_grp = vim.api.nvim_create_augroup('GoFormat', {})
  vim.api.nvim_create_autocmd('BufWritePre', {
    pattern = '*.go',
    callback = function()
      require('go.format').goimports()
    end,
    group = format_sync_grp,
  })
end
