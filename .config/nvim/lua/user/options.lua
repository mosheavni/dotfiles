vim.opt.compatible = false

-- disable legacy vim filetype detection in favor of new lua based from neovim
vim.g.do_filetype_lua    = 1
vim.g.did_load_filetypes = 0

vim.opt.cursorcolumn = true
vim.opt.cursorline   = true -- Add highlight behind current line
vim.opt.shortmess:append { c = true, l = false, q = false, S = false }
vim.opt.list = true
vim.opt.listchars = { tab = '┆·', trail = '·', precedes = '', extends = '', eol = '↲', }
-- set lcscope=tab:┆·,trail:·,precedes:,extends:
vim.opt.fillchars = { vert = '|', fold = '·' }
vim.opt.emoji = false

vim.opt.number         = true -- Show current line number
vim.opt.relativenumber = true -- Show relative line numbers
vim.opt.linebreak      = true -- Avoid wrapping a line in the middle of a word.
vim.opt.wrap           = true -- Wrap long lines
vim.opt.hlsearch       = true -- highlight reg. ex. in @/ register
vim.opt.incsearch      = true -- Search as characters are typed
vim.opt.inccommand     = "split" -- Incremental search and replace with small split window
vim.opt.ignorecase     = true -- Search case insensitive...
vim.opt.smartcase      = true -- ignore case if search pattern is all lowercase, case-sensitive otherwise
vim.opt.autoread       = true -- Re-read file if it was changed from the outside
vim.opt.scrolloff      = 7 -- When about to scroll page, see 7 lines below cursor
vim.opt.cmdheight      = 2 -- Height of the command bar
vim.opt.hidden         = true -- Hide buffer if abandoned
vim.opt.showmatch      = true -- When closing a bracket (like {}), show the enclosing
vim.opt.splitbelow     = true -- Horizontaly plitted windows open below
vim.opt.splitright     = true -- Vertically plitted windows open below bracket for a brief second
vim.opt.startofline    = false -- Stop certain movements from always going to the first character of a line.
vim.opt.confirm        = true -- Prompt confirmation if exiting unsaved file
vim.opt.lazyredraw     = true -- redraw only when we need to.
vim.opt.swapfile       = false
vim.opt.backup         = false
vim.opt.writebackup    = false
vim.opt.wildmenu       = true -- Displays a menu on autocomplete
vim.opt.wildmode       = { 'longest:full', 'full' } -- Command-line completion mode

vim.opt.title         = true -- Changes the iterm title
vim.opt.showcmd       = true
vim.opt.guifont       = ':h'
vim.opt.mouse         = 'a'
vim.opt.undofile      = true -- Enables saving undo history to a file
vim.opt.colorcolumn   = '80' -- Mark where are 80 characters to start breaking line
vim.opt.textwidth     = 80
vim.opt.fileencodings = { "utf-8", "cp1251" }
vim.opt.encoding      = 'utf-8'
vim.opt.visualbell    = true -- Use visual bell instead of beeping
vim.opt.conceallevel  = 1
vim.opt.showmode      = false -- Redundant as lighline takes care of that
vim.opt.history       = 1000
vim.opt.termguicolors = true
vim.opt.signcolumn    = "auto"

-- Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable delays and poor user experience.
vim.opt.updatetime = 300

-- Ignore node_modules and other dirs
vim.opt.wildignore:append { '**/node_modules/**', '.hg', '.git', '.svn', '*.DS_Store', '*.pyc' }
vim.opt.path:append { '**' }

-- Folding
vim.opt.foldenable = true
vim.opt.foldmethod = "syntax"
vim.opt.foldlevel = 999
vim.opt.foldlevelstart = 10

vim.opt.formatoptions:append { j = true, t = false, r = true, o = true, l = true } -- j = Delete comment character when joining commented lines. t = auto break long lines

