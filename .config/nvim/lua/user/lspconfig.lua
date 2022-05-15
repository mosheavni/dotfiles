local lsp_status = require('lsp-status')
local autocmd = vim.api.nvim_create_autocmd
local augroup = function(name)
  vim.api.nvim_create_augroup(name, { clear = true })
end
local buf_set_option = vim.api.nvim_buf_set_option

-- Set formatting
require('vim.lsp.log').set_format_func(vim.inspect)

local default_on_attach = function(client, bufnr)
  lsp_status.on_attach(client)

  if client.resolved_capabilities.code_lens then
    autocmd({ 'BufEnter', 'InsertLeave', 'InsertEnter' }, {
      desc = 'Auto show code lenses',
      pattern = '<buffer>',
      command = 'silent! lua vim.lsp.codelens.refresh()',
    })
  end
  if client.resolved_capabilities.document_highlight then
    local group = augroup('HighlightLSPSymbols')
    -- Highlight text at cursor position
    autocmd({ 'CursorHold', 'CursorHoldI' }, {
      desc = 'Highlight references to current symbol under cursor',
      pattern = '<buffer>',
      command = 'silent! lua vim.lsp.buf.document_highlight()',
      group = group,
    })
    autocmd({ 'CursorMoved' }, {
      desc = 'Clear highlights when cursor is moved',
      pattern = '<buffer>',
      command = 'silent! lua vim.lsp.buf.clear_references()',
      group = group,
    })
  end
  if client.resolved_capabilities.document_formatting then
    -- auto format file on save
    autocmd({ 'BufWritePre' }, {
      desc = 'Auto format file before saving',
      pattern = '<buffer>',
      command = 'silent! undojoin | lua vim.lsp.buf.formatting_seq_sync()',
    })
  end

  -- Enable tag jump and formatting based on LSP
  if client.resolved_capabilities.goto_definition == true then
    buf_set_option(bufnr, "tagfunc", "v:lua.vim.lsp.tagfunc")
  end

  if client.resolved_capabilities.document_formatting == true then
    buf_set_option(bufnr, "formatexpr", "v:lua.vim.lsp.formatexpr()")
  end
end

local function ensure_server(name)
  local lsp_installer = require('nvim-lsp-installer.servers')
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
ensure_server('ansiblels'):setup({
  on_attach = default_on_attach,
  capabilities = capabilities,
})
-- ansblel
ensure_server('awk_ls'):setup({
  on_attach = default_on_attach,
  capabilities = capabilities,
})
-- bashls
ensure_server('bashls'):setup({
  on_attach = default_on_attach,
  capabilities = capabilities,
})
-- dockerls
ensure_server('dockerls'):setup({
  on_attach = default_on_attach,
  capabilities = capabilities,
})
-- eslint
ensure_server('eslint'):setup({
  on_attach = default_on_attach,
  capabilities = capabilities,
})
-- groovyls
ensure_server('groovyls'):setup({
  on_attach = default_on_attach,
  capabilities = capabilities,
})
-- html
ensure_server('html'):setup({
  on_attach = default_on_attach,
  capabilities = capabilities,
})
-- json
local jsonls = ensure_server('jsonls')
jsonls:setup({
  on_attach = default_on_attach,
  capabilities = capabilities,
  commands = {
    Format = {
      function()
        vim.lsp.buf.range_formatting({}, { 0, 0 }, { vim.fn.line('$'), 0 })
      end,
    },
  },
  settings = {
    json = {
      schemas = require('schemastore').json.schemas(),
    },
  },
})
-- python
ensure_server('pyright'):setup({
  on_attach = default_on_attach,
  capabilities = capabilities,
  settings = {
    organizeimports = {
      provider = "isort"

    }
  }
})
--lua
ensure_server('sumneko_lua'):setup({
  on_attach = default_on_attach,
  capabilities = capabilities,
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        library = {
          [vim.fn.expand("$VIMRUNTIME/lua")] = true,
          [vim.fn.stdpath("config") .. "/lua"] = true,
        },
      },
    },
  },
})
--terraformls
ensure_server('terraformls'):setup({
  on_attach = default_on_attach,
  capabilities = capabilities,
})
--tsserver
ensure_server('tsserver'):setup({
  on_attach = default_on_attach,
  capabilities = capabilities,
})

--vimls
ensure_server('vimls'):setup({
  on_attach = default_on_attach,
  capabilities = capabilities,
})
-- yaml{
-- vim.lsp.set_log_level("debug")
ensure_server('yamlls'):setup({
  on_attach = default_on_attach,
  capabilities = capabilities,
  cmd = { 'node', '/Users/mavni/Repos/yaml-language-server/out/server/src/server.js', '--stdio' },
  on_init = function()
    require('user.select-schema').get_client()
  end,
  settings = {
    yaml = {
      hover = true,
      trace = {
        server = "verbose"
      },
      completion = true,
      format = {
        enable = true
      },
      validate = true,
      schemaStore = {
        enable = true,
        url = "https://www.schemastore.org/api/json/catalog.json"
      },
      schemas = {
        kubernetes = {
          "*role*.y*ml",
          "deploy.y*ml",
          "deployment.y*ml",
          "ingress.y*ml",
          "kubectl-edit-*",
          "pdb.y*ml",
          "pod.y*ml",
          "rbac.y*ml",
          "service.y*ml",
          "service*account.y*ml",
          "storageclass.y*ml",
          "svc.y*ml"
        }
      }
    }
  }
})

-- general LSP config
vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
  underline = true,
  update_in_insert = true,
  virtual_text = false,
  signs = true,
})

-- show icons in the sidebar
local signs = { Error = ' ', Warn = ' ', Hint = ' ', Information = ' ' }

for type, icon in pairs(signs) do
  local hl = 'DiagnosticSign' .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

vim.diagnostic.config({
  severity_sort = true,
})

-- null-ls
-- local null_ls = require('null-ls')
-- null_ls.setup({
--   debug = true,
--   sources = {
--     -- null_ls.builtins.code_actions.eslint_d,
--     null_ls.builtins.code_actions.refactoring,
--     -- null_ls.builtins.diagnostics.eslint_d,
--     -- null_ls.builtins.diagnostics.markdownlint,
--     -- null_ls.builtins.diagnostics.write_good,
--     -- null_ls.builtins.formatting.eslint_d,
--     -- null_ls.builtins.formatting.fixjson,
--     -- null_ls.builtins.formatting.markdownlint,
--     null_ls.builtins.code_actions.shellcheck,
--     null_ls.builtins.diagnostics.ansiblelint,
--     null_ls.builtins.diagnostics.hadolint,
--     null_ls.builtins.diagnostics.pylint,
--     null_ls.builtins.diagnostics.shellcheck,
--     null_ls.builtins.diagnostics.yamllint,
--     null_ls.builtins.formatting.black,
--     null_ls.builtins.formatting.prettier,
--     null_ls.builtins.formatting.shfmt,
--     -- null_ls.builtins.diagnostics.codespell.with({
--     --   filetypes = { 'txt', 'md' },
--     -- }),
--   },
--   on_attach = default_on_attach,
-- })
require('lsp_signature').setup({})
