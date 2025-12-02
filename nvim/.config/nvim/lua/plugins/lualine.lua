local M = {
  'nvim-lualine/lualine.nvim',
  event = 'VeryLazy',
}

M.config = function()
  local lualine = require 'lualine'

  local palette = require 'rose-pine.palette'
  local colors = {
    bg = palette.base,
    fg = palette.text,
    aqua = palette.rose, -- Changed to rose for better contrast
    yellow = palette.gold,
    cyan = palette.foam, -- Changed to foam for better visibility
    darkblue = palette.surface,
    green = palette.pine,
    orange = palette.iris, -- Changed to iris for better distinction
    violet = palette.iris,
    magenta = palette.rose, -- Changed to rose for consistency
    blue = palette.foam,
    red = palette.love,
  }

  local conditions = {
    buffer_not_empty = function()
      return vim.fn.empty(vim.fn.expand '%:t') ~= 1
    end,
    hide_in_width = function()
      return vim.fn.winwidth(0) > 80
    end,
    is_yaml_ft = function()
      return vim.api.nvim_get_option_value('filetype', { buf = 0 }) == 'yaml'
    end,
  }

  local my_branch = { 'branch', icon = '', color = { fg = colors.aqua, gui = 'bold' } }

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
    nvimtree_self = {
      sections = {
        lualine_c = {
          borders.left,
          {
            function()
              return '-'
            end,
            icon = '',
            padding = { right = 1 },
          },
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
        lualine_x = {
          {
            function()
              return 'Marks: ' .. vim.tbl_count(require('nvim-tree.api').marks.list())
            end,
            color = { fg = '#ffffff' },
          },
          borders.right,
        },
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
      theme = 'auto',
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
      lualine_c = {},
      lualine_x = {},
      lualine_y = {},
      lualine_z = {},
    },
    extensions = {
      'fugitive',
      'lazy',
      'nvim-dap-ui',
      'quickfix',
      'trouble',
      my_extensions.nvimtree_self,
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
        n = palette.rose, -- Normal mode
        i = palette.pine, -- Insert mode
        v = palette.foam, -- Visual mode
        [''] = palette.foam, -- Visual block
        V = palette.foam, -- Visual line
        c = palette.love, -- Command mode
        no = palette.love, -- Normal operator pending
        s = palette.gold, -- Select mode
        S = palette.gold, -- Select line
        ic = palette.iris, -- Insert completion
        R = palette.iris, -- Replace mode
        Rv = palette.iris, -- Virtual replace
        cv = palette.love, -- Ex mode
        ce = palette.love, -- Normal ex
        r = palette.foam, -- Hit-enter prompt
        rm = palette.foam, -- More prompt
        ['r?'] = palette.foam, -- Confirm
        ['!'] = palette.love, -- Shell
        t = palette.pine, -- Terminal
      }
      return { fg = mode_color[vim.fn.mode()] }
    end,
    padding = { right = 1 },
  }

  ins_left(my_branch)

  ins_left {
    'diff',
    symbols = { added = ' ', modified = ' ', removed = ' ' },
    cond = conditions.hide_in_width,
  }

  ins_left {
    'diagnostics',
    sources = { 'nvim_diagnostic' },
    symbols = { error = ' ', warn = ' ', info = ' ' },
    diagnostics_color = {
      color_error = { fg = palette.love },
      color_warn = { fg = palette.gold },
      color_info = { fg = palette.foam },
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
    color = { fg = 'subtle', gui = 'bold' },
  }

  -------------------
  -- Right Section --
  -------------------
  ins_right {
    -- Lsp server name .
    function()
      local clients = vim.lsp.get_clients { bufnr = 0 }
      if not next(clients) then
        return 'No Active Lsp'
      end
      return 'LSP: ' .. table.concat(
        vim.tbl_map(function(client)
          return client.name
        end, clients),
        ', '
      )
    end,
    icon = { ' ', color = { fg = colors.green } },
    color = { fg = '#ffffff' },
  }
  ins_right {
    'fileformat',
    color = { fg = colors.aqua, gui = 'bold' },
  }
  ins_right { 'filetype' }

  ins_right { 'progress', color = { fg = colors.fg, gui = 'bold' } }

  ins_right { 'location' }

  local startup_time = require('lazy').stats().startuptime
  ins_right {
    function()
      return startup_time
    end,
    color = function()
      local time = startup_time
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