-- Indenting
vim.opt.breakindent = true -- Maintain indent on wrapping lines
vim.opt.autoindent = true -- always set autoindenting on
vim.opt.copyindent = true -- copy the previous indentation on autoindenting
vim.opt.smartindent = true -- Number of spaces to use for each step of (auto)indent.
vim.opt.shiftwidth = 4 -- Number of spaces for each indent
vim.opt.softtabstop = 4
vim.opt.tabstop = 4
vim.opt.smarttab = true -- insert tabs on the start of a line according to shiftwidth, not tabstop
vim.opt.expandtab = true -- Tab changes to spaces. Format with :retab

-- Set shell
if vim.fn.executable('/bin/zsh') == 1 then
  vim.opt.shell = '/bin/zsh -l'
elseif vim.fn.executable('/bin/bash') == 1 then
  vim.opt.shell = '/bin/bash'
else
  vim.opt.shell = '/bin/sh'
end

-- Set python path
if vim.fn.executable('/usr/local/bin/python3') == 1 then
  vim.g.python3_host_prog = '/usr/local/bin/python3'
elseif vim.fn.executable('/usr/bin/python3') == 1 then
  vim.g.python3_host_prog = '/usr/bin/python3'
end


vim.cmd [[
hi ColorColumn ctermbg=238 guibg=lightgrey

let &t_SI = "\<Esc>]50;CursorShape=1\x7"
let &t_SR = "\<Esc>]50;CursorShape=2\x7"

filetype indent on
]]

-- Abbreviations
vim.cmd [[
inoreabbrev teh the
inoreabbrev seperate separate
inoreabbrev dont don't
inoreabbrev rbm # TODO: remove before merging
inoreabbrev cbm # TODO: change before merging
inoreabbrev ubm # TODO: uncomment before merging
inoreabbrev funciton function
inoreabbrev functiton function
inoreabbrev fucntion function
inoreabbrev funtion function
inoreabbrev erturn return
inoreabbrev retunr return
inoreabbrev reutrn return
inoreabbrev reutn return
inoreabbrev queyr query
inoreabbrev htis this
inoreabbrev foreahc foreach
inoreabbrev forech foreach
]]


vim.cmd [[
let g:sh_fold_enabled = 4

com! FormatJSON exe '%!python -m json.tool'

function FormatEqual() abort
  let save_cursor = getcurpos()
  normal! gg=G
  silent! exe '%s#)\zs\ze{# #g'
  call setpos('.', save_cursor)
  echom 'Formatted with equalprg'
endfunction

]]

-- Run current buffer
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

nnoremap <silent> <F5> :call ExecuteFile()<CR>
]]

-- Grep
vim.cmd [[
" This is only availale in the quickfix window, owing to the filetype
" restriction on the autocmd (see below).
function! s:OpenQuickfix(new_split_cmd)
  " 1. the current line is the result idx as we are in the quickfix
  let l:qf_idx = line('.')
  " 2. jump to the previous window
  wincmd p
  " 3. switch to a new split (the new_split_cmd will be 'vnew' or 'split')
  execute a:new_split_cmd
  " 4. open the 'current' item of the quickfix list in the newly created buffer
  "    (the current means, the one focused before switching to the new buffer)
  execute l:qf_idx . 'cc'
endfunction

augroup grep_augroup
  autocmd!
  autocmd QuickFixCmdPost [^l]* copen
  autocmd QuickFixCmdPost l*    lopen
  autocmd FileType qf nnoremap <buffer> <C-v> :call <SID>OpenQuickfix("vnew")<CR>
  autocmd FileType qf nnoremap <buffer> <C-x> :call <SID>OpenQuickfix("split")<CR>
augroup END

" Set grepprg as RipGrep or ag (the_silver_searcher), fallback to grep
if executable('rg')
  let &grepprg="rg --vimgrep --no-heading --smart-case --hidden --follow -g '!{" . &wildignore . "}' $*"
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

function RipGrepCWORD(bang, visualmode, ...) abort
  let search_word = a:1

  if a:visualmode
    " Get the line and column of the visual selection marks
    let [lnum1, col1] = getpos("'<")[1:2]
    let [lnum2, col2] = getpos("'>")[1:2]

    " Get all the lines represented by this range
    let lines = getline(lnum1, lnum2)

    " The last line might need to be cut if the visual selection didn't end on the last column
    let lines[-1] = lines[-1][: col2 - (&selection ==? 'inclusive' ? 1 : 2)]
    " The first line might need to be trimmed if the visual selection didn't start on the first column
    let lines[0] = lines[0][col1 - 1:]

    " Get the desired text
    let search_word = join(lines, "\n")
  endif
  if search_word ==? ''
    let search_word = expand('<cword>')
  endif

  " Set bang command for literal search (no regexp expansion)
  let search_message_literally = "for " . search_word
  if a:bang == "!"
    let search_message_literally = "literally for " . search_word
    let search_word = get(g:, 'grep_literal_flag', "") . ' ' . shellescape(search_word)
  endif

  echom 'Searching ' . search_message_literally

  " Silent removes the "press enter to continue" prompt
  " Bang (!) is for literal search (no regexp expansion)
  let grepcmd = 'silent grep! ' . search_word
  execute grepcmd
endfunction
command! -bang -range -nargs=? RipGrepCWORD call RipGrepCWORD("<bang>", v:false, <q-args>)
command! -bang -range -nargs=? RipGrepCWORDVisual call RipGrepCWORD("<bang>", v:true, <q-args>)
nmap <c-f> :RipGrepCWORD!<Space>
vmap <c-f> :RipGrepCWORDVisual!<cr>
]]


