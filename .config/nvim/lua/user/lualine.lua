local status_ok, lualine = pcall(require, "lualine")
if not status_ok then
  return vim.notify('Module lualine not installed')
end

local gps_status_ok, gps = pcall(require, "nvim-gps")
if not gps_status_ok then
  return vim.notify('Module nvim-gps not installed')
end
-- lualine
lualine.setup({
  options = {
    icons_enabled = true,
    theme = 'onedark',
    component_separators = { left = '', right = '' },
    section_separators = { left = '', right = '' },
    disabled_filetypes = {},
    always_divide_middle = true,
    globalstatus = true,
  },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = {
      'branch',
      'diff',
    },
    lualine_c = {
      'diagnostics',
      function()
        return require('lsp-status').status()
      end,
      "require'user.select-schema'.get_current_schema()",
      { gps.get_location, cond = gps.is_available },
    },
    lualine_x = {
      {
        -- Lsp server name .
        function()
          local msg = 'No Active Lsp'
          local clients = vim.lsp.get_active_clients({bufnr = 0})
          if #clients == 0 then
            return msg
          end
          local all_client_names = {}
          for _, client in ipairs(clients) do
            table.insert(all_client_names, client.name)
          end
          return table.concat(all_client_names, ', ')
        end,
        icon = ' LSP:',
        color = { fg = '#ffffff', gui = 'bold' },
      },
      'encoding', 'fileformat', 'filetype',
    },
    lualine_y = { 'progress' },
    lualine_z = { 'location' }
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { 'filename' },
    lualine_x = { 'location' },
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  extensions = {
    'nerdtree',
    'fugitive'
  }
})

-- lsp status.
local status_ok, lsp_status = pcall(require, "lsp-status")
if not status_ok then
  return
end

lsp_status.register_progress()
lsp_status.config({
  diagnostics = false
})
