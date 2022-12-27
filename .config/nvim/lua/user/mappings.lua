-- leader key - before mapping lsp maps
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

local utils = require 'user.utils'
local opts = utils.map_opts
local nmap = utils.nnoremap
local nnoremap = utils.nnoremap
local vmap = utils.vnoremap
local vnoremap = utils.vnoremap
local onoremap = utils.onoremap
local inoremap = utils.inoremap
local xmap = utils.xnoremap
local xnoremap = utils.xnoremap
local tnoremap = utils.tnoremap

-- Select all file visually
nnoremap('<leader>sa', 'gg^<S-v>G$')

-- Inner word movements
onoremap('<c-w>', 'iw')
nnoremap('v<c-w>', 'viw')

-- Map 0 to first non-blank character
nnoremap('0', '^')

-- Move to the end of the line
nnoremap('L', '$ze10zl')
vnoremap('L', '$')
nnoremap('H', '0zs10zh')
vnoremap('H', '0')

-- indent/unindent visual mode selection with tab/shift+tab
vmap('<tab>', '>gv')
vmap('<s-tab>', '<gv')

-- Indent by block
vim.cmd [[let @i="v%koj>$"]]
vim.cmd [[let @o="v%koj<$"]]

-- Copy number of lines and paste below
function _G.__duplicate_lines(motion)
  local count = vim.api.nvim_get_vvar 'count'
  local start = {}
  local finish = {}
  if count ~= 0 then
    start = vim.api.nvim_win_get_cursor(0)
    finish = { start[1] + count, 0 }
  elseif motion == nil then
    vim.o.operatorfunc = 'v:lua.__duplicate_lines'
    return vim.fn.feedkeys 'g@'
  elseif motion == 'char' then
    return
  elseif motion == 'line' then
    start = vim.api.nvim_buf_get_mark(0, '[')
    finish = vim.api.nvim_buf_get_mark(0, ']')
  end
  local text = vim.api.nvim_buf_get_lines(0, start[1] - 1, finish[1], false)
  -- prepend empty string to text table
  table.insert(text, 1, '')
  vim.api.nvim_buf_set_lines(0, finish[1], finish[1], false, text)
  -- vim.cmd.normal(finish[1] + 1 .. 'G')
  vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win(), { finish[1] + 1, finish[2] })
end
nmap('<leader>cp', _G.__duplicate_lines)

-- Indent block
nmap('<leader>gt', function()
  vim.cmd [[normal v%koj$>]]
end)

