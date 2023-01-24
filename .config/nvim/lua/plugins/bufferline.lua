local M = {
  'noib3/nvim-cokeline',
  event = 'BufReadPre',
  enabled = false,
}

M.config = function()
  local utils = require 'user.utils'
  local nnoremap = utils.nnoremap
  local get_hex = require('cokeline/utils').get_hex
  local is_picking_focus = require('cokeline/mappings').is_picking_focus
  local is_picking_close = require('cokeline/mappings').is_picking_close
  local colors = {
    blue = '#80a0ff',
    cyan = '#79dac8',
    black = '#080808',
    white = '#c6c6c6',
    whiter = '#fafafa',
    red = '#ff5189',
    violet = '#a583e8',
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
        return buffer.type ~= 'nowrite' and buffer.type ~= 'nofile'
      end,
    },
    sidebar = {
      filetype = 'NvimTree',
      components = {
        {
          text = '',
          fg = vim.g.terminal_color_3,
          bg = get_hex('NvimTreeNormal', 'bg'),
        },
        {
          text = '  NvimTree  ',
          bg = vim.g.terminal_color_3,
          fg = get_hex('NvimTreeNormal', 'bg'),
          style = 'bold',
        },
        {
          text = '',
          fg = vim.g.terminal_color_3,
          bg = get_hex('NvimTreeNormal', 'bg'),
        },
      },
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
          return (is_picking_focus() or is_picking_close()) and buffer.pick_letter .. ' ' or buffer.devicon.icon
        end,
        fg = function(buffer)
          return (is_picking_focus() and yellow) or (is_picking_close() and red) or buffer.devicon.color
        end,
        style = function(_)
          return (is_picking_focus() or is_picking_close()) and 'italic,bold' or nil
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

  nnoremap('<leader>`', '<Plug>(cokeline-pick-focus)', true)
  nnoremap('<leader>1', '<Plug>(cokeline-focus-1)', true)
  nnoremap('<leader>2', '<Plug>(cokeline-focus-2)', true)
  nnoremap('<leader>3', '<Plug>(cokeline-focus-3)', true)
  nnoremap('<leader>4', '<Plug>(cokeline-focus-4)', true)
  nnoremap('<leader>5', '<Plug>(cokeline-focus-5)', true)
  nnoremap('<leader>6', '<Plug>(cokeline-focus-6)', true)
  nnoremap('<leader>7', '<Plug>(cokeline-focus-7)', true)
  nnoremap('<leader>8', '<Plug>(cokeline-focus-8)', true)
end

return M
