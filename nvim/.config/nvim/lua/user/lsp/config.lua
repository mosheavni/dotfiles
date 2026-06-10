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
  vim.keymap.set('n', '<leader>lq', function()
    local diagnostics = vim.diagnostic.get(bufnr)
    if vim.tbl_isempty(diagnostics) then
      vim.notify('No diagnostics in current buffer', vim.log.levels.INFO)
      return
    end
    local items = vim.diagnostic.toqflist(diagnostics)
    for i, d in ipairs(diagnostics) do
      if d.source and d.source ~= '' and items[i] then
        items[i].text = string.format('[%s] %s', d.source, items[i].text)
      end
    end
    vim.fn.setqflist({}, ' ', {
      title = 'Diagnostics: ' .. vim.api.nvim_buf_get_name(bufnr),
      items = items,
    })
    vim.cmd 'botright copen'
  end, opts 'Set qflist with buffer diagnostics')
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
  end, { desc = 'Start LSP (without file)' })
  vim.keymap.set('n', '<leader>lS', function()
    _G.start_ls(true)
  end, { desc = 'Start LSP (with file)' })
  require('user.menu').add_actions('LSP', {
    ['Start LSP without file (<leader>ls)'] = function()
      _G.start_ls()
    end,
    ['Start LSP with file (<leader>lS)'] = function()
      _G.start_ls(true)
    end,
  })

  vim.diagnostic.config {
    jump = {
      on_jump = function(_, jump_bufnr)
        vim.diagnostic.open_float { bufnr = jump_bufnr, scope = 'cursor', focus = false }
      end,
    },
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

      -- Mappings (per-buffer, only once)
      if not vim.b[bufnr].lsp_keymaps_configured then
        vim.b[bufnr].lsp_keymaps_configured = true
        setup_keymaps(bufnr)
      end

      -- Prefer LSP folding over treesitter/indent when the server supports it.
      -- Skip when the window is in diff mode so fugitive (and :diffthis) keep foldmethod=diff.
      if client and client:supports_method('textDocument/foldingRange', bufnr) then
        local win = vim.api.nvim_get_current_win()
        if not vim.wo[win].diff then
          vim.wo[win][0].foldmethod = 'expr'
          vim.wo[win][0].foldexpr = 'v:lua.vim.lsp.foldexpr()'
        end
      end

      -- Highlight references of symbol under cursor (semantic, complements mini.cursorword)
      if client and client:supports_method('textDocument/documentHighlight', bufnr) and not vim.b[bufnr].lsp_dochl_configured then
        vim.b[bufnr].lsp_dochl_configured = true
        local hl_group = vim.api.nvim_create_augroup('lsp-document-highlight', { clear = false })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          buffer = bufnr,
          group = hl_group,
          callback = vim.lsp.buf.document_highlight,
        })
        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
          buffer = bufnr,
          group = hl_group,
          callback = vim.lsp.buf.clear_references,
        })
        vim.api.nvim_create_autocmd('LspDetach', {
          group = hl_group,
          buffer = bufnr,
          callback = function(detach_ev)
            -- LspDetach fires before the client is removed, so <= 1 means
            -- the detaching client is the last one supporting documentHighlight
            if #vim.lsp.get_clients { bufnr = detach_ev.buf, method = 'textDocument/documentHighlight' } <= 1 then
              vim.lsp.util.buf_clear_references(detach_ev.buf)
              vim.api.nvim_clear_autocmds { group = hl_group, buffer = detach_ev.buf }
              vim.b[detach_ev.buf].lsp_dochl_configured = nil
            end
          end,
        })
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
