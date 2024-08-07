---@diagnostic disable: global_usage
local map = vim.keymap.set

-- better up/down
map({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { desc = 'Down', expr = true, silent = true })
map({ 'n', 'x' }, '<Down>', "v:count == 0 ? 'gj' : 'j'", { desc = 'Down', expr = true, silent = true })
map({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { desc = 'Up', expr = true, silent = true })
map({ 'n', 'x' }, '<Up>', "v:count == 0 ? 'gk' : 'k'", { desc = 'Up', expr = true, silent = true })

-- Select all file visually
map('n', '<leader>sa', 'ggVG', { remap = false, desc = 'Visually select entire buffer' })

-- Map 0 to first non-blank character
map('n', '0', '^', { remap = false, desc = 'Go to the first non-blank character' })
map('v', '0', '^', { remap = false, desc = 'Go to the first non-blank character' })

-- Move to the end of the line
map('n', 'L', '$ze10zl', { remap = false, desc = 'Go to the end of the line and move view' })
map('v', 'L', '$', { remap = false })
map('n', 'H', '0zs10zh', { remap = false })
map('v', 'H', '0', { remap = false })

-- indent/unindent visual mode selection with tab/shift+tab
map('v', '<tab>', '>gv')
map('v', '<s-tab>', '<gv')

-- command line mappings
map('c', '<c-h>', '<left>')
map('c', '<c-j>', '<down>')
map('c', '<c-k>', '<up>')
map('c', '<c-l>', '<right>')

-- Add undo break-points
map('i', ',', ',<c-g>u', { remap = false })
map('i', '.', '.<c-g>u', { remap = false })
map('i', ';', ';<c-g>u', { remap = false })

map('i', ';;', '<C-O>A;', { remap = false })

-- delete word on insert mode
map('i', '<C-e>', '<C-o>de', { remap = false })
map('i', '<C-b>', '<C-o>db', { remap = false })

-- Search for string within the visual selection
map('x', '/', '<Esc>/\\%V', { remap = false })

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
  table.insert(text, 1, '')
  vim.api.nvim_buf_set_lines(0, finish[1], finish[1], false, text)
  vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win(), { finish[1] + 1, finish[2] })
end

map('n', '<leader>cp', _G.__duplicate_lines)

-- surround with string interpolation with motion
function _G.__surround_with_interpolation(motion)
  local start = {}
  local finish = {}
  if motion == nil or motion == 'line' then
    vim.o.operatorfunc = 'v:lua.__surround_with_interpolation'
    return vim.fn.feedkeys 'g@'
  end
  if motion == 'char' then
    start = vim.api.nvim_buf_get_mark(0, '[')
    finish = vim.api.nvim_buf_get_mark(0, ']')
  end
  local line = vim.api.nvim_buf_get_text(0, start[1] - 1, start[2], finish[1] - 1, finish[2] + 1, {})[1]
  local new_text = { '"${' .. line .. '}"' }
  vim.api.nvim_buf_set_text(0, start[1] - 1, start[2], finish[1] - 1, finish[2] + 1, new_text)
  vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win(), { finish[1], finish[2] })
end
map('n', 'mt', _G.__surround_with_interpolation)

-- Indent block
vim.cmd [[
function! g:__align_based_on_indent(_)
  normal v%koj$>
endfunction
]]
map('n', '<leader>gt', function()
  vim.go.operatorfunc = '__align_based_on_indent'
  return 'g@l'
end, { expr = true })

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
function! s:BasicGroovyFormat() abort
  silent! %s/\(\w\){/\1 {/gc
  silent %s?\V){?) {?gc
endfunction
com! -bang FormatGroovyMap call s:FormatGroovyMap("<bang>")
com! BasicGroovyFormat call s:BasicGroovyFormat()
]=]

-- Windows mappings
map('n', '<Leader><Leader>', '<C-^>', { remap = false, silent = true })
map('n', '<tab>', '<c-w>w', { remap = false, silent = true })
map('n', '<c-w><c-c>', '<c-w>c', { remap = false, silent = true })
map('n', '<leader>bn', '<cmd>bn<cr>', { remap = false, silent = true, desc = 'Next buffer' })
map('n', '<c-w>v', ':vnew<cr>', { remap = false, silent = true, desc = 'New buffer vertically split' })
map('n', '<c-w>s', ':new<cr>', { remap = false, silent = true, desc = 'New buffer horizontally split' })
map('n', '<c-w>e', ':enew<cr>', { remap = false, silent = true, desc = 'New empty buffer' })

