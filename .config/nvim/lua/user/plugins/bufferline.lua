local get_hex = require('cokeline/utils').get_hex
local colors = {
  blue = '#80a0ff',
  cyan = '#79dac8',
  black = '#080808',
  white = '#c6c6c6',
  whiter = '#fafafa',
  red = '#ff5189',
  violet = '#d183e8',
  grey = '#303030',
  light_grey = '#505050',
}

local bg_func = function(buffer)
  return buffer.is_focused and colors.violet or colors.light_grey
end
require('cokeline').setup {
  default_hl = {
    fg = function(buffer)
      return buffer.is_focused and colors.grey or colors.white
    end,
    bg = bg_func,
  },
  buffers = {
    filter_valid = function(buffer)
      return buffer.type ~= 'nowrite'
    end,
  },
  components = {
    {
      text = ' ',
      bg = get_hex('Normal', 'bg'),
    },
    {
      text = '',
      bg = get_hex('Normal', 'bg'),
      fg = bg_func,
    },
    {
      text = function(buffer)
        return buffer.devicon.icon
      end,
      fg = function(buffer)
        return buffer.devicon.color
      end,
    },
    {
      text = ' ',
    },
    {
      text = function(buffer)
        local is_modified = buffer.is_modified and '' or ''
        return buffer.filename .. ' ' .. is_modified .. '  '
      end,
      style = function(buffer)
        return buffer.is_focused and 'bold' or nil
      end,
    },
    {
      text = function(buffer)
        return buffer.is_modified and '●' or ''
      end,
      delete_buffer_on_left_click = true,
    },
    {
      text = '',
      bg = get_hex('Normal', 'bg'),
      fg = bg_func,
    },
  },
}
