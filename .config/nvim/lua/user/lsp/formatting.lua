local M = {}
local m_utils = require 'user.utils'
local opts = m_utils.map_opts
local buf_set_option = vim.api.nvim_buf_set_option
local lsp_format_ok, lsp_format = pcall(require, 'lsp-format')
if not lsp_format_ok then
  return
end

lsp_format.setup {
  lua = {
    exclude = { 'sumneko_lua' },
  },

  javascriptreact = {
    exclude = { 'tsserver' },
  },
}

local function select_client(method, callback)
  local clients = vim.tbl_values(vim.lsp.get_active_clients { bufnr = 0 })
  local client_names = {}
  for _, client in ipairs(clients) do
    if client.supports_method(method) then
      table.insert(client_names, client.name)
    end
  end

  -- Prompt user for client with vim.ui.input and call callback with response
  if #client_names == 1 then
    return callback(client_names[1])
  end
  return vim.ui.select(client_names, { 'Select LSP client' }, callback)
end

M.format = function()
  select_client('textDocument/formatting', function(client_name)
    if client_name == nil then
      return
    end
    vim.lsp.buf.format {
      filter = function(s_client)
        return s_client.name == client_name
      end,
    }
    vim.notify('Formatted using ' .. client_name)
  end)
end

M.setup = function(client, bufnr)
  lsp_format.on_attach(client)
  vim.keymap.set('n', '<leader>lp', function()
    M.format()
  end, vim.tbl_extend('force', opts.silent, { buffer = bufnr }))

  -- Formatexpr using LSP
  if client.server_capabilities.document_formatting == true then
    buf_set_option(bufnr, 'formatexpr', 'v:lua.vim.lsp.formatexpr()')
  end
end

return M
