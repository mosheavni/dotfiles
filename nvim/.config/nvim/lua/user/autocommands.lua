local autocmd = vim.api.nvim_create_autocmd

-- Check if we need to reload the file when it changed
local reload_file_group = vim.api.nvim_create_augroup('ReloadFile', { clear = true })
autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
  group = reload_file_group,
  callback = function()
    if vim.o.buftype ~= 'nofile' then
      vim.cmd 'checktime'
    end
  end,
})

autocmd('FileChangedShellPost', {
  desc = 'Reload when the file is changed outside of Neovim',
  group = reload_file_group,
  callback = function()
    vim.notify('File changed, reloading the buffer', vim.log.levels.WARN)
  end,
})

local first_load = vim.api.nvim_create_augroup('FirstLoad', { clear = true })
autocmd('UIEnter', {
  desc = 'Print the output of flag --startuptime startuptime.txt',
  group = first_load,
  pattern = '*',
  once = true,
  callback = function()
    vim.defer_fn(function()
      if vim.fn.filereadable 'startuptime.txt' == 1 then
        local tail = vim.system({ 'tail', '-n3', 'startuptime.txt' }, { text = true }):wait().stdout
        ---@diagnostic disable-next-line: param-type-mismatch
        vim.notify(tail)
        return vim.fn.delete 'startuptime.txt'
      else
        return false
      end
    end, 1500)
  end,
})

-- Deferred plugin setup
autocmd('User', {
  desc = 'Setup non-critical stuff after deferred plugins load',
  group = first_load,
  pattern = 'DeferredPluginsLoaded',
  callback = function()
    require('user.menu').setup()
    require('user.projects').setup()
    require('user.navic').setup()
    require('user.input').setup()
    require('user.search-count').setup()
    require('user.tabular-v2').setup()
    require('user.number-separators').setup()
    require('user.terminal').setup()
    require('user.yank-ring').setup()
    require('user.run-buffer').setup()
    require('user.grep').setup()
    require('user.lister').setup()
    require('user.figlet').setup()
    require('user.open-url').setup()
    require('user.gitbrowse').setup()
    require('user.easymotion').setup()
    require('user.conflicts').setup()
  end,
})

-- Buffer settings
local buffer_settings = vim.api.nvim_create_augroup('BufferSettings', { clear = true })
autocmd('FileType', {
  desc = 'Quit with q in this filetypes',
  group = buffer_settings,
  pattern = {
    'PlenaryTestPopup',
    'checkhealth',
    'help',
    'lspinfo',
    'man',
    'neotest-output',
    'neotest-output-panel',
    'neotest-summary',
    'netrw',
    'notify',
    'qf',
    'spectre_panel',
    'startuptime',
    'tsplayground',
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = event.buf, silent = true })
  end,
})
autocmd('FileType', {
  pattern = 'cmp_docs',
  group = buffer_settings,
  callback = function()
    vim.treesitter.start(0, 'markdown')
  end,
})
autocmd({ 'TextYankPost', 'TextPutPost' }, {
  desc = 'Highlight on yank/put',
  group = buffer_settings,
  callback = function()
    vim.hl.hl_op { higroup = 'IncSearch', timeout = 200 }
  end,
})

-- resize splits if window got resized
autocmd({ 'VimResized' }, {
  group = buffer_settings,
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd 'tabdo wincmd ='
    vim.cmd('tabnext ' .. current_tab)
  end,
})

-- Special filetypes
local special_filetypes = vim.api.nvim_create_augroup('SpecialFiletypes', { clear = true })
autocmd({ 'FileType' }, {
  group = special_filetypes,
  pattern = 'json',
  command = 'syntax match Comment +\\/\\/.\\+$+',
})
autocmd({ 'FileType' }, {
  group = special_filetypes,
  pattern = 'javascript',
  command = 'setlocal iskeyword+=-',
})
autocmd({ 'FileType' }, {
  group = special_filetypes,
  pattern = 'nginx',
  command = 'setlocal iskeyword+=$',
})
autocmd({ 'FileType' }, {
  group = special_filetypes,
  pattern = { 'markdown', 'gitcommit', 'text' },
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.spelllang = { 'en' }
    vim.api.nvim_set_hl(0, 'SpellBad', {
      undercurl = true,
      sp = '#ff5555', -- curl color
    })
  end,
})

-- Quickfix
local quickfix_au = vim.api.nvim_create_augroup('QuickFixAu', { clear = true })
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

-- autocmd for terminal buffers
local term_au = vim.api.nvim_create_augroup('MosheTerm', { clear = true })
autocmd({ 'TermOpen' }, {
  group = term_au,
  pattern = '*',
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.cmd.startinsert()
  end,
})

-- custom settings
local custom_settings_group = vim.api.nvim_create_augroup('CustomSettingsGroup', { clear = true })
autocmd('BufWritePost', {
  group = custom_settings_group,
  desc = 'make sh file executable if a shebang is deteced',
  pattern = '*',
  callback = function(args)
    local shebang = vim.api.nvim_buf_get_lines(args.buf, 0, 1, true)[1]
    if not shebang or not shebang:match '^#!.+' then
      return
    end
    local filename = vim.api.nvim_buf_get_name(args.buf)
    if filename == '' then
      return
    end
    ---@diagnostic disable-next-line: undefined-field
    local fileinfo = vim.uv.fs_stat(filename)
    if not fileinfo or vim.uv.fs_access(filename, 'X') then
      return
    end
    ---@diagnostic disable-next-line: undefined-global
    -- selene: allow(undefined_variable)
    if vim.uv.fs_chmod(filename, bit.bor(fileinfo.mode, 493)) then
      vim.notify 'File made executable'
    end
  end,
  once = false,
})

-- CursorLine only in current window
local cursorline_group = vim.api.nvim_create_augroup('CursorLineCurrentWindow', { clear = true })
autocmd({ 'WinEnter', 'BufWinEnter' }, {
  group = cursorline_group,
  callback = function()
    vim.opt_local.cursorline = true
  end,
})
autocmd('WinLeave', {
  group = cursorline_group,
  callback = function()
    if vim.bo.filetype == 'qf' then
      return
    end
    vim.opt_local.cursorline = false
  end,
})

local report_cwd_group = vim.api.nvim_create_augroup('ReportCwd', { clear = true })
autocmd({ 'VimEnter', 'DirChanged' }, {
  group = report_cwd_group,
  desc = 'Report cwd to terminal via OSC 7',
  callback = function()
    io.stdout:write(string.format('\027]7;file://%s%s\027\\', vim.fn.hostname(), vim.fn.getcwd()))
    io.stdout:flush()
  end,
})

-- Big file: disable heavy features above 2MB
local bigfile_group = vim.api.nvim_create_augroup('BigFile', { clear = true })
autocmd('BufReadPre', {
  desc = 'Disable heavy features for large files (>2MB)',
  group = bigfile_group,
  callback = function(ev)
    local ok, stat = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(ev.buf))
    if not (ok and stat and stat.size > 2 * 1024 * 1024) then
      return
    end
    vim.b[ev.buf].bigfile = true
    vim.opt_local.swapfile = false
    vim.opt_local.foldmethod = 'manual'
    vim.opt_local.undolevels = -1
    vim.opt_local.undoreload = 0
    vim.opt_local.list = false
    autocmd('BufReadPost', {
      buffer = ev.buf,
      once = true,
      callback = function()
        vim.opt_local.syntax = 'OFF'
        pcall(vim.treesitter.stop, ev.buf)
      end,
    })
  end,
})
