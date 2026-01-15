local M = {
  diagnostic_signs = {
    [vim.diagnostic.severity.ERROR] = '✘',
    [vim.diagnostic.severity.WARN] = '',
    [vim.diagnostic.severity.HINT] = ' ',
    [vim.diagnostic.severity.INFO] = ' ',
  },
  capabilities = {
    textDocument = {
      completion = {
        completionItem = {
          snippetSupport = true,
        },
      },
      foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      },
    },
  },
}

local function setup_keymaps(bufnr)
  local function opts(description)
    return { remap = false, buffer = bufnr, silent = true, desc = description }
  end

  -- rename
  vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, opts 'Rename')
  -- goto definition/declaration
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts 'Go to definition')
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts 'Go to declaration')
  vim.keymap.set('n', '<leader>lk', vim.lsp.buf.signature_help, opts 'Signature help')

  -- GoTo code navigation
  vim.keymap.set('n', 'gy', vim.lsp.buf.type_definition, opts 'Go to type definition')
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts 'Go to implementation')
  vim.keymap.set('n', 'gR', vim.lsp.buf.references, opts 'Go to references')

  -- Workspace
  vim.keymap.set('n', '<leader>lwa', vim.lsp.buf.add_workspace_folder, opts 'Add workspace folder')
  vim.keymap.set('n', '<leader>lwr', vim.lsp.buf.remove_workspace_folder, opts 'Remove workspace folder')
  vim.keymap.set('n', '<leader>lwl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, opts 'List workspace folders')

  -- Inlay hints
  vim.keymap.set('n', '<leader>lh', function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = bufnr })
  end, opts 'Toggle inlay hints')

  -- Diagnostics
  vim.keymap.set('n', '<leader>lq', vim.diagnostic.setqflist, opts 'Set qflist with diagnostics')
  vim.keymap.set('n', '<leader>ld', vim.diagnostic.open_float, opts 'Open diagnostics float window')

  -- Code action
  vim.keymap.set('n', '<leader>la', vim.lsp.buf.code_action, opts 'Code action')
  vim.keymap.set('n', '<leader>lx', vim.lsp.codelens.run, opts 'Code lens')
end

M.setup = function()
  _G.start_ls = function(with_file)
    local file_name = nil
    if with_file == true then
      local ft = vim.bo[0].filetype
      file_name = _G.tmp_write { should_delete = false, new = false, ft = ft }
    end
    -- load lsp
    require 'lspconfig'
    return file_name
  end
  vim.keymap.set('n', '<leader>ls', function()
    _G.start_ls(false)
  end)
  vim.keymap.set('n', '<leader>lS', function()
    _G.start_ls(true)
  end)
  require('user.menu').add_actions('LSP', {
    ['Start LSP (<leader>ls)'] = function()
      _G.start_ls()
    end,
  })

  -- on attach
  local on_attach_aug = vim.api.nvim_create_augroup('UserLspAttach', { clear = true })
  vim.api.nvim_create_autocmd('LspAttach', {
    group = on_attach_aug,
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      local bufnr = ev.buf

      -- navic
      if client and client.server_capabilities.documentSymbolProvider then
        require('nvim-navic').attach(client, bufnr)
      end

      -- Configure semantic token highlighting
      if client and client.server_capabilities.semanticTokensProvider then
        vim.lsp.semantic_tokens.enable(true)
      end

      -- Mappings (per-buffer, only once)
      if not vim.b[bufnr].lsp_keymaps_configured then
        vim.b[bufnr].lsp_keymaps_configured = true
        setup_keymaps(bufnr)
      end

      -- Diagnostics config (once)
      if not vim.g.diagnostics_configured then
        vim.g.diagnostics_configured = true
        vim.diagnostic.config {
          severity_sort = true,
          signs = { text = M.diagnostic_signs },
          virtual_text = {
            prefix = '●',
            source = 'if_many',
            current_line = false,
            severity = { min = vim.diagnostic.severity.WARN },
          },
          virtual_lines = { current_line = true },
          float = { border = 'rounded', source = true },
          update_in_insert = false,
          underline = true,
        }
      end

      -- for statusline
      vim.schedule(function()
        vim.b[bufnr].attached_lsp = vim.tbl_map(function(client_l)
          return client_l.name
        end, vim.lsp.get_clients { bufnr = bufnr })
        vim.cmd 'redrawstatus'
      end)
    end,
  })

  require('user.lsp.actions').setup()
  require('user.lsp.inspect').setup()

  -- Global capabilities for all LSP servers
  vim.lsp.config('*', { capabilities = M.capabilities })

  -- Enable LSP servers
  vim.lsp.enable {
    'bashls',
    'cssls',
    'cssmodules_ls',
    'docker_compose_language_service',
    'dockerls',
    'golangci_lint_ls',
    'groovyls',
    'helm_ls',
    'html',
    'jinja_lsp',
    'jsonls',
    'lua_ls',
    'pyright',
    'terraformls',
    'user_lsp',
    'vimls',
    'vtsls',
    'yamlls',
  }
end

return M
