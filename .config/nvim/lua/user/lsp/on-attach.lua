local utils = require 'user.utils'
local user_maps = require 'user.lsp.maps'
local autocmd = utils.autocmd
local augroup = utils.augroup
local moshe_formatting = require 'user.lsp.formatting'
local buf_set_option = vim.api.nvim_buf_set_option
local navic = require 'nvim-navic'

local enable_ls_signature = {
  'sumneko_lua',
}

local on_attach_aug = augroup 'OnAttachAu'
local default_on_attach = function(client, bufnr)
  -- Add mappings
  user_maps(bufnr)

  -- Plugins on-attach
  local basics = require 'lsp_basics'
  basics.make_lsp_commands(client, bufnr)
  moshe_formatting.setup(client, bufnr)
  if client.server_capabilities.documentSymbolProvider then
    navic.attach(client, bufnr)
  end

  if vim.tbl_contains(enable_ls_signature, client.name) then
    require('lsp_signature').on_attach({
      bind = true, -- This is mandatory, otherwise border config won't get registered.
      handler_opts = {
        border = 'rounded',
      },
    }, bufnr)
  end

  if client.server_capabilities.code_lens then
    autocmd({ 'BufEnter', 'InsertLeave', 'InsertEnter' }, {
      group = on_attach_aug,
      desc = 'Auto show code lenses',
      buffer = bufnr,
      command = 'silent! lua vim.lsp.codelens.refresh()',
    })
  end
  if client.server_capabilities.document_highlight then
    -- Highlight text at cursor position
    autocmd({ 'CursorHold', 'CursorHoldI' }, {
      desc = 'Highlight references to current symbol under cursor',
      group = on_attach_aug,
      buffer = bufnr,
      command = 'silent! lua vim.lsp.buf.document_highlight()',
    })
    autocmd({ 'CursorMoved' }, {
      desc = 'Clear highlights when cursor is moved',
      group = on_attach_aug,
      buffer = bufnr,
      command = 'silent! lua vim.lsp.buf.clear_references()',
    })
  end

  -- Enable tag jump based on LSP
  if client.server_capabilities.goto_definition == true then
    buf_set_option(bufnr, 'tagfunc', 'v:lua.vim.lsp.tagfunc')
  end

  local diagnostic_pop = augroup 'DiagnosticPop'
  autocmd('CursorHold', {
    buffer = bufnr,
    group = diagnostic_pop,
    callback = function()
      local opts = {
        focusable = false,
        close_events = { 'BufLeave', 'CursorMoved', 'InsertEnter', 'FocusLost' },
        border = 'rounded',
        source = 'always',
        prefix = ' ',
        scope = 'cursor',
      }
      if vim.lsp.buf.server_ready() then
        vim.diagnostic.open_float(nil, opts)
      end
    end,
  })
end

local minimal_on_attach = function(_, bufnr)
  P 'minimal on_attach'
  -- Add mappings
  user_maps(bufnr)

  -- local basics = require 'lsp_basics'
  -- basics.make_lsp_commands(client, bufnr)
  --
  -- if not vim.tbl_contains(disable_ls_signature, client.name) then
  --   require('lsp_signature').on_attach()
  -- end

  -- Enable tag jump and formatting based on LSP
  -- if client.server_capabilities.goto_definition == true then
  --   buf_set_option(bufnr, 'tagfunc', 'v:lua.vim.lsp.tagfunc')
  -- end
  -- if client.server_capabilities.document_formatting == true then
  --   buf_set_option(bufnr, 'formatexpr', 'v:lua.vim.lsp.formatexpr()')
  -- end
end

return {
  default = default_on_attach,
  minimal = minimal_on_attach,
}