-- Terminal configurations
vim.cmd [[
if exists(':terminal')

  if !exists('g:terminal_ansi_colors')
    let g:terminal_ansi_colors = [
          \'#21222C',
          \'#FF5555',
          \'#69FF94',
          \'#FFFFA5',
          \'#D6ACFF',
          \'#FF92DF',
          \'#A4FFFF',
          \'#FFFFFF',
          \'#636363',
          \'#F1FA8C',
          \'#BD93F9',
          \'#FF79C6',
          \'#8BE9FD',
          \'#F8F8F2',
          \'#6272A4',
          \'#FF6E6E'
    \]
  endif

  " Function to set terminal colors
  fun! s:setTerminalColors()
    if exists('g:terminal_ansi_colors')
      for i in range(len(g:terminal_ansi_colors))
          exe 'let g:terminal_color_' . i . ' = g:terminal_ansi_colors[' . i . ']'
      endfor
      unlet! g:terminal_ansi_colors
    endif
  endfunction

  augroup TerminalAugroup
    autocmd!

    " Start terminal in insert mode
    autocmd BufEnter * if &buftype == 'terminal' | :startinsert | endif

    " Call terminal colors function only after colorscheme changed
    autocmd Colorscheme * call <sid>setTerminalColors()
  augroup END

  tnoremap <Esc> <C-\><C-n>

  " To force using 256 colors
  set t_Co=256
endif

]]

-- Visual Calculator
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

-- Last position on document
vim.cmd [[
if has('autocmd')
  augroup redhat
    autocmd!
    " When editing a file, always jump to the last cursor position
    autocmd BufReadPost *
    \ if line("'\"") > 0 && line ("'\"") <= line("$") |
    \   exe "normal! g'\"" |
    \ endif
  augroup END
endif
]]

vim.cmd [[
" Better yanking {{{
" note:
"   the register 1 is reserved for deletion
"   there's no "small yank" register
"   can break :h redo-register
"   still misses any manual register 0 change
augroup YankShift | au!
    let s:regzero = [getreg(0), getregtype(0)]
    autocmd TextYankPost * call <SID>yankshift(v:event)
augroup end

function! s:yankshift(event)
    if a:event.operator ==# 'y' && (empty(a:event.regname) || a:event.regname == '"')
        for l:regno in range(8, 2, -1)
            call setreg(l:regno + 1, getreg(l:regno), getregtype(l:regno))
        endfor
        call setreg(2, s:regzero[0], s:regzero[1])
        let s:regzero = [a:event.regcontents, a:event.regtype]
    elseif a:event.regname == '0'
        let s:regzero = [a:event.regcontents, a:event.regtype]
    endif
endfunction
" }}}
]]
