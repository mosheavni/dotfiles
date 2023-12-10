local M = {
  'nvim-lualine/lualine.nvim',
  event = 'VeryLazy',
}

M.config = function()
  local lualine = require 'lualine'

  -- Color table for highlights
  -- stylua: ignore
  local colors = {
    bg       = '#202328',
    fg       = '#bbc2cf',
    aqua     = '#6EB0A3',
    yellow   = '#ECBE7B',
    cyan     = '#008080',
    darkblue = '#081633',
    green    = '#a9b665',
    orange   = '#FF8800',
    violet   = '#a9a1e1',
    magenta  = '#c678dd',
    blue     = '#51afef',
    red      = '#ec5f67',
  }

  local conditions = {
    buffer_not_empty = function()
      return vim.fn.empty(vim.fn.expand '%:t') ~= 1
    end,
    hide_in_width = function()
      return vim.fn.winwidth(0) > 80
    end,
    check_git_workspace = function()
      local filepath = vim.fn.expand '%:p:h'
      local gitdir = vim.fn.finddir('.git', filepath .. ';')
      return gitdir and #gitdir > 0 and #gitdir < #filepath
    end,
    is_yaml_ft = function()
      return vim.api.nvim_get_option_value('filetype', { buf = 0 }) == 'yaml'
    end,
  }

  local my_branch = { 'branch', icon = '', color = { fg = colors.violet, gui = 'bold' } }

  local borders = {
    left = {
      function()
        return '▊'
      end,
      color = { fg = colors.blue }, -- Sets highlighting of component
      padding = { left = 0, right = 1 }, -- We don't need space before this
    },
    right = {
      function()
        return '▊'
      end,
      color = { fg = colors.blue },
      padding = { left = 1 },
    },
  }

  local my_extensions = {
    telescope = {
      sections = {
        lualine_c = {
          borders.left,
          {
            function()
              return 'telescope'
            end,
            color = { fg = colors.red },
          },
        },
        lualine_x = { borders.right },
      },
      filetypes = { 'TelescopePrompt' },
    },

    nvimtree_self = {
      sections = {
        lualine_c = {
          borders.left,
          my_branch,
          {
            function()
              return '%='
            end,
          },
          {
            function()
              return vim.fn.fnamemodify(vim.fn.getcwd(), ':~')
            end,
            color = { fg = colors.aqua },
          },
        },
        lualine_x = { borders.right },
      },
      filetypes = { 'NvimTree' },
    },
  }

  -- lualine
  local config = {
    options = {
      -- Disable sections and component separators
      component_separators = '',
      section_separators = '',
      theme = {
        -- We are going to use lualine_c an lualine_x as left and
        -- right section. Both are highlighted by c theme .  So we
        -- are just setting default looks o statusline
        normal = { c = { fg = colors.fg, bg = colors.bg } },
        inactive = { c = { fg = colors.fg, bg = colors.bg } },
      },
      icons_enabled = true,
      always_divide_middle = true,
      globalstatus = true,
    },
    sections = {
      -- these are to remove the defaults
      lualine_a = {},
      lualine_b = {},
      lualine_y = {},
      lualine_z = {},
      -- These will be filled later
      lualine_c = {},
      lualine_x = {},
    },
    inactive_sections = {
      -- these are to remove the defaults
      lualine_a = {},
      lualine_b = {},
      lualine_y = {},
      lualine_z = {},
      lualine_c = {},
      lualine_x = {},
    },
    extensions = {
      'fugitive',
      'lazy',
      'nvim-dap-ui',
      'quickfix',
      'trouble',
      my_extensions.nvimtree_self,
      my_extensions.telescope,
    },
  }

  -- Inserts a component in lualine_c at left section
  local function ins_left(component)
    table.insert(config.sections.lualine_c, component)
  end

  -- Inserts a component in lualine_x at right section
  local function ins_right(component)
    table.insert(config.sections.lualine_x, component)
  end

  ------------------
  -- Left Section --
  ------------------
  ins_left(borders.left)

  ins_left {
    -- mode component
    'mode',
    fmt = function(str)
      return str:sub(1, 1)
    end,
    icon = '',
    color = function()
      local mode_color = {
        n = colors.red,
        i = colors.green,
        v = colors.blue,
        [''] = colors.blue,
        V = colors.blue,
        c = colors.magenta,
        no = colors.red,
        s = colors.orange,
        S = colors.orange,
        ic = colors.yellow,
        R = colors.violet,
        Rv = colors.violet,
        cv = colors.red,
        ce = colors.red,
        r = colors.cyan,
        rm = colors.cyan,
        ['r?'] = colors.cyan,
        ['!'] = colors.red,
        t = colors.cyan,
      }
      return { fg = mode_color[vim.fn.mode()] }
    end,
    padding = { right = 1 },
  }

  ins_left(my_branch)

  ins_left {
    'diff',
    symbols = { added = ' ', modified = '󰝤 ', removed = ' ' },
    cond = conditions.hide_in_width,
  }

  ins_left {
    'diagnostics',
    sources = { 'nvim_diagnostic' },
    symbols = { error = ' ', warn = ' ', info = ' ' },
    diagnostics_color = {
      color_error = { fg = colors.red },
      color_warn = { fg = colors.yellow },
      color_info = { fg = colors.cyan },
    },
  }

  ins_left {
    function()
      local schema = require('yaml-companion').get_buf_schema(0)
      if schema then
        return 'YAML Schema: ' .. schema.result[1].name
      end
    end,
    cond = conditions.is_yaml_ft,
  }

  --------------------
  -- Center Section --
  --------------------
  -- Insert mid section. You can make any number of sections in neovim :)
  -- for lualine it's any number greater then 2
  ins_left {
    function()
      return '%='
    end,
  }
  ins_left {
    'filename',
    cond = conditions.buffer_not_empty,
    color = { fg = colors.aqua, gui = 'bold' },
  }

  -------------------
  -- Right Section --
  -------------------
  ins_right {
    -- Lsp server name .
    function()
      local msg = 'No Active Lsp'
      local clients = vim.lsp.get_clients { bufnr = 0 }
      if next(clients) == nil then
        return msg
      end
      local all_client_names = {}
      for _, client in ipairs(clients) do
        table.insert(all_client_names, client.name)
      end
      return table.concat(all_client_names, ', ')
    end,
    icon = { ' LSP:', color = { fg = colors.green } },
    color = { fg = '#ffffff' },
  }
  ins_right {
    'fileformat',
    color = { fg = colors.aqua, gui = 'bold' },
  }
  ins_right { 'filetype' }

  ins_right { 'progress', color = { fg = colors.fg, gui = 'bold' } }

  ins_right { 'location' }

  ins_right {
    function()
      return require('lazy').stats().startuptime
    end,
    color = function()
      local time = require('lazy').stats().startuptime
      if time > 120 then
        return { fg = colors.red }
      elseif time > 90 then
        return { fg = colors.orange }
      elseif time > 60 then
        return { fg = colors.yellow }
      else
        return { fg = colors.green }
      end
    end,
  }

  ins_right(borders.right)

  -- setup
  lualine.setup(config)
end

return M
