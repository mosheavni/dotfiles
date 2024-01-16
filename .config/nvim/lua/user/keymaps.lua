local utils = require 'user.utils'
local opts = utils.map_opts
local nmap = utils.nnoremap
local nnoremap = utils.nnoremap
local vmap = utils.vmap
local vnoremap = utils.vnoremap
local onoremap = utils.onoremap
local inoremap = utils.inoremap
local xnoremap = utils.xnoremap
local tnoremap = utils.tnoremap

-- Select all file visually
nnoremap('<leader>sa', 'ggVG')

-- Inner word movements
onoremap('<c-w>', 'iw')
nnoremap('v<c-w>', 'viw')

-- Map 0 to first non-blank character
nnoremap('0', '^')
vnoremap('0', '^')

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

-- command line mappings
vim.keymap.set('c', '<c-h>', '<left>')
vim.keymap.set('c', '<c-j>', '<down>')
vim.keymap.set('c', '<c-k>', '<up>')
vim.keymap.set('c', '<c-l>', '<right>')
-- vim.keymap.set('c', '^', '<home>')
-- vim.keymap.set('c', '$', '<end>')

-- Add undo break-points
inoremap(',', ',<c-g>u')
inoremap('.', '.<c-g>u')
inoremap(';', ';<c-g>u')

inoremap(';;', '<C-O>A;')

-- delete word on insert mode
inoremap('<C-e>', '<C-o>de')
inoremap('<C-b>', '<C-o>db')

-- Search for string within the visual selection
xnoremap('/', '<Esc>/\\%V')

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

nmap('<leader>cp', _G.__duplicate_lines)

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
nmap('mt', _G.__surround_with_interpolation)

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
nnoremap('<leader>bn', '<cmd>bn<cr>', true)
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
inoremap('<c-v>', '<c-r>"', true)

-- Quickfix and tabs
nnoremap(']q', ':cnext<cr>zz', true)
nnoremap('[q', ':cprev<cr>zz', true)
nnoremap(']l', ':lnext<cr>zz', true)
nnoremap('[l', ':lprev<cr>zz', true)
nnoremap(']t', ':tabnext<cr>zz', true)
nnoremap('[t', ':tabprev<cr>zz', true)
nnoremap(']b', ':bnext<cr>', true)
nnoremap('[b', ':bprev<cr>', true)

-- This creates a new line of '=' signs the same length of the line
nnoremap('<leader>=', 'yypVr=')

-- Map dp and dg with leader for diffput and diffget
nnoremap('<leader>dp', ':diffput<cr>', true)
nnoremap('<leader>dg', ':diffget<cr>', true)
nnoremap('<leader>dn', ':windo diffthis<cr>', true)
nnoremap('<leader>df', ':windo diffoff<cr>', true)

-- Map enter to no highlight
nnoremap('<CR>', '<Esc>:nohlsearch<CR><CR>', true)

-- Set mouse=v mapping
nnoremap('<leader>ma', ':set mouse=a<cr>', true)
nnoremap('<leader>mv', ':set mouse=v<cr>', true)

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

vnoremap('*', ":call StarSearch('/')<CR>/<C-R>=@/<CR><CR>", true)
vnoremap('#', ":call StarSearch('?')<CR>?<C-R>=@/<CR><CR>", true)

-- Map - to move a line down and _ a line up
nnoremap('-', [["ldd$"lp==]])
nnoremap('_', [["ldd2k"lp==]])

-- Allow clipboard copy paste in neovim
vim.keymap.set('', '<D-v>', '+p<CR>', opts.no_remap_silent)
vim.keymap.set('!', '<D-v>', '<C-R>+', opts.no_remap_silent)
tnoremap('<D-v>', '<C-R>+', true)
vnoremap('<D-v>', '<C-R>+', true)

-- Copy entire file to clipboard
nnoremap('Y', ':%y+<cr>', true)

