local M = {}

--- Format a Lua value for display
---@param value any
---@return string
local function format_value(value)
  return vim.inspect(value, { indent = '  ', newline = '\n' })
end

--- Open a new tab with the client configuration
---@param client vim.lsp.Client
local function show_client_config(client)
  vim.cmd 'tabnew'
  local buf = vim.api.nvim_get_current_buf()

  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = 'lua'

  local lines = {
    '-- LSP Client: ' .. client.name,
    '-- ID: ' .. client.id,
    '-- Root Dir: ' .. (client.root_dir or 'nil'),
    '',
    '-- ═══════════════════════════════════════════════════════════════════════════',
    '-- CONFIG (passed to vim.lsp.start)',
    '-- ═══════════════════════════════════════════════════════════════════════════',
    '',
  }

  local config_str = format_value(client.config)
  for line in config_str:gmatch '[^\n]+' do
    table.insert(lines, line)
  end

  table.insert(lines, '')
  table.insert(lines, '-- ═══════════════════════════════════════════════════════════════════════════')
  table.insert(lines, '-- SERVER CAPABILITIES')
  table.insert(lines, '-- ═══════════════════════════════════════════════════════════════════════════')
  table.insert(lines, '')

  local caps_str = format_value(client.server_capabilities)
  for line in caps_str:gmatch '[^\n]+' do
    table.insert(lines, line)
  end

  table.insert(lines, '')
  table.insert(lines, '-- ═══════════════════════════════════════════════════════════════════════════')
  table.insert(lines, '-- SETTINGS (workspace/configuration)')
  table.insert(lines, '-- ═══════════════════════════════════════════════════════════════════════════')
  table.insert(lines, '')

  local settings_str = format_value(client.settings)
  for line in settings_str:gmatch '[^\n]+' do
    table.insert(lines, line)
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_name(buf, 'lsp://' .. client.name .. '/config')
  vim.bo[buf].modifiable = false
end

--- Prompt user to select an LSP client and show its configuration
function M.select_client()
  local clients = vim.lsp.get_clients()

  if #clients == 0 then
    vim.notify('No active LSP clients', vim.log.levels.WARN)
    return
  end

  vim.ui.select(clients, {
    prompt = 'Select LSP client:',
    format_item = function(client)
      local buf_count = vim.tbl_count(client.attached_buffers)
      return string.format('%s (id=%d, buffers=%d)', client.name, client.id, buf_count)
    end,
  }, function(client)
    if client then
      show_client_config(client)
    end
  end)
end

function M.setup()
  vim.api.nvim_create_user_command('LspInspect', M.select_client, {
    desc = 'Inspect active LSP client configuration',
  })

  require('user.menu').add_actions('LSP', {
    ['Inspect LSP Config'] = M.select_client,
  })
end

return M