-- Format groovy map
vim.cmd [=[
function! s:FormatGroovyMap(surround_words)
  silent! %s?\]?\r]?g
  silent! %s/, /,\r/g
  silent! %s?\[?[\r?g
  silent! %s?:\[?:[?g
  silent! %s?\v([^\s]):([^\s])?\1: \2?
  silent! %s?:\[?: [?
  if a:surround_words != "!"
    silent! %s/\v(.*: )([^,\[\]]*)(,?)$/\1"\2"\3/g
  endif
  normal! gg=G
  noh
endfunction
com! -bang FormatGroovyMap call s:FormatGroovyMap("<bang>")
]=]

-- Windows mappings
nnoremap('<Leader><Leader>', '<C-^>', true)
nnoremap('<tab>', '<c-w>w', true)
nnoremap('<c-w><c-c>', '<c-w>c', true)
nnoremap('<leader>bn', ':bn<cr>', true)
nnoremap('<c-w>v', ':vnew<cr>', true)
nnoremap('<c-w>s', ':new<cr>', true)
nnoremap('<c-w>e', ':enew<cr>', true)
nnoremap('<C-J>', '<C-W><C-J>', true)
nnoremap('<C-K>', '<C-W><C-K>', true)
nnoremap('<C-L>', '<C-W><C-L>', true)
nnoremap('<C-H>', '<C-W><C-H>', true)

-- entire file text-object
onoremap('ae', '<cmd>normal! ggVG<CR>', true)
vnoremap('ae', '<esc>gg0vG$')

-- Run and edit macros
for _, key in pairs { 'Q', 'X' } do
  nnoremap(key, '@' .. key:lower())
  nnoremap('<leader>' .. key, ":<c-u><c-r><c-r>='let @" .. key:lower() .. " = '. string(getreg('" .. key:lower() .. "'))<cr><c-f><left>")
end

-- keymap('n', 'Q', '@q', opts.no_remap)
-- keymap('n', '<leader>Q', ":<c-u><c-r><c-r>='let @q = '. string(getreg('q'))<cr><c-f><left>", opts.no_remap)

-- Paste in insert mode
inoremap('<c-v>', '<c-r>')

-- Quickfix
nnoremap(']q', ':cnext<cr>zz', true)
nnoremap('[q', ':cprev<cr>zz', true)
nnoremap(']l', ':lnext<cr>zz', true)
nnoremap('[l', ':lprev<cr>zz', true)

-- This creates a new line of '=' signs the same length of the line
nnoremap('<leader>=', 'yypVr=')

-- Map dp and dg with leader for diffput and diffget
nnoremap('<leader>dp', ':diffput<cr>')
nnoremap('<leader>dg', ':diffget<cr>')
nnoremap('<leader>dn', ':windo diffthis<cr>')
nnoremap('<leader>df', ':bufdo diffoff<cr>')

-- Map enter to no highlight
nnoremap('<CR>', ':nohlsearch<CR><CR>', true)

-- Set mouse=v mapping
nnoremap('<leader>ma', ':set mouse=a<cr>')
nnoremap('<leader>mv', ':set mouse=v<cr>')

-- Exit mappings
inoremap('jk', '<esc>')
nnoremap('<leader>qq', ':qall<cr>', true)

-- Search mappings
nnoremap('*', ':execute "normal! *N"<cr>', true)
nnoremap('#', ':execute "normal! #n"<cr>', true)
nnoremap('n', "'Nn'[v:searchforward]", opts.no_remap_expr)
xnoremap('n', "'Nn'[v:searchforward]", opts.no_remap_expr)
onoremap('n', "'Nn'[v:searchforward]", opts.no_remap_expr)
nnoremap('N', "'nN'[v:searchforward]", opts.no_remap_expr)
xnoremap('N', "'nN'[v:searchforward]", opts.no_remap_expr)
onoremap('N', "'nN'[v:searchforward]", opts.no_remap_expr)
-- Search visually selected text with // or * or #
vim.cmd [[
function! StarSearch(cmdtype) abort
  let old_reg=getreg('"')
  let old_regtype=getregtype('"')
  norm! gvy
  let @/ = '\V' . substitute(escape(@", a:cmdtype . '\.*$^~['), '\_s\+', '\\_s\\+', 'g')
  norm! gVzv
  call setreg('"', old_reg, old_regtype)
endfunction
]]

-- Terminal
tnoremap('<Esc>', [[<C-\><C-n>]])

-- local function star_search(cmdtype)
--   local old_reg = vim.fn.getreg('"')
--   local old_regtype = vim.fn.getregtype('"')
--   vim.cmd("norm! gvy")
--   vim.cmd [[let @/ = '\V' . substitute(escape(@", cmdtype . '\.*$^~['), '\_s\+', '\\_s\\+', 'g')]]
--   vim.cmd [[norm! gVzv]]
--   vim.fn.setreg('"', old_reg, old_regtype)
--   vim.cmd [[exe 'norm! ' . cmdtype . '<c-r>@/<cr><cr>']]
-- end

-- vim.keymap.set('v', '*', function()
--   return star_search('*')
-- end)

vnoremap('*', ":call StarSearch('/')<CR>/<C-R>=@/<CR><CR>")
vnoremap('#', ":call StarSearch('?')<CR>?<C-R>=@/<CR><CR>")

-- Map - to move a line down and _ a line up
nnoremap('-', [["ldd$"lp]])
nnoremap('_', [["ldd2k"lp]])

-- Copy entire file to clipboard
nnoremap('Y', ':%y+<cr>')

-- Copy file path to clipboard
nnoremap('<leader>cfp', [[:let @+ = expand('%')<cr>:echo   "Copied file path " . expand('%')<cr>]], true)
nnoremap('<leader>cfa', [[:let @+ = expand('%:p')<cr>:echo "Copied file path " . expand('%:p')<cr>]], true)
nnoremap('<leader>cfd', [[:let @+ = expand('%:p:h')<cr>:echo "Copied file path " . expand('%:p:h')<cr>]], true)

-- Copy and paste to/from system clipboard
vmap('cp', '"+y')
nmap('cP', '"+yy')
nmap('cp', '"+y')
nmap('cv', '"+p')

-- Move visually selected block
vnoremap('J', [[:m '>+1<CR>gv=gv]])
vnoremap('K', [[:m '<-2<CR>gv=gv]])

-- Convert all tabs to spaces
nnoremap('<leader>ct<space>', ':retab<cr>')

-- Enable folding with the leader-f/a
nnoremap('<leader>ff', 'za')
nnoremap('<leader>fc', 'zM')
nnoremap('<leader>fo', 'zR')
-- Open level folds
nnoremap('<leader>fl', 'zazczA')

-- Change \n to new lines
nmap('<leader><cr>', [[:silent! %s?\\n?\r?g<bar>silent! %s?\\t?\t?g<bar>silent! %s?\\r?\r?g<cr>:noh<cr>]])

-- Move vertically by visual line (don't skip wrapped lines)
nmap('k', "v:count == 0 ? 'gk' : 'k'", opts.expr_silent)
nmap('j', "v:count == 0 ? 'gj' : 'j'", opts.expr_silent)

-- Scroll one line
nnoremap('<PageUp>', '<c-y>', true)
nnoremap('<PageDown>', '<c-e>', true)

-- Scrolling centralized
nnoremap('<C-u>', '<C-u>zz', true)
nnoremap('<C-d>', '<C-d>zz', true)

-- Change working directory based on open file
nnoremap('<leader>cd', ':cd %:p:h<CR>:pwd<CR>')

-- Convert all tabs to spaces
nnoremap('<leader>ct<space>', ':retab<cr>')
-- Change every " -" with " \<cr> -" to break long lines of bash
nnoremap([[<leader>\]], [[:.s/ -/ \\\r  -/g<cr>:noh<cr>]], true)

-- Search and Replace
nnoremap('<Leader>r', ':.,$s?\\V<C-r><C-w>?<C-r><C-w>?gc<Left><Left><Left>', true)
vnoremap('<leader>r', '"hy:.,$s?\\V<C-r>h?<C-r>h?gc<left><left><left>', true)
vnoremap('<leader>dab', [["hyqeq:v?\V<c-r>h?d E<cr>:let @"=@e<cr>:noh<cr>]], { desc = 'Delete all but ...', silent = true })
vnoremap('<leader>daa', [["hyqeq:g?\V<c-r>h?d E<cr>:let @"=@e<cr>:noh<cr>]], true)
vnoremap('<leader>yab', [["hymmqeq:v?\V<c-r>h?yank E<cr>:let @"=@e<cr>`m:noh<cr>, true]])
vnoremap('<leader>yaa', [["hymmqeq:g?\V<c-r>h?yank E<cr>:let @"=@e<cr>`m:noh<cr>]], true)

-- Paste without saving deleted reg
nmap('<leader>p', '<Plug>ReplaceWithRegisterOperator')
nmap('<leader>P', '<Plug>ReplaceWithRegisterLine')
xmap('<leader>P', '<Plug>ReplaceWithRegisterVisual')

-- Base64 dencode
vnoremap('<leader>46', [[c<c-r>=substitute(system('base64 --decode', @"), '\n$', '', 'g')<cr><esc>]], true)
vnoremap('<leader>64', [[c<c-r>=substitute(system('base64', @"), '\n$', '', 'g')<cr><esc>]], true)

-- Vimrc edit mappings
nnoremap('<leader>ev', [[:execute("vsplit " . '~/.config/nvim/lua/user/options.lua')<cr>]], true)
nnoremap('<leader>ep', [[:execute("vsplit " . '~/.config/nvim/lua/user/plugins/init.lua')<cr>]], true)
nnoremap('<leader>ec', [[:execute("vsplit " . '~/.config/nvim/lua/user/plugins/configs.lua')<cr>]], true)
nnoremap('<leader>el', [[:execute("vsplit " . '~/.config/nvim/lua/user/lsp/config.lua')<cr>]], true)
nnoremap('<leader>em', [[:execute("vsplit " . '~/.config/nvim/lua/user/mappings.lua')<cr>]], true)

-- Delete current buffer
nnoremap('<leader>bd', '<cmd>BDelete this<cr>', true)
-- Close current buffer
nnoremap('<leader>bc', ':close<cr>', true)

-----------------
-- Yaml / Json --
-----------------
-- Yaml 2 json
vim.api.nvim_create_user_command('Yaml2Json', function()
  vim.cmd [[%!yq -ojson]]
end, {})

vim.api.nvim_create_user_command('Json2Yaml', function()
  vim.cmd [[%!yq -P]]
end, {})

------------------------
-- Change indentation --
------------------------
nnoremap('cii', function()
  vim.ui.input({ prompt = 'Enter new indent' }, function(indent_size)
    local indent_size = tonumber(indent_size)
    vim.opt_local.shiftwidth = indent_size
    vim.opt_local.softtabstop = indent_size
    vim.opt_local.tabstop = indent_size
  end)
end)

-------------------------------
-- Split parameters to lines --
-------------------------------
vim.cmd [[
function! SplitParamLines() abort
  let f_line_num = line('.')
  let indent_length = indent(f_line_num)
  exe "normal! 0f(a\<cr>\<esc>"
  exe ".s/\s*,/,\r" . repeat(' ', indent_length + &shiftwidth - 1) . '/g'
  nohlsearch
  exe "normal! 0t)a\<cr>\<esc>"
endfunction
nnoremap <silent> <leader>( :call SplitParamLines()<cr>
]]

-------------------------
-- Diff with last save --
-------------------------
vim.cmd [[
function! s:DiffWithSaved()
  let filetype=&ft
  diffthis
  lefta vnew | r # | normal! 1Gdd
  exe 'setlocal bt=nofile bh=wipe nobl noswf ro foldlevel=999 ft=' . filetype
  diffthis
  nnoremap <buffer> q :bd!<cr>
  augroup ShutDownDiffOnLeave
    autocmd! * <buffer>
    autocmd BufDelete,BufUnload,BufWipeout <buffer> wincmd p | diffoff | wincmd p | diffoff
  augroup END

  wincmd p
endfunction
com! DiffSaved call s:DiffWithSaved()
nnoremap <leader>ds :DiffSaved<cr>
]]

-----------------------
-- Visual calculator --
-----------------------
vim.cmd [[
function s:VisualCalculator() abort
  let save_pos = getpos('.')
  " Get visual selection
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][: col2 - (&selection ==? 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][col1 - 1:]
  let first_expr = join(lines, "\n")

  " Get arithmetic operation from user input
  call inputsave()
  let operation = input('Enter operation: ')
  call inputrestore()

  " Calculate final result
  let fin_result = eval(str2nr(first_expr) . operation)

  " Replace
  exe 's/\%V' . first_expr . '/' . fin_result . '/'

  call setpos('.', save_pos)
endfunction
command! -range VisualCalculator call <SID>VisualCalculator()
vmap <c-r> :VisualCalculator<cr>
]]
-- keymap('v', '<c-r>', function()
--   local selection = utils.get_selection()
--   local num = tonumber(selection)
--   P(selection)
--   -- return VisualCalculator()
-- end, opts.no_remap)

----------
-- Titleize --
--------------
vim.api.nvim_create_user_command('Titleize', function(options)
  local title_char = '-'
  if options.args ~= '' then
    title_char = options.args
  end
  local current_line = vim.api.nvim_get_current_line()
  local r, _ = unpack(vim.api.nvim_win_get_cursor(0))

  -- delete line
  vim.api.nvim_del_current_line()

  local top_bottom = title_char:rep(#current_line + 6)
  vim.api.nvim_buf_set_lines(0, r - 1, r - 1, false, {
    top_bottom,
    title_char:rep(2) .. ' ' .. current_line .. ' ' .. title_char:rep(2),
    top_bottom,
  })
end, { nargs = '?' })

-------------
-- AutoRun --
-------------
local attach_to_buffer = function(output_bufnr, pattern, command)
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = vim.api.nvim_create_augroup('AutoRun', { clear = true }),
    pattern = pattern,
    callback = function()
      local append_data = function(_, data)
        if data then
          vim.api.nvim_buf_set_lines(output_bufnr, -1, -1, false, data)
        end
      end
      vim.api.nvim_buf_set_lines(output_bufnr, 0, -1, false, { table.concat(command, ' ') .. ' output:' })
      vim.fn.jobstart(command, {
        stdout_buffered = true,
        on_stdout = append_data,
        on_stderr = append_data,
      })
    end,
  })
end
vim.api.nvim_create_user_command('AutoRun', function()
  local pattern = vim.fn.expand '%:p'
  vim.ui.input({ prompt = 'Command: ' }, function(command_text)
    if command_text == nil then
      return
    end
    if command_text:find [[%%]] then
      command_text = command_text:gsub('%%', vim.fn.expand '%')
    end
    local command = vim.split(command_text, ' ')
    print 'AutoRun starts now...'
    -- Open split and focus on it
    vim.cmd 'vsplit'
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_win_set_buf(win, buf)

    -- Resize
    local win_width = vim.o.columns
    local split_size = 25 * win_width / 100
    vim.cmd('vertical resize ' .. tostring(split_size))

    attach_to_buffer(tonumber(buf), pattern, command)
  end)
end, {})

------------------------
-- Plugins Management --
------------------------
vim.api.nvim_create_user_command('PluginsList', function()
  require('user.plugins.mgmt').display_awesome_plugins()
end, {})

vim.api.nvim_create_user_command('PluginsReload', function()
  require('user.plugins.mgmt').reload_plugin()
end, {})