-- Copy file path to clipboard
nnoremap('<leader>cfp', [[:let @+ = expand('%')<cr>:echo   "Copied relative file path " . expand('%')<cr>]], true)
nnoremap('<leader>cfa', [[:let @+ = expand('%:p')<cr>:echo "Copied full file path " . expand('%:p')<cr>]], true)
nnoremap('<leader>cfd', [[:let @+ = expand('%:p:h')<cr>:echo "Copied file directory path " . expand('%:p:h')<cr>]], true)
nnoremap('<leader>cfn', [[:let @+ = expand('%:t')<cr>:echo "Copied file directory path " . expand('%:t')<cr>]], true)

-- Copy and paste to/from system clipboard
vmap('cp', '"+y')
nmap('cP', '"+yy')
nmap('cp', '"+y')
nmap('cv', '"+p')

-- Move visually selected block
vnoremap('J', [[:m '>+1<CR>gv=gv]], true)
vnoremap('K', [[:m '<-2<CR>gv=gv]], true)

-- Select last inserted text
nnoremap('gV', '`[v`]')

-- Convert all tabs to spaces
nnoremap('<leader>ct<space>', ':retab<cr>', true)

-- Enable folding with the leader-f/a
nnoremap('<leader>ff', 'za')
nnoremap('<leader>fc', 'zM')
nnoremap('<leader>fo', 'zR')
-- Open level folds
nnoremap('<leader>fl', 'zazczA')

-- Change \n to new lines
nmap('<leader><cr>', [[:silent! %s?\\n?\r?g<bar>silent! %s?\\t?\t?g<bar>silent! %s?\\r?\r?g<cr>:noh<cr>]], true)

-- Move vertically by visual line (don't skip wrapped lines)
-- nmap('k', "v:count == 0 ? 'gk' : 'k'", opts.expr_silent)
-- nmap('j', "v:count == 0 ? 'gj' : 'j'", opts.expr_silent)

-- toggle wrap
nnoremap('<leader>ww', ':set wrap!<cr>', true)

-- Scroll one line
nnoremap('<PageUp>', '<c-y>', true)
nnoremap('<PageDown>', '<c-e>', true)

-- Scrolling centralized
nnoremap('<C-u>', '<C-u>zz', true)
nnoremap('<C-d>', '<C-d>zz', true)

-- Change working directory based on open file
nnoremap('<leader>cd', ':cd %:p:h<CR>:pwd<CR>', true)

-- Convert all tabs to spaces
nnoremap('<leader>ct<space>', ':retab<cr>', true)
-- Change every " -" with " \<cr> -" to break long lines of bash
nnoremap([[<leader>\]], [[:.s/ -/ \\\r  -/g<cr>:noh<cr>]], true)

-- Search and Replace
nnoremap('<Leader>r', ':.,$s?\\V<C-r><C-w>?<C-r><C-w>?gc<Left><Left><Left>', true)
vnoremap('<leader>r', '"hy:.,$s?\\V<C-r>h?<C-r>h?gc<left><left><left>', true)
vnoremap('<leader>dab', [["hyqeq:v?\V<c-r>h?d E<cr>:let @"=@e<cr>:noh<cr>]], { desc = 'Delete all but ...', silent = true })
vnoremap('<leader>daa', [["hyqeq:g?\V<c-r>h?d E<cr>:let @"=@e<cr>:noh<cr>]], true)
vnoremap('<leader>yab', [["hymmqeq:v?\V<c-r>h?yank E<cr>:let @"=@e<cr>`m:noh<cr>, true]])
vnoremap('<leader>yaa', [["hymmqeq:g?\V<c-r>h?yank E<cr>:let @"=@e<cr>`m:noh<cr>]], true)

-- Base64 dencode
vnoremap('<leader>46', [[c<c-r>=substitute(system('base64 --decode', @"), '\n$', '', 'g')<cr><esc>]], true)
vnoremap('<leader>64', [[c<c-r>=substitute(system('base64', @"), '\n$', '', 'g')<cr><esc>]], true)

-- Vimrc edit mappings
nnoremap('<leader>ev', [[:execute("vsplit " . '~/.config/nvim/lua/user/options.lua')<cr>]], true)
nnoremap('<leader>ep', [[:execute("vsplit " . '~/.config/nvim/lua/plugins/init.lua')<cr>]], true)
nnoremap('<leader>el', [[:execute("vsplit " . '~/.config/nvim/lua/user/lsp/config.lua')<cr>]], true)
nnoremap('<leader>em', [[:execute("vsplit " . '~/.config/nvim/lua/user/mappings.lua')<cr>]], true)

-- Delete current buffer
nnoremap('<leader>bd', '<cmd>BDelete this<cr>', true)
-- Close current buffer
nnoremap('<leader>bc', ':close<cr>', true)

-- Abbreviations
vim.keymap.set('!a', 'dont', [[don't]], opts.no_remap)
vim.keymap.set('!a', 'seperate', [[separate]], opts.no_remap)
vim.keymap.set('!a', 'rbm', [[# TODO: remove before merging]], opts.no_remap)
vim.keymap.set('!a', 'cbm', [[# TODO: change before merging]], opts.no_remap)
vim.keymap.set('!a', 'ubm', [[# TODO: uncomment before merging]], opts.no_remap)

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
nnoremap('cii', function()
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
    vim.keymap.set('n', 'q', function()
      vim.api.nvim_buf_delete(scratch, { force = true })
      vim.keymap.del('n', 'q', { buffer = start })
    end, { buffer = buf })
  end
end, {})
nnoremap('<leader>ds', ':DiffWithSaved<cr>', true)

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
vim.keymap.set({ 'n', 'v' }, '<C-f>', function()
  return vim.fn.mode() == 'v' and ':RipGrepCWORDVisual!<cr>' or ':RipGrepCWORD!<Space>'
end, opts.no_remap_expr)

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
nnoremap('<F3>', ':call ExecuteFile()<CR>', true)

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

---------------------
-- Traverse indent --
---------------------
---Adapted from https://vi.stackexchange.com/a/12870
---Traverse to indent >= or > current indent
---@param direction integer 1 - forwards | -1 - backwards
---@param equal boolean include lines equal to current indent in search?
local function indent_traverse(direction, equal)
  return function()
    -- Get the current cursor position
    local current_line, column = unpack(vim.api.nvim_win_get_cursor(0))
    local match_line = current_line
    local match_indent = false
    local match = false

    local buf_length = vim.api.nvim_buf_line_count(0)

    -- Look for a line of appropriate indent
    -- level without going out of the buffer
    while (not match) and (match_line ~= buf_length) and (match_line ~= 1) do
      match_line = match_line + direction
      local match_line_str = vim.api.nvim_buf_get_lines(0, match_line - 1, match_line, false)[1]
      -- local match_line_is_whitespace = match_line_str and match_line_str:match('^%s*$')
      local match_line_is_whitespace = match_line_str:match '^%s*$'

      if equal then
        match_indent = vim.fn.indent(match_line) <= vim.fn.indent(current_line)
      else
        match_indent = vim.fn.indent(match_line) < vim.fn.indent(current_line)
      end
      match = match_indent and not match_line_is_whitespace
    end

    -- If a line is found go to line
    if match or match_line == buf_length then
      vim.fn.cursor { match_line, column + 1 }
    end
  end
end
-- vim.keymap.set({ 'n', 'v' }, 'gj', indent_traverse(1, true)) -- next equal indent
-- vim.keymap.set({ 'n', 'v' }, 'gk', indent_traverse(-1, true)) -- previous equal indent
--
-- vim.keymap.set({ 'n', 'v' }, 'gJ', indent_traverse(1, false)) -- next equal indent
-- vim.keymap.set({ 'n', 'v' }, 'gK', indent_traverse(-1, false)) -- previous equal indent
