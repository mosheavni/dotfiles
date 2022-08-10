local status_ok, lualine = pcall(require, 'lualine')
if not status_ok then
  return vim.notify 'Module lualine not installed'
end

local gps_status_ok, gps = pcall(require, 'nvim-gps')
if not gps_status_ok then
  return vim.notify 'Module nvim-gps not installed'
end

-- lsp status.
local status_ok_lsps, lsp_status = pcall(require, 'lsp-status')
if not status_ok_lsps then
  return vim.notify 'Module lsp-status not installed'
end

lsp_status.register_progress()
lsp_status.config {
  diagnostics = false,
}

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
    theme = 'neon',
    component_separators = { left = '', right = '' },
    section_separators = { left = '', right = '' },
    disabled_filetypes = {},
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
      {
        function()
          return lsp_status.status()
        end,
        fmt = trunc(120, 20, 60),
      },
      "require'user.select-schema'.get_current_schema()",
      { gps.get_location, cond = gps.is_available },
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
    lualine_z = { 'location' },
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { 'filename' },
    lualine_x = { 'location' },
    lualine_y = {},
    lualine_z = {},
  },
  tabline = {},
  extensions = {
    'nerdtree',
    'fugitive',
    'quickfix',
  },
}
