local M = {}
local util = require 'vim.lsp.util'
local m_utils = require 'user.utils'
local opts = m_utils.map_opts
local buf_set_option = vim.api.nvim_buf_set_option
local lsp_format = require 'lsp-format'

lsp_format.setup {
  exclude = { 'copilot' },
  lua = {
    exclude = { 'sumneko_lua' },
  },
}

local function select_client(method, callback)
  local clients = vim.tbl_values(vim.lsp.buf_get_clients())
  local client_names = {}
  for _, client in ipairs(clients) do
    if client.supports_method(method) then
      -- add client.name to client_names
      table.insert(client_names, client.name)
    end
  end

  -- Prompt user for client with vim.ui.input and call callback with response
  vim.ui.select(client_names, { 'Select LSP client' }, callback)
end

local function formatting_sync(options, timeout_ms)
  local client = select_client 'textDocument/formatting'
  if client == nil then
    return
  end

  local params = util.make_formatting_params(options)
  local result, err = client.request_sync('textDocument/formatting', params, timeout_ms, vim.api.nvim_get_current_buf())
  if result and result.result then
    util.apply_text_edits(result.result)
  elseif err then
    vim.notify('vim.lsp.buf.formatting_sync: ' .. err, vim.log.levels.WARN)
  end
end

M.setup = function(client, bufnr)
  P('called for ' .. client.name)
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
