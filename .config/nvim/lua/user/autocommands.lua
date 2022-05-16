local utils = require 'user.utils'
local autocmd = utils.autocmd
local augroup = utils.augroup
local opts = utils.map_opts

-- Auto reload file
local reload_file_group = augroup('ReloadFile')
autocmd({ 'FocusGained', 'BufEnter' }, {
  desc = 'Auto load file changes when focus or buffer is entered',
  group = reload_file_group,
  pattern = '*',
  command = 'if &buftype == "nofile" | checktime | endif'
})

-- Special filetypes
local special_filetypes = augroup('SpecialFiletype')
autocmd({ "FileType" }, {
  group = special_filetypes,
  pattern = 'json',
  command = 'syntax match Comment +\\/\\/.\\+$+'
})
autocmd({ "BufNewFile", "BufRead" }, {
  group = special_filetypes,
  pattern = "aliases.sh",
  command = "setf zsh"
})
autocmd({ "BufNewFile", "BufRead" }, {
  group = special_filetypes,
  pattern = ".eslintrc",
  command = "setf json"
})
autocmd({ "BufNewFile", "BufRead" }, {
  group = special_filetypes,
  pattern = "*.hcl",
  command = "setf terraform"
})
autocmd({ "BufRead", "BufNewFile" }, {
  group = special_filetypes,
  pattern = { "*/templates/*.yaml", "*/templates/*.tpl", "*.gotmpl", "helmfile.yaml" },
  command = "set ft=helm"
})
autocmd({ "FileType" }, {
  group = special_filetypes,
  pattern = "javascript",
  command = "set filetype=javascriptreact | set iskeyword+=-"
})
autocmd({ "FileType" }, {
  group = special_filetypes,
  pattern = "nginx",
  command = "setlocal iskeyword+=$ | let b:coc_additional_keywords = ['$']"
})
autocmd({ 'BufWritePost' }, {
  group = special_filetypes,
  pattern = 'plugins.lua',
  command = 'source <afile> | PackerCompile',
})

-- Nvim Blame Line
-- local nvim_blame_line = augroup('NvimBlameLine')
-- autocmd({ 'BufEnter' }, {
--   group = nvim_blame_line,
--   pattern = '*',
--   command = 'EnableBlameLine'
-- })

-- bulb
local bulb = augroup('BulbAu')
autocmd({ 'CursorHold', 'CursorHoldI' }, {
  group = bulb,
  pattern = '*',
  callback = function()
    require 'nvim-lightbulb'.update_lightbulb()
  end
})

-- Quickfix
local quickfix_au = augroup('QuickFix')
autocmd({ 'QuickFixCmdPost' }, {
  group = quickfix_au,
  pattern = 'l*',
  command = 'lopen',
  desc = 'Open location window on location action'
})
autocmd({ 'QuickFixCmdPost' }, {
  group = quickfix_au,
  pattern = [[[^l]*]],
  command = 'copen',
  desc = 'Open quickfix window on quickfix action'
})
autocmd({ 'FileType' }, {
  group = quickfix_au,
  pattern = "qf",
  callback = function()
    local open_quickfix = function(new_split_cmd)
      local qf_idx = vim.fn.line('.')
      vim.cmd 'wincmd p'
      vim.cmd(new_split_cmd)
      vim.cmd(qf_idx .. 'cc')
    end
    vim.keymap.set("n", "<c-v>", function()
      open_quickfix('vnew')
    end, vim.tbl_extend('force', { buffer = true }, opts.no_remap))

    vim.keymap.set("n", "<c-x>", function()
      open_quickfix('split')
    end, vim.tbl_extend('force', { buffer = true }, opts.no_remap))
    -- "n", "<C-v>", :call <SID>OpenQuickfix("vnew")<CR>
    -- "n", "<C-x>", :call <SID>OpenQuickfix("split")<CR>
  end,
  desc = 'Open quickfix window on quickfix action'
})
