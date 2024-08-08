local utils = require 'user.utils'
local autocmd = utils.autocmd
local augroup = utils.augroup

-- Check if we need to reload the file when it changed
local reload_file_group = augroup 'ReloadFile'
vim.api.nvim_create_autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
  group = reload_file_group,
  callback = function()
    if vim.o.buftype ~= 'nofile' then
      vim.cmd 'checktime'
    end
  end,
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
autocmd('TextYankPost', {
  desc = 'Highlight on yank',
  group = buffer_settings,
  callback = function()
    pcall(vim.highlight.on_yank, { higroup = 'IncSearch', timeout = 200 })
  end,
})

-- resize splits if window got resized
vim.api.nvim_create_autocmd({ 'VimResized' }, {
  group = buffer_settings,
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd 'tabdo wincmd ='
    vim.cmd('tabnext ' .. current_tab)
  end,
})

vim.api.nvim_create_autocmd('BufReadPost', {
  desc = 'go to last loc when opening a buffer',
  group = buffer_settings,
  callback = function(event)
    local exclude = { 'gitcommit' }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].lazyvim_last_loc then
      return
    end
    vim.b[buf].lazyvim_last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
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
  pattern = { '*/plugins/*.lua', '.github/workflows/*.y*ml' },
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
  desc = 'Quickfix window settings',
  group = quickfix_au,
  pattern = 'qf',
  callback = function()
    local open_quickfix = function(new_split_cmd)
      local qf_idx = vim.fn.line '.'
      vim.cmd 'wincmd p'
      vim.cmd(new_split_cmd)
      vim.cmd(qf_idx .. 'cc')
    end
    vim.keymap.set('n', '<c-v>', function()
      open_quickfix 'vnew'
    end, { buffer = true })

    vim.keymap.set('n', '<c-x>', function()
      open_quickfix 'split'
    end, { buffer = true })

    local function remove_qf_item()
      local qf_list = vim.fn.getqflist()
      if #qf_list > 0 then
        local curqfidx = vim.fn.line '.'
        table.remove(qf_list, curqfidx)
        vim.fn.setqflist(qf_list, 'r')
        vim.cmd(curqfidx .. 'cfirst')
        vim.cmd 'copen'
      end
    end
    vim.api.nvim_create_user_command('RemoveQFItem', remove_qf_item, {})
    vim.keymap.set('n', 'dd', '<CMD>RemoveQFItem<CR>', { remap = false, buffer = true })

    -- map yy to yank file name
    vim.keymap.set('n', 'yy', function()
      local line = vim.api.nvim_get_current_line()
      local filename = vim.split(line, ' ')[1]
      vim.fn.setreg('"', filename)
    end, { remap = false, buffer = true })
  end,
})

-- autocmd for terminal buffers
local term_au = augroup 'MosheTerm'
autocmd({ 'TermOpen' }, {
  group = term_au,
  pattern = '*',
  command = 'startinsert',
})

-- custom settings
local CustomSettingsGroup = augroup 'CustomSettingsGroup'
autocmd('BufWritePost', {
  group = CustomSettingsGroup,
  desc = 'make sh file executable if a shebang is deteced',
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
})

-- Automatically commit lockfile after running Lazy Update (or Sync)
autocmd('User', {
  pattern = 'LazyUpdate',
  callback = function()
    local repo_dir = vim.env.HOME .. '/Repos/dotfiles'
    if vim.fn.isdirectory(repo_dir) ~= 1 then
      return
    end

    local lockfile = repo_dir .. '/.config/nvim/lazy-lock.json'

    local cmd = {
      'git',
      '-C',
      repo_dir,
      'commit',
      lockfile,
      '-m',
      'Update lazy-lock.json',
    }

    local success, process = pcall(function()
      return vim.system(cmd):wait()
    end)

    if process and process.code == 0 then
      vim.notify 'Committed lazy-lock.json'
      vim.notify(process.stdout)
    else
      if not success then
        vim.notify("Failed to run command '" .. table.concat(cmd, ' ') .. "':", vim.log.levels.WARN, {})
        vim.notify(tostring(process), vim.log.levels.WARN, {})
      else
        vim.notify 'git ran but failed to commit:'
        vim.notify(process.stderr, vim.log.levels.WARN, {})
      end
    end
  end,
})