-- Move to window using the <ctrl> hjkl keys
map('n', '<C-h>', '<C-w>h', { remap = true, desc = 'Go to Left Window' })
map('n', '<C-j>', '<C-w>j', { remap = true, desc = 'Go to Lower Window' })
map('n', '<C-k>', '<C-w>k', { remap = true, desc = 'Go to Upper Window' })
map('n', '<C-l>', '<C-w>l', { remap = true, desc = 'Go to Right Window' })

-- Resize window using <ctrl> arrow keys
map('n', '<M-k>', '<cmd>resize +2<cr>', { desc = 'Increase Window Height' })
map('n', '<M-j>', '<cmd>resize -2<cr>', { desc = 'Decrease Window Height' })
map('n', '<M-h>', '<cmd>vertical resize -2<cr>', { desc = 'Decrease Window Width' })
map('n', '<M-l>', '<cmd>vertical resize +2<cr>', { desc = 'Increase Window Width' })

-- entire file text-object
map('o', 'ae', '<cmd>normal! ggVG<CR>', { remap = false })
map('v', 'ae', '<esc>gg0vG$', { remap = false })

-- Run and edit macros
for _, key in pairs { 'Q', 'X' } do
  map('n', key, '@' .. key:lower(), { remap = false })
  map('n', '<leader>' .. key, ":<c-u><c-r><c-r>='let @" .. key:lower() .. " = '. string(getreg('" .. key:lower() .. "'))<cr><c-f><left>", { remap = false })
end

-- keymap('n', 'Q', '@q', opts.no_remap)
-- keymap('n', '<leader>Q', ":<c-u><c-r><c-r>='let @q = '. string(getreg('q'))<cr><c-f><left>", opts.no_remap)

-- Paste in insert mode
map('i', '<c-v>', '<c-r>"', { remap = false })

-- Quickfix and tabs
map('n', ']q', ':cnext<cr>zz', { remap = false, silent = true })
map('n', '[q', ':cprev<cr>zz', { remap = false, silent = true })
map('n', ']l', ':lnext<cr>zz', { remap = false, silent = true })
map('n', '[l', ':lprev<cr>zz', { remap = false, silent = true })
map('n', ']t', ':tabnext<cr>zz', { remap = false, silent = true })
map('n', '[t', ':tabprev<cr>zz', { remap = false, silent = true })
map('n', ']b', ':bnext<cr>', { remap = false, silent = true })
map('n', '[b', ':bprev<cr>', { remap = false, silent = true })

-- This creates a new line of '=' signs the same length of the line
map('n', '<leader>=', 'yypVr=', { remap = false })

-- Map dp and dg with leader for diffput and diffget
_G.__diffput = function()
  vim.cmd [[diffput]]
end
map('n', '<leader>dp', function()
  vim.go.operatorfunc = 'v:lua.__diffput'
  return 'g@l'
end, { expr = true })
_G.__diffget = function()
  vim.cmd [[diffget]]
end
map('n', '<leader>dg', function()
  vim.go.operatorfunc = 'v:lua.__diffget'
  return 'g@l'
end, { expr = true })
map('n', '<leader>dn', ':windo diffthis<cr>', { remap = false, silent = true })
map('n', '<leader>df', ':windo diffoff<cr>', { remap = false, silent = true })

-- Map enter to no highlight
map('n', '<CR>', '<Esc>:nohlsearch<CR><CR>', { remap = false, silent = true })

-- Set mouse=v mapping
map('n', '<leader>ma', ':set mouse=a<cr>', { remap = false, silent = true })
map('n', '<leader>mv', ':set mouse=v<cr>', { remap = false, silent = true })

-- Exit mappings
map('i', 'jk', '<esc>', { remap = false })
map('n', '<leader>qq', ':qall<cr>', { remap = false, silent = true })

-- Search mappings
map('n', '*', ':execute "normal! *N"<cr>', { remap = false, silent = true })
map('n', '#', ':execute "normal! #n"<cr>', { remap = false, silent = true })
-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
map('n', 'n', "'Nn'[v:searchforward].'zv'", { expr = true, desc = 'Next Search Result' })
map('x', 'n', "'Nn'[v:searchforward]", { expr = true, desc = 'Next Search Result' })
map('o', 'n', "'Nn'[v:searchforward]", { expr = true, desc = 'Next Search Result' })
map('n', 'N', "'nN'[v:searchforward].'zv'", { expr = true, desc = 'Prev Search Result' })
map('x', 'N', "'nN'[v:searchforward]", { expr = true, desc = 'Prev Search Result' })
map('o', 'N', "'nN'[v:searchforward]", { expr = true, desc = 'Prev Search Result' })
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
map('t', '<Esc>', [[<C-\><C-n>]], { remap = false })

