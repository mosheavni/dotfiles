local M = {
  'nvim-lualine/lualine.nvim',
  event = 'VeryLazy',
}

M.config = function()
  local lualine = require 'lualine'

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

  local colors = {
    blue = '#80a0ff',
    cyan = '#79dac8',
    black = '#080808',
    white = '#c6c6c6',
    whiter = '#fafafa',
    red = '#ff5189',
    violet = '#8683e8',
    grey = '#303030',
    light_grey = '#505050',
  }

  local one_dark_theme = require 'lualine.themes.onedark'
  one_dark_theme.visual.a.bg = one_dark_theme.normal.a.bg
  one_dark_theme.normal.a.bg = colors.violet
  one_dark_theme.normal.b.bg = colors.light_grey
  one_dark_theme.normal.b.fg = colors.whiter

  -- lualine
  lualine.setup {
    options = {
      icons_enabled = true,
      theme = 'auto',
      -- theme = one_dark_theme,
      component_separators = '|',
      section_separators = { right = '', left = '' },
      disabled_filetypes = {
        winbar = { 'fugitive', 'git', 'NvimTree' },
      },
      always_divide_middle = true,
      globalstatus = true,
    },
    sections = {
      lualine_a = {
        {
          'mode',
          fmt = function(mode)
            return mode:sub(1, 1):upper()
          end,
          separator = { left = '', right = '' },
          left_padding = 2,
          right_padding = 2,
        },
      },
      lualine_b = {
        'branch',
        'diff',
      },
      lualine_c = {
        'filename',
        'diagnostics',
        function()
          if vim.api.nvim_buf_get_option(0, 'filetype') == 'yaml' then
            local schema = require('yaml-companion').get_buf_schema(0)
            if schema then
              return 'YAML Schema: ' .. schema.result[1].name
            end
          end
          return ''
        end,
        {
          separator = { left = '', right = '' },
          left_padding = 2,
          right_padding = 2,
        },
      },
      lualine_x = {},
      lualine_y = {
        {
          -- Lsp server name .
          function()
            local msg = 'No Active Lsp'
            ---@diagnostic disable-next-line: deprecated
            local clients = vim.lsp.get_active_clients { bufnr = 0 }
            if #clients == 0 then
              return msg
            end
            local all_client_names = {}
            for _, client in ipairs(clients) do
              ---@diagnostic disable-next-line: undefined-field
              table.insert(all_client_names, client.name)
            end
            return table.concat(all_client_names, ', ')
          end,
          icon = ' ',
          color = { fg = colors.whiter, gui = 'bold' },
        },
        'fileformat',
        'filetype',
        'progress',
      },
      lualine_z = {
        '%l/%L',
        'searchcount',
        {
          function()
            return require('lazy').stats().startuptime
          end,
          -- cond = require('lazy.status').has_updates,
          separator = { right = '' },
          left_padding = 2,
        },
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
    -- winbar = {
    --   lualine_a = {},
    --   lualine_b = {},
    --   lualine_c = {},
    --   lualine_y = { 'modified' },
    --   lualine_z = { 'filename' },
    -- },
    extensions = {
      'fugitive',
      'nvim-dap-ui',
      'nvim-tree',
      'quickfix',
    },
  }
end

return M
