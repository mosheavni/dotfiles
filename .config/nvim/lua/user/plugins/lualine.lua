local status_ok, lualine = pcall(require, 'lualine')
if not status_ok then
  return vim.notify 'Module lualine not installed'
end

local navic = require 'nvim-navic'

-- Truncate items on a small window
--- @param trunc_width any #Number trunctates component when screen width is less then trunc_width
--- @param trunc_len any #Number truncates component to trunc_len number of chars
--- @param hide_width any #Number hides component when window width is smaller then hide_width
--- @param no_ellipsis any #Boolean whether to disable adding '...' at end after truncation
--- @return function that can format the component accordingly
local function trunc(trunc_width, trunc_len, hide_width, no_ellipsis)
  return function(str)
    local win_width = vim.fn.winwidth(0)
    if hide_width and win_width < hide_width then
      return ''
    elseif trunc_width and trunc_len and win_width < trunc_width and #str > trunc_len then
      return str:sub(1, trunc_len) .. (no_ellipsis and '' or '...')
    end
    return str
  end
end

-- lualine
lualine.setup {
  options = {
    icons_enabled = true,
    theme = 'onedark',
    component_separators = { left = '', right = '' },
    section_separators = { left = '', right = '' },
    disabled_filetypes = {
      winbar = { 'fugitive', 'git', 'NvimTree' },
    },
    always_divide_middle = true,
    globalstatus = true,
  },
  sections = {
    lualine_a = { { 'mode', fmt = trunc(80, 4, nil, true) } },
    lualine_b = {
      'branch',
      'diff',
    },
    lualine_c = {
      'diagnostics',
      'filename',
      function()
        if vim.bo.filetype == 'yaml' then
          local schema = require('yaml-companion').get_buf_schema(0)
          if schema then
            return 'YAML Schema: ' .. schema.result[1].name
          end
        end
        return ''
      end,
    },
    lualine_x = {
      {
        -- Lsp server name .
        function()
          local msg = 'No Active Lsp'
          local clients = vim.lsp.get_active_clients { bufnr = 0 }
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
      'encoding',
      'fileformat',
      'filetype',
    },
    lualine_y = { 'progress' },
    lualine_z = {
      'location',
      function()
        return os.date '%H:%M'
      end,
    },
  },
  inactive_sections = {
    lualine_a = { { 'mode', fmt = trunc(80, 4, nil, true) } },
    lualine_b = {},
    lualine_c = { 'filename' },
    lualine_x = { 'location' },
    lualine_y = {},
    lualine_z = {},
  },
  tabline = {},
  winbar = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_z = {
      {
        function()
          local location = navic.get_location()
          return navic.is_available() and location ~= '' and location or ''
        end,
      },
    },
  },
  inactive_winbar = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_y = { 'modified' },
    lualine_z = { 'filename' },
  },
  extensions = {
    'fugitive',
    'nvim-dap-ui',
    'nvim-tree',
    'quickfix',
  },
}