map('v', '*', ":call StarSearch('/')<CR>/<C-R>=@/<CR><CR>", { remap = false, silent = true })
map('v', '#', ":call StarSearch('?')<CR>?<C-R>=@/<CR><CR>", { remap = false, silent = true })

-- Map - to move a line down and _ a line up
map('n', '-', [["ldd$"lp==]], { remap = false })
map('n', '_', [["ldd2k"lp==]], { remap = false })

-- Allow clipboard copy paste in neovim
map('', '<D-v>', '+p<CR>', { remap = false, silent = true })
map('!', '<D-v>', '<C-R>+', { remap = false, silent = true })
map('t', '<D-v>', '<C-R>+', { remap = false, silent = true })
map('v', '<D-v>', '<C-R>+', { remap = false })

-- Copy entire file to clipboard
map('n', 'Y', ':%y+<cr>', { remap = false, silent = true })

-- Copy file path to clipboard
map('n', '<leader>cfp', [[:let @+ = expand('%')<cr>:echo   "Copied relative file path " . expand('%')<cr>]], { remap = false, silent = true })
map('n', '<leader>cfa', [[:let @+ = expand('%:p')<cr>:echo "Copied full file path " . expand('%:p')<cr>]], { remap = false, silent = true })
map('n', '<leader>cfd', [[:let @+ = expand('%:p:h')<cr>:echo "Copied file directory path " . expand('%:p:h')<cr>]], { remap = false, silent = true })
map('n', '<leader>cfn', [[:let @+ = expand('%:t')<cr>:echo "Copied file directory path " . expand('%:t')<cr>]], { remap = false, silent = true })

-- Copy and paste to/from system clipboard
map('v', 'cp', '"+y')
map('n', 'cP', '"+yy')
map('n', 'cp', '"+y')
map('n', 'cv', '"+p')

