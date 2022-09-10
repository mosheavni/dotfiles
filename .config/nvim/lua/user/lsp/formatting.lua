local M = {}
local util = require 'vim.lsp.util'
local m_utils = require 'user.utils'
local opts = m_utils.map_opts
local buf_set_option = vim.api.nvim_buf_set_option
local lsp_format = require 'lsp-format'

lsp_format.setup {
  lua = {
    exclude = { 'sumneko_lua' },
  },
}

local function select_client(method, callback)
  local clients = vim.tbl_values(vim.lsp.buf_get_clients())
  local client_names = {}
  for _, client in ipairs(clients) do
    if client.supports_method(method) then
      table.insert(client_names, client.name)
    end
  end

  -- Prompt user for client with vim.ui.input and call callback with response
  vim.ui.select(client_names, { 'Select LSP client' }, callback)
end

M.setup = function(client, bufnr)
  lsp_format.on_attach(client)
  vim.keymap.set('n', '<leader>lp', function()
    select_client('textDocument/formatting', function(client_name)
      if client_name == nil then
        return
      end
      vim.lsp.buf.format {
        filter = function(s_client)
          return s_client.name == client_name
        end,
      }
    end)
  end, vim.tbl_extend('force', opts.silent, { buffer = bufnr }))

  -- Formatexpr using LSP
  if client.server_capabilities.document_formatting == true then
    buf_set_option(bufnr, 'formatexpr', 'v:lua.vim.lsp.formatexpr()')
  end
end

return M
