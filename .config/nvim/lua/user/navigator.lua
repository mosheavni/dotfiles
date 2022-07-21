-- Navigator
local status_ok, navigator = pcall(require, 'navigator')
if not status_ok then
  return vim.notify 'Module navigator not installed'
end
local n_reference = require 'navigator.reference'
-- local n_symbols = require 'navigator.symbols'
local n_workspace = require 'navigator.workspace'
local n_definition = require 'navigator.definition'
local n_treesitter = require 'navigator.treesitter'
local n_codeAction = require 'navigator.codeAction'
local n_rename = require 'navigator.rename'
local n_diagnostics = require 'navigator.diagnostics'
-- local n_dochighlight = require 'navigator.dochighlight'
-- local n_formatting = require 'navigator.formatting'
local n_codeLens = require 'navigator.codeLens'
navigator.setup {
  default_mapping = false,
  lsp = {
    ['lua-dev'] = { runtime_path = true }, -- any non default lua-dev setups
  },
  keymaps = {
    { key = 'gr', func = n_reference.async_ref, desc = 'async_ref' },
    { mode = 'i', key = '<M-k>', func = vim.lsp.signature_help, desc = 'signature_help' },
    { key = '<leader>lk', func = vim.lsp.buf.signature_help, desc = 'signature_help' },
    -- { key = 'g0', func = n_symbols.document_symbols, desc = 'document_symbols' },
    -- { key = 'gW', func = n_workspace.workspace_symbol_live, desc = 'workspace_symbol_live' },
    { key = '<c-]>', func = n_definition.definition, desc = 'definition' },
    { key = 'gd', func = n_definition.definition, desc = 'definition' },
    { key = 'gp', func = n_definition.definition_preview, desc = 'definition_preview' },
    -- { key = '<Leader>gt', func = n_treesitter.buf_ts, desc = 'buf_ts' },
    -- { key = '<Leader>gT', func = n_treesitter.bufs_ts, desc = 'bufs_ts' },
    -- { key = '<Leader>ct', func = n_ctags.ctags, desc = 'ctags' },
    { key = '<Leader>la', mode = 'n', func = n_codeAction.code_action, desc = 'code_action' },
    {
      key = '<Leader>la',
      mode = 'v',
      func = n_codeAction.range_code_action,
      desc = 'range_code_action',
    },
    -- { key = '<Leader>re', func = 'rename()' },
    { key = '<Leader>lrn', func = n_rename.rename, desc = 'rename' },
    -- { key = '<Leader>gi', func = vim.lsp.buf.incoming_calls, desc = 'incoming_calls' },
    -- { key = '<Leader>go', func = vim.lsp.buf.outgoing_calls, desc = 'outgoing_calls' },
    { key = 'gi', func = vim.lsp.buf.implementation, desc = 'implementation' },
    { key = 'gy', func = vim.lsp.buf.type_definition, desc = 'type_definition' },
    -- { key = '<Leader>ld', func = n_diagnostics.show_diagnostics, desc = 'show_diagnostics' },
    { key = '<Leader>ld', func = n_diagnostics.show_buf_diagnostics, desc = 'show_buf_diagnostics' },
    -- { key = '<Leader>dt', func = n_diagnostics.toggle_diagnostics, desc = 'toggle_diagnostics' },
    { key = ']g', func = vim.diagnostic.goto_next, desc = 'next diagnostics' },
    { key = '[g', func = vim.diagnostic.goto_prev, desc = 'prev diagnostics' },
    -- { key = ']O', func = vim.diagnostic.set_loclist, desc = 'diagnostics set loclist' },
    { key = ']r', func = n_treesitter.goto_next_usage, desc = 'goto_next_usage' },
    { key = '[r', func = n_treesitter.goto_previous_usage, desc = 'goto_previous_usage' },
    -- { key = '<C-LeftMouse>', func = vim.lsp.buf.definition, desc = 'definition' },
    -- { key = 'g<LeftMouse>', func = vim.lsp.buf.implementation, desc = 'implementation' },
    -- { key = '<Leader>k', func = n_dochighlight.hi_symbol, desc = 'hi_symbol' },
    { key = '<Leader>lwa', func = n_workspace.add_workspace_folder, desc = 'add_workspace_folder' },
    {
      key = '<Leader>lwr',
      func = n_workspace.remove_workspace_folder,
      desc = 'remove_workspace_folder',
    },
    { key = '<Leader>lp', func = vim.lsp.buf.format, mode = 'n', desc = 'format' },
    { key = '<Leader>lp', func = vim.lsp.buf.range_formatting, mode = 'v', desc = 'range format' },
    -- { key = '<Leader>rf', func = n_formatting.range_format, mode = 'n', desc = 'range_fmt_v' },
    { key = '<Leader>lwl', func = n_workspace.list_workspace_folders, desc = 'list_workspace_folders' },
    { key = '<Leader>lx', mode = 'n', func = n_codeLens.run_action, desc = 'run code lens action' },
  },
}
