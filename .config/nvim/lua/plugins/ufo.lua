local handler = function(virtText, lnum, endLnum, width, truncate)
  local log = require 'ufo.lib.log'
  local newVirtText = {}
  local suffix = (' 󰁂 %d '):format(endLnum - lnum)
  local sufWidth = vim.fn.strdisplaywidth(suffix)
  local targetWidth = width - sufWidth
  local curWidth = 0
  for _, chunk in ipairs(virtText) do
    log.error('chunk', chunk)
    local chunkText = chunk[1]
    local chunkWidth = vim.fn.strdisplaywidth(chunkText)
    if targetWidth > curWidth + chunkWidth then
      table.insert(newVirtText, chunk)
    else
      chunkText = truncate(chunkText, targetWidth - curWidth)
      local hlGroup = chunk[2]
      table.insert(newVirtText, { chunkText, hlGroup })
      chunkWidth = vim.fn.strdisplaywidth(chunkText)
      -- str width returned from truncate() may less than 2nd argument, need padding
      if curWidth + chunkWidth < targetWidth then
        suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
      end
      break
    end
    curWidth = curWidth + chunkWidth
  end
  local _end = endLnum - 1
  local final_text = vim.trim(vim.api.nvim_buf_get_text(0, _end, 0, _end, -1, {})[1])
  table.insert(newVirtText, { ' ⋯ ' .. final_text })
  table.insert(newVirtText, { suffix, 'MoreMsg' })
  return newVirtText
end

local M = {
  'kevinhwang91/nvim-ufo',
  dependencies = { 'kevinhwang91/promise-async' },
  event = 'BufReadPost',
  keys = {
    { '<leader>fo', '<cmd>lua require("ufo").openAllFolds()<cr>' },
    { '<leader>fc', '<cmd>lua require("ufo").closeAllFolds()<cr>' },
    { '<leader>fp', '<cmd>lua require("ufo").peekFoldedLinesUnderCursor()<cr>' },
  },
  opts = {
    close_fold_kinds_for_ft = {
      default = { 'imports', 'comment' },
      json = { 'array' },
      c = { 'comment', 'region' },
    },
    open_fold_hl_timeout = 0,
    provider_selector = function()
      return { 'treesitter', 'indent' }
    end,
    fold_virt_text_handler = handler,
  },

  init = function()
    ---@diagnostic disable-next-line: inject-field
    vim.o.foldcolumn = '1' -- '0' is not bad
    ---@diagnostic disable-next-line: inject-field
    vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
    ---@diagnostic disable-next-line: inject-field
    vim.o.foldlevelstart = 99
    ---@diagnostic disable-next-line: inject-field
    vim.o.foldenable = true
  end,
}

return M
