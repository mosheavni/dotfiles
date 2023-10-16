local utils = require 'user.utils'
local autocmd = utils.autocmd
local augroup = utils.augroup
local nnoremap = utils.nnoremap
local fn = vim.fn
local cmd = vim.cmd

local reload_file_group = augroup 'ReloadFile'
autocmd({ 'FocusGained', 'BufEnter' }, {
  desc = 'Auto load file changes when focus or buffer is entered',
  group = reload_file_group,
  pattern = '*',
  command = 'if &buftype == "nofile" | checktime | endif',
})

autocmd('FileChangedShellPost', {
  desc = 'Actions when the file is changed outside of Neovim',
  group = reload_file_group,
  callback = function()
    vim.notify('File changed, reloading the buffer', vim.log.levels.WARN)
  end,
})

local first_load = augroup 'first_load'
autocmd('UIEnter', {
  desc = 'Print the output of flag --startuptime startuptime.txt',
  group = first_load,
  pattern = '*',
  once = true,
  callback = function()
    vim.defer_fn(function()
      if vim.fn.filereadable 'startuptime.txt' == 1 then
        local tail = vim.fn.system { 'tail', '-n3', 'startuptime.txt' }
        vim.notify(tail)
        return vim.fn.delete 'startuptime.txt'
      else
        return false
      end
    end, 1500)
  end,
})

autocmd('User', {
  desc = 'Setup non-critical stuff after lazy has loaded',
  group = first_load,
  pattern = 'VeryLazy',
  callback = function()
    require('user.menu').setup()
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
  group = buffer_settings,
  pattern = { '*' },
  command = 'normal zx',
})

autocmd('TextYankPost', {
  desc = 'Highlight on yank',
  group = buffer_settings,
  callback = function()
    pcall(vim.highlight.on_yank, { higroup = 'IncSearch', timeout = 700 })
  end,
})

vim.api.nvim_create_autocmd('BufReadPost', {
  desc = 'go to last loc when opening a buffer',
  group = buffer_settings,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Special filetypes
local special_filetypes = augroup 'SpecialFiletype'
autocmd({ 'FileType' }, {
  group = special_filetypes,
  pattern = 'json',
  command = 'syntax match Comment +\\/\\/.\\+$+',
})
autocmd({ 'FileType' }, {
  group = special_filetypes,
  pattern = 'javascript',
  command = 'set iskeyword+=-',
})
autocmd({ 'FileType' }, {
  group = special_filetypes,
  pattern = 'nginx',
  command = 'setlocal iskeyword+=$',
})
autocmd({ 'BufRead' }, {
  group = special_filetypes,
  pattern = '*/plugins/*.lua',
  command = 'lua require("user.open-url").setup()',
})

-- Quickfix
local quickfix_au = augroup 'QuickFix'
autocmd({ 'QuickFixCmdPost' }, {
  desc = 'Open location window on location action',
  group = quickfix_au,
  pattern = 'l*',
  command = 'lopen',
})
autocmd({ 'QuickFixCmdPost' }, {
  desc = 'Open quickfix window on quickfix action',
  group = quickfix_au,
  pattern = [[[^l]*]],
  command = 'copen',
})
autocmd({ 'FileType' }, {
  desc = 'Open quickfix results in a new split',
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
})

-- custom settings
local CustomSettingsGroup = augroup 'CustomSettingsGroup'
autocmd('BufWritePost', {
  group = CustomSettingsGroup,
  pattern = '*',
  callback = function(args)
    local shebang = vim.api.nvim_buf_get_lines(0, 0, 1, true)[1]
    if not shebang or not shebang:match '^#!.+' then
      return
    end
    local filename = vim.api.nvim_buf_get_name(args.buf)
    ---@diagnostic disable-next-line: undefined-field
    local fileinfo = vim.uv.fs_stat(filename)
    if not fileinfo or bit.band(fileinfo.mode - 32768, 0x40) ~= 0 then
      return
    end

    vim.notify 'File made executable'
    ---@diagnostic disable-next-line: undefined-field
    vim.uv.fs_chmod(filename, bit.bor(fileinfo.mode, 493))
  end,
  once = false,
  desc = 'Mark script files with shebangs as executable on write.',
})