-- Move visually selected block
map('v', 'J', [[:m '>+1<CR>gv=gv]], { remap = false, silent = true })
map('v', 'K', [[:m '<-2<CR>gv=gv]], { remap = false, silent = true })

-- Select last inserted text
map('n', 'gV', '`[v`]', { remap = false })

-- Convert all tabs to spaces
map('n', '<leader>ct<space>', ':retab<cr>', { remap = false, silent = true })

-- Enable folding with the leader-f/a
map('n', '<leader>ff', 'za', { remap = false })
map('n', '<leader>fc', 'zM', { remap = false })
map('n', '<leader>fo', 'zR', { remap = false })
-- Open level folds
map('n', '<leader>fl', 'zazczA', { remap = false })

-- Change \n to new lines
map('n', '<leader><cr>', [[:silent! %s?\\n?\r?g<bar>silent! %s?\\t?\t?g<bar>silent! %s?\\r?\r?g<cr>:noh<cr>]], { silent = true })

-- Move vertically by visual line (don't skip wrapped lines)
-- nmap('k', "v:count == 0 ? 'gk' : 'k'", opts.expr_silent)
-- nmap('j', "v:count == 0 ? 'gj' : 'j'", opts.expr_silent)

-- toggle wrap
map('n', '<leader>ww', ':set wrap!<cr>', { remap = false, silent = true })

-- Scroll one line
map('n', '<PageUp>', '<c-y>', { remap = false })
map('n', '<PageDown>', '<c-e>', { remap = false })

-- Scrolling centralized
map('n', '<C-u>', '<C-u>zz', { remap = false })
map('n', '<C-d>', '<C-d>zz', { remap = false })

-- Change working directory based on open file
map('n', '<leader>cd', ':cd %:p:h<CR>:pwd<CR>', { remap = false, silent = true })

-- Convert all tabs to spaces
map('n', '<leader>ct<space>', ':retab<cr>', { silent = true })
-- Change every " -" with " \<cr> -" to break long lines of bash
map('n', [[<leader>\]], [[:.s/ -/ \\\r  -/g<cr>:noh<cr>]], { silent = true })

-- global yanks and deletes
map('v', '<leader>dab', [["hyqeq:v?\V<c-r>h?d E<cr>:let @"=@e<cr>:noh<cr>]], { remap = false, desc = 'Delete all but...', silent = true })
map('v', '<leader>daa', [["hyqeq:g?\V<c-r>h?d E<cr>:let @"=@e<cr>:noh<cr>]], { remap = false, desc = 'Delete all ...', silent = true })
map('v', '<leader>yab', [["hymmqeq:v?\V<c-r>h?yank E<cr>:let @"=@e<cr>`m:noh<cr>]], { remap = false, desc = 'Yank all but...', silent = true })
map('v', '<leader>yaa', [["hymmqeq:g?\V<c-r>h?yank E<cr>:let @"=@e<cr>`m:noh<cr>]], { remap = false, desc = 'Yank all...', silent = true })

-- print lua value of visual selection using ex-command :=
map('v', '<leader>xx', [["hy:lua <c-r>h<cr>]], { silent = true })
map('v', '<leader>x=', [["hy:=<c-r>h<cr>]], { silent = true })

-- Base64 dencode
map('v', '<leader>64', [[c<c-r>=substitute(system('base64', @"), '\n$', '', 'g')<cr><esc>]], { remap = false, silent = true, desc = 'Base64 encode' })
map('v', '<leader>46', [[c<c-r>=substitute(system('base64 --decode', @"), '\n$', '', 'g')<cr><esc>]], { remap = false, silent = true, desc = 'Base64 decode' })

-- Vimrc edit mappings
map('n', '<leader>ev', [[:execute("vsplit " . '~/.config/nvim/lua/user/options.lua')<cr>]], { silent = true })
map('n', '<leader>ep', [[:execute("vsplit " . '~/.config/nvim/lua/plugins/init.lua')<cr>]], { silent = true })
map('n', '<leader>el', [[:execute("vsplit " . '~/.config/nvim/lua/user/lsp/config.lua')<cr>]], { silent = true })
map('n', '<leader>em', [[:execute("vsplit " . '~/.config/nvim/lua/user/mappings.lua')<cr>]], { silent = true })

-- Close current buffer
map('n', '<leader>bc', ':close<cr>', { silent = true, desc = 'Close this buffer' })

-- Abbreviations
map('!a', 'dont', [[don't]], { remap = false })
map('!a', 'seperate', [[separate]], { remap = false })
map('!a', 'rbm', [[# TODO: remove before merging]], { remap = false })
map('!a', 'cbm', [[# TODO: change before merging]], { remap = false })
map('!a', 'ubm', [[# TODO: uncomment before merging]], { remap = false })

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

-----------------
-- Where am I? --
-----------------
vim.api.nvim_create_user_command('Whereami', function()
  local country_data = vim.json.decode(require('plenary.curl').get('http://ipconfig.io/json').body)
  local iso = country_data.country_iso
  local country = country_data.country
  local emoji = require('user.utils').country_os_to_emoji(iso)
  if not emoji then
    emoji = '🌎'
  end
  local msg = [[You're in ]] .. country
  vim.notify(msg, vim.log.levels.INFO, { title = 'Where am I?', icon = emoji })
end, {})

------------------------
-- Change indentation --
------------------------
map('n', 'cii', function()
  vim.ui.input({ prompt = 'Enter new indent: ' }, function(indent_size)
    local indent_size_normalized = tonumber(indent_size)
    vim.opt_local.shiftwidth = indent_size_normalized
    vim.opt_local.softtabstop = indent_size_normalized
    vim.opt_local.tabstop = indent_size_normalized
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
vim.api.nvim_create_user_command('DiffWithSaved', function()
  -- Get start buffer
  local start = vim.api.nvim_get_current_buf()
  local filetype = vim.api.nvim_get_option_value('filetype', { buf = start })

  -- `vnew` - Create empty vertical split window
  -- `set buftype=nofile` - Buffer is not related to a file, will not be written
  -- `0d_` - Remove an extra empty start row
  -- `diffthis` - Set diff mode to a new vertical split
  vim.cmd 'vnew | set buftype=nofile | read ++edit # | 0d_ | diffthis'

  -- Get scratch buffer
  local scratch = vim.api.nvim_get_current_buf()

  -- Set filetype of scratch buffer to be the same as start
  vim.api.nvim_set_option_value('filetype', filetype, { buf = scratch })

  -- `wincmd p` - Go to the start window
  -- `diffthis` - Set diff mode to a start window
  vim.cmd 'wincmd p | diffthis'

  -- Map `q` for both buffers to exit diff view and delete scratch buffer
  for _, buf in ipairs { scratch, start } do
    map('n', 'q', function()
      vim.api.nvim_buf_delete(scratch, { force = true })
      vim.keymap.del('n', 'q', { buffer = start })
    end, { buffer = buf })
  end
end, {})
map('n', '<leader>ds', ':DiffWithSaved<cr>', { remap = false, silent = true })

-----------------------
-- Visual calculator --
-----------------------
vim.cmd [[
function s:VisualCalculator() abort
  let save_pos = getpos('.')
  let first_expr = GetMotion('gv')

  " Get arithmetic operation from user input
  call inputsave()
  let operation = input('Enter operation: ')
  call inputrestore()

  " Calculate final result
  let fin_result = eval(str2nr(first_expr) . operation)

  " Replace
  call ReplaceMotion('gv', fin_result)
  call setpos('.', save_pos)
endfunction
command! -range VisualCalculator call <SID>VisualCalculator()
vmap <c-r> :VisualCalculator<cr>
]]

----------
-- Grep --
----------
vim.cmd [[
" Set grepprg as RipGrep or ag (the_silver_searcher), fallback to grep
if executable('rg')
  let &grepprg="rg --vimgrep --no-heading --smart-case --hidden --follow -g '!{" . &wildignore . "}' -uu $*"
  let g:grep_literal_flag="-F"
  set grepformat=%f:%l:%c:%m,%f:%l:%m
elseif executable('ag')
  let &grepprg='ag --vimgrep --smart-case --hidden --follow --ignore "!{' . &wildignore . '}" $*'
  let g:grep_literal_flag="-Q"
  set grepformat=%f:%l:%c:%m
else
  let &grepprg='grep -n -r --exclude=' . shellescape(&wildignore) . ' . $*'
  let g:grep_literal_flag="-F"
endif

function! RipGrepCWORD(bang, visualmode, ...) abort
  let search_word = a:1

  if a:visualmode
    let search_word = GetMotion('gv')
  endif
  if search_word ==? ''
    let search_word = expand('<cword>')
  endif

  " Set bang command for literal search (no regexp expansion)
  let search_message_literally = "for " . search_word
  if a:bang == "!" || a:bang == v:true
    let search_message_literally = "literally for " . search_word
    let search_word = get(g:, 'grep_literal_flag', "") . ' -- ' . shellescape(search_word)
  endif

  echom 'Searching ' . search_message_literally

  " Silent removes the "press enter to continue" prompt
  " Bang (!) is for literal search (no regexp expansion)
  let grepcmd = 'silent grep! ' . search_word
  execute grepcmd
endfunction
]]
vim.api.nvim_create_user_command('RipGrepCWORD', function(f_opts)
  vim.fn.RipGrepCWORD(f_opts.bang, false, f_opts.args)
end, { bang = true, range = true, nargs = '?', complete = 'file_in_path' })
vim.api.nvim_create_user_command('RipGrepCWORDVisual', function(f_opts)
  vim.fn.RipGrepCWORD(f_opts.bang, true, f_opts.args)
end, { bang = true, range = true, nargs = '?', complete = 'file_in_path' })
map({ 'n', 'v' }, '<C-f>', function()
  return vim.fn.mode() == 'v' and ':RipGrepCWORDVisual!<cr>' or ':RipGrepCWORD!<Space>'
end, { remap = false, expr = true })

------------------------
-- Run current buffer --
------------------------
vim.cmd [[
" Will attempt to execute the current file based on the `&filetype`
" You need to manually map the filetypes you use most commonly to the
" correct shell command.
function! ExecuteFile()
  let l:filetype_to_command = {
        \   'javascript': 'node',
        \   'python': 'python3',
        \   'html': 'open',
        \   'sh': 'bash'
        \ }
  call inputsave()
  let sure = input('Are you sure you want to run the current file? (y/n): ')
  call inputrestore()
  if sure !=# 'y'
    return ''
  endif
  echo ''
  let l:cmd = get(l:filetype_to_command, &filetype, 'bash')
  :%y
  new | 0put
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
  exe '%!'.l:cmd
  normal! ggO
  call setline(1, 'Output of ' . l:cmd . ' command:')
  normal! yypVr=o
endfunction
]]
map('n', '<F3>', ':call ExecuteFile()<CR>', { remap = false, silent = true })

----------------------------
-- Sort Json Array by key --
----------------------------
vim.cmd [[
function s:JsonSortArrayByKey() abort
  call inputsave()
  let sort_key = input('Sort by key: ')
  call inputrestore()
  let save_pos = getpos('.')
  let save_pos[2] = save_pos[2] - 1
  let entire_selection = GetMotion('gv')
  let formatted_selection = trim(system("jq 'sort_by(" . sort_key . ")'", entire_selection))
  call ReplaceMotion('gv', formatted_selection)
  call setpos('.', save_pos)
  normal! gv=
endfunction
command! -range JsonSortArrayByKey call <SID>JsonSortArrayByKey()
]]

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
  require('user.plugins-mgmt').display_awesome_plugins()
end, {})

vim.api.nvim_create_user_command('PluginsReload', function()
  require('user.plugins-mgmt').reload_plugin()
end, {})

------------------------
-- Search and Replace --
------------------------
require('user.search-replace')
