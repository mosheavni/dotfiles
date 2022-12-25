local utils = require 'user.utils'
local autocmd = utils.autocmd
local augroup = utils.augroup
local nnoremap = utils.nnoremap
local fn = vim.fn
local cmd = vim.cmd
local api = vim.api

-- Auto reload file
local reload_file_group = augroup 'ReloadFile'
autocmd({ 'FocusGained', 'BufEnter' }, {
  desc = 'Auto load file changes when focus or buffer is entered',
  group = reload_file_group,
  pattern = '*',
  command = 'if &buftype == "nofile" | checktime | endif',
})

-- Actions when the file is changed outside of Neovim
autocmd('FileChangedShellPost', {
  desc = 'Actions when the file is changed outside of Neovim',
  group = reload_file_group,
  callback = function()
    vim.notify('File changed, reloading the buffer', vim.log.levels.WARN)
  end,
})

-- Print the output of flag --startuptime startuptime.txt
local first_load = augroup 'first_load'
autocmd('UIEnter', {
  desc = 'Print the output of flag --startuptime startuptime.txt',
  group = first_load,
  pattern = '*',
  once = true,
  callback = function()
    vim.defer_fn(function()
      return vim.fn.filereadable 'startuptime.txt' == 1 and vim.cmd ':!tail -n3 startuptime.txt' and vim.fn.delete 'startuptime.txt'
    end, 1000)
  end,
})

-- Buffer settings
local buffer_settings = augroup 'buffer_settings'
autocmd('FileType', {
  desc = 'Quit with q in this filetypes',
  group = buffer_settings,
  pattern = {
    'help',
    'lspinfo',
    'man',
    'netrw',
    'qf',
    'startuptime',
  },
  callback = function()
    nnoremap('q', '<CMD>close<CR>', { buffer = 0 })
  end,
})
autocmd('BufEnter', {
  pattern = { '*' },
  group = buffer_settings,
  command = 'normal zx',
})

-- Highlight on yank
autocmd('TextYankPost', {
  desc = 'Highlight on yank',
  group = buffer_settings,
  callback = function()
    pcall(vim.highlight.on_yank, { higroup = 'IncSearch', timeout = 700 })
  end,
})

-- Special filetypes
local special_filetypes = augroup 'SpecialFiletype'
autocmd({ 'FileType' }, {
  group = special_filetypes,
  pattern = 'json',
  command = 'syntax match Comment +\\/\\/.\\+$+',
})
autocmd({ 'BufNewFile', 'BufRead' }, {
  group = special_filetypes,
  pattern = 'aliases.sh',
  command = 'setf zsh',
})
autocmd({ 'BufNewFile', 'BufRead' }, {
  group = special_filetypes,
  pattern = '.eslintrc',
  command = 'setf json',
})
autocmd({ 'BufRead', 'BufNewFile' }, {
  group = special_filetypes,
  pattern = { '*/templates/*.yaml', '*/templates/*.tpl', '*.gotmpl', 'helmfile.yaml' },
  command = 'set ft=helm',
})
autocmd({ 'FileType' }, {
  group = special_filetypes,
  pattern = 'javascript',
  command = 'set filetype=javascriptreact | set iskeyword+=-',
})
autocmd({ 'FileType' }, {
  group = special_filetypes,
  pattern = 'nginx',
  command = 'setlocal iskeyword+=$',
})
autocmd({ 'BufRead' }, {
  group = special_filetypes,
  pattern = '*/plugins/init.lua',
  command = 'lua require("user.open-url").setup()',
})

-- Last position on Document
local last_position = augroup 'LastPosition'
autocmd({ 'BufReadPost' }, {
  group = last_position,
  callback = function()
    local test_line_data = api.nvim_buf_get_mark(0, '"')
    local test_line = test_line_data[1]
    local last_line = api.nvim_buf_line_count(0)

    if test_line > 0 and test_line <= last_line then
      api.nvim_win_set_cursor(0, test_line_data)
    end
  end,
})

-- Quickfix
local quickfix_au = augroup 'QuickFix'
autocmd({ 'QuickFixCmdPost' }, {
  group = quickfix_au,
  pattern = 'l*',
  command = 'lopen',
  desc = 'Open location window on location action',
})
autocmd({ 'QuickFixCmdPost' }, {
  group = quickfix_au,
  pattern = [[[^l]*]],
  command = 'copen',
  desc = 'Open quickfix window on quickfix action',
})
autocmd({ 'FileType' }, {
  group = quickfix_au,
  pattern = 'qf',
  callback = function()
    local open_quickfix = function(new_split_cmd)
      local qf_idx = fn.line '.'
      cmd 'wincmd p'
      cmd(new_split_cmd)
      cmd(qf_idx .. 'cc')
    end
    nnoremap('<c-v>', function()
      open_quickfix 'vnew'
    end, { buffer = true })

    nnoremap('<c-x>', function()
      open_quickfix 'split'
    end, { buffer = true })
    -- "n", "<C-v>", :call <SID>OpenQuickfix("vnew")<CR>
    -- "n", "<C-x>", :call <SID>OpenQuickfix("split")<CR>
  end,
  desc = 'Open quickfix window on quickfix action',
})
