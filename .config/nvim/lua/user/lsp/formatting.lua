local M = {
  bufnr = 0,
}
M.get_all_clients = function()
  local method = 'textDocument/formatting'
  local clients = vim.tbl_values(vim.lsp.get_clients { bufnr = M.bufnr })
  local formatting_clients = {}
  for _, client in ipairs(clients) do
    if client.supports_method(method) then
      table.insert(formatting_clients, client)
    end
  end
  return formatting_clients
end

local function select_client(callback)
  local clients = M.get_all_clients()
  -- Prompt user for client with vim.ui.input and call callback with response
  if #clients == 1 then
    return callback(clients[1])
  end
  return vim.ui.select(clients, {
    prompt = 'Select LSP client',
    format_item = function(client)
      return client.name
    end,
  }, function(client)
    if client == nil then
      return
    end
    callback(client)
  end)
end

M.format = function(client)
  M.format_changedtick = vim.api.nvim_buf_get_changedtick(M.bufnr)
  vim.lsp.buf.format {
    timeout_ms = 20000,
    filter = function(s_client)
      return s_client.name == client.name
    end,
  }

  if M.format_changedtick ~= vim.api.nvim_buf_get_changedtick(M.bufnr) then
    vim.notify('Formatted using ' .. client.name)
  end
end

M.format_select = function()
  select_client(function(client)
    M.format(client)
  end)
end

M.format_on_save = function()
  local clients = M.get_all_clients()
  if #clients == 0 then
    return
  end
  M.format(clients[1])
end

M.setup = function(client, bufnr)
  M.bufnr = bufnr
  -- format keymap
  vim.keymap.set('n', '<leader>lp', function()
    M.format_select()
  end, { silent = true, buffer = bufnr, desc = 'Format document' })

  -- format on save
  local group = vim.api.nvim_create_augroup('Format', { clear = false })
  vim.api.nvim_clear_autocmds {
    buffer = bufnr,
    group = group,
  }
  local event = 'BufWritePre'
  vim.api.nvim_create_autocmd(event, {
    group = group,
    desc = 'Format on save',
    buffer = bufnr,
    callback = M.format_on_save,
  })

  -- Formatexpr using LSP
  if client.server_capabilities.document_formatting == true then
    vim.api.nvim_set_option_value('formatexpr', 'v:lua.vim.lsp.formatexpr()', { buf = bufnr })
  end
end

return M
