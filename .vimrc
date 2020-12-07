set encoding=utf-8
scriptencoding utf-8
" Moshe's vimrc. Custom made for my needs :)

" .    .         .              .
" |\  /|         |             / \               o
" | \/ | .-. .--.|--. .-.     /___\.    ._.--.   .
" |    |(   )`--.|  |(.-'    /     \\  /  |  |   |
" '    ' `-' `--''  `-`--'  '       ``'   '  `--' `-

" Basic configurations {{{
set nocompatible
syntax enable

if executable('/bin/zsh')
  set shell=/bin/zsh\ -l
elseif executable('/bin/bash')
  set shell=/bin/bash
else
  set shell=/bin/sh
endif
" set tags=./tags,tags;$HOME

" set shellcmdflag=-ic

set number         " Show current line number
set relativenumber " Show relative line numbers
set linebreak      " Avoid wrapping a line in the middle of a word.
set nowrap
set cursorcolumn
set cursorline     " Add highlight behind current line
" hi cursorline cterm=none term=none
" highlight CursorLine guibg=#303000 ctermbg=234
set hlsearch       " highlight reg. ex. in @/ register
set incsearch      " Search as characters are typed
set ignorecase     " Search case insensitive...
set smartcase      " ignore case if search pattern is all lowercase,
" case-sensitive otherwise
set autoread       " Re-read file if it was changed from the outside
set scrolloff=7    " When about to scroll page, see 7 lines below cursor
set cmdheight=2    " Height of the command bar
set hidden         " Hide buffer if abandoned
set showmatch      " When closing a bracket (like {}), show the enclosing
" bracket for a brief second
set nostartofline  " Stop certain movements from always going to the first
" character of a line.
set confirm        " Prompt confirmation if exiting unsaved file
set lazyredraw     " redraw only when we need to.
set noswapfile
set nobackup
set nowritebackup
set wildmenu       " Displays a menu on autocomplete
set wildmode=longest:full,full " on first <Tab> it will complete to the
" longest common string and will invoke wildmenu
set title          " Changes the iterm title
set showcmd
set guifont=:h
set mouse=a
set undofile       " Enables saving undo history to a file
set colorcolumn=80 " Mark where are 80 characters to start breaking line
set guicursor=i:blinkwait700-blinkon400-blinkoff250
set fileencodings=utf-8,cp1251
set visualbell     " Use visual bell instead of beeping

if has('nvim')
  set shortmess+=c " don't give |ins-completion-menu| messages.
  set shortmess-=l " Print "lines" instead of "L"
endif

" Ignore node_modules
set wildignore+=**/node_modules/**
set wildignore+=.hg,.git,.svn,*.DS_Store,*.pyc

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

if v:version > 703 || v:version == 703 && has('patch541')
  set formatoptions+=j " Delete comment character when joining commented lines
endif

filetype plugin on
filetype plugin indent on

set list
set listchars=trail:·,precedes:«,extends:»,eol:↲,tab:▸\
set fillchars=vert:\|,fold:·

set path+=** " When searching, search also subdirectories

" Set python path
if executable('/usr/local/bin/python3')
  let g:python3_host_prog='/usr/local/bin/python3'
elseif executable('/usr/bin/python3')
  let g:python3_host_prog='/usr/bin/python3'
endif

" Auto load file changes when focus or buffer is entered
augroup ReloadFile
  autocmd!
  au FocusGained,BufEnter * :checktime
augroup END

if &history < 1000
  set history=1000
endif

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved. {{{
if has('patch-8.1.1564')
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif
" }}}

" Set relativenumber when focused {{{
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave * set number relativenumber
  autocmd BufLeave,FocusLost,InsertEnter   * set number norelativenumber
augroup END
" }}}

" set verbose=1
if has('termguicolors')
  " let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  " let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif
" " Terminal colors {{{


" " Allow color schemes to do bright colors without forcing bold.
" if &t_Co == 8 && $TERM !~# '^Eterm'
"   set t_Co=256
" endif

" if has('nvim')
"   " https://github.com/neovim/neovim/issues/2897#issuecomment-115464516
"   " let g:terminal_color_0 = '#4e4e4e'
"   " let g:terminal_color_1 = '#d68787'
"   " let g:terminal_color_2 = '#5f865f'
"   " let g:terminal_color_3 = '#d8af5f'
"   " let g:terminal_color_4 = '#85add4'
"   " let g:terminal_color_5 = '#d7afaf'
"   " let g:terminal_color_6 = '#87afaf'
"   " let g:terminal_color_7 = '#d0d0d0'
"   " let g:terminal_color_8 = '#626262'
"   " let g:terminal_color_9 = '#d75f87'
"   " let g:terminal_color_10 = '#87af87'
"   " let g:terminal_color_11 = '#ffd787'
"   " let g:terminal_color_12 = '#add4fb'
"   " let g:terminal_color_13 = '#ffafaf'
"   " let g:terminal_color_14 = '#87d7d7'
"   " let g:terminal_color_15 = '#e4e4e4'

"   autocmd BufReadPost *
"         \ if line("'\"") >= 1 && line("'\"") <= line("$") |
"         \   exe "normal! g`\"" |
"         \ endif
"   let $NVIM_TUI_ENABLE_TRUE_COLOR=1
" else
"   let g:terminal_ansi_colors = [
"         \ '#4e4e4e', '#d68787', '#5f865f', '#d8af5f',
"         \ '#85add4', '#d7afaf', '#87afaf', '#d0d0d0',
"         \ '#626262', '#d75f87', '#87af87', '#ffd787',
"         \ '#add4fb', '#ffafaf', '#87d7d7', '#e4e4e4']
"   set nocursorline
"   set nocursorcolumn
" endif
" " }}}
" }}}

" Indentation {{{
" Indentation settings for using 4 spaces instead of tabs.
" Do not change 'tabstop' from its default value of 8 with this setup.
filetype indent on
if exists('+breakindent')
  set breakindent   " Maintain indent on wrapping lines
endif
set autoindent    " always set autoindenting on
set copyindent    " copy the previous indentation on autoindenting
set smartindent   " Number of spaces to use for each step of (auto)indent.
set shiftwidth=4  " Number of spaces for each indent
set softtabstop=4
set tabstop=4
set smarttab      " insert tabs on the start of a line according to
" shiftwidth, not tabstop
set expandtab     " Tab changes to spaces. Format with :retab
" }}}

" Statusline {{{
set statusline=%.50F\ -\ FileType:\ %y
set statusline+=%=        " Switch to the right side
set statusline+=%l    " Current line
set statusline+=/    " Separator
set statusline+=%L\   " Total lines
set showtabline=2
" }}}

" Mappings {{{

" Map leader to space
let mapleader=' '
let maplocalleader = "\\"

" Toggle number sets
" nnoremap <leader>num :set number! \| set relativenumber!<cr>

" Map 0 to first non-blank character
nnoremap 0 ^
" Move to the end of the line
nnoremap E $
vnoremap E $

"indent/unindent visual mode selection with tab/shift+tab
vmap <tab> >gv
vmap <s-tab> <gv

" Sudo write
command! W w :term sudo tee % > /dev/null

" with this you can save with ;wq
" nnoremap ; :

" Windows mappings {{{
nnoremap <Leader><Leader> <C-^>
nnoremap <tab> <c-w>w
nnoremap <c-w><c-c> <c-w>c
nnoremap <leader>n :bn<cr>

" Delete current buffer
nnoremap <silent> <leader>bd :bp <bar> bd #<cr>
" Close current buffer
nnoremap <silent> <leader>bc :close<cr>

" Split navigations mappings
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

set splitbelow
set splitright

" }}}

" Run macro
nnoremap Q @q

" Insert mappings {{{

" Paste in insert mode
inoremap <c-v> <c-r>"

if empty(mapcheck('<C-U>', 'i'))
  inoremap <C-U> <C-G>u<C-U>
endif
if empty(mapcheck('<C-W>', 'i'))
  inoremap <C-W> <C-G>u<C-W>
endif

" }}}

" Quickfix {{{
nnoremap ]q :cnext<cr>zz
nnoremap [q :cprev<cr>zz
nnoremap ]l :lnext<cr>zz
nnoremap [l :lprev<cr>zz
" }}}

" This creates a new line of '=' signs the same length of the line
nnoremap <leader>= yypVr=

" Map dp and dg with leader for diffput and diffget
nnoremap <leader>dp :diffput<cr>
nnoremap <leader>dg :diffget<cr>
nnoremap <leader>du :windo diffupdate<cr>
nnoremap <leader>dn :windo diffthis<cr>
nnoremap <leader>df :windo diffoff<cr>

" Map enter to no highlight
nnoremap <silent> <CR> :nohlsearch<CR><CR>

" Remove blank spaces from the end of the line
" nnoremap <silent> <leader>a :let _s=@/ <Bar> :%s/\s\+$//e <Bar> :let @/=_s
"       \<Bar> :nohl <Bar> :unlet _s <CR>

" Set mouse=v mapping
nnoremap <leader>ma :set mouse=a<cr>
nnoremap <leader>mv :set mouse=v<cr>

" Don't lose seletion when indenting
xnoremap <  <gv
xnoremap >  >gv

" Search mappings {{{
nnoremap <silent> * :execute "normal! *N"<cr>
nnoremap <silent> # :execute "normal! #n"<cr>

nnoremap <expr> n  'Nn'[v:searchforward]
xnoremap <expr> n  'Nn'[v:searchforward]
onoremap <expr> n  'Nn'[v:searchforward]

nnoremap <expr> N  'nN'[v:searchforward]
xnoremap <expr> N  'nN'[v:searchforward]
onoremap <expr> N  'nN'[v:searchforward]

" Search visually selected text with // or * or # {{{
vnoremap // y/\V<C-R>=escape(@",'/\')<CR><CR>

function! s:StarSearch(cmdtype) abort
  let old_reg=getreg('"')
  let old_regtype=getregtype('"')
  norm! gvy
  let @/ = '\V' . substitute(escape(@", a:cmdtype . '\.*$^~['), '\_s\+', '\\_s\\+', 'g')
  norm! gVzv
  call setreg('"', old_reg, old_regtype)

endfunction

vnoremap * :<C-u>call <SID>StarSearch('/')<CR>/<C-R>=@/<CR><CR>
vnoremap # :<C-u>call <SID>StarSearch('?')<CR>?<C-R>=@/<CR><CR>
" }}}

" }}}

" Map - to move a line down and _ a line up
" nnoremap -  :<c-u>execute 'move +'. v:count1<cr>
" nnoremap _  :<c-u>execute 'move -1-'. v:count1<cr>
nnoremap - "ldd$"lp
nnoremap _ "ldd2k"lp

" Base64 decode
vnoremap <leader>64 y:echo system('base64 --decode', @")<cr>

" Map ctrl+u to toggle word to uppercase/lowercase in insert and normal and
" visual
nnoremap U viw~
vnoremap U ~

" Vimrc edit mappings {{{
let g:myvimrc = '~/.vimrc'
let g:myvimrcplugins = '~/.vimrcplugins'

nnoremap <silent> <leader>ev :execute("vsplit ".g:myvimrc)<cr>
nnoremap <silent> <leader>sv :execute("source ".g:myvimrc)<cr>
" exe("autocmd BufWritePost ".g:myvimrc." source ".g:myvimrc)

function! LoadPlugins() abort
  execute('so '.g:myvimrcplugins)
  PlugInstall
  echom 'Ran PlugInstall'
  execute('windo so '.g:myvimrcplugins)
  echom 'Sourced '.g:myvimrcplugins.' on all windows'
endfunction

nnoremap <silent> <leader>ep :execute("vsplit ".g:myvimrcplugins)<cr>
nnoremap <silent> <leader>sp :call LoadPlugins()<cr>
" }}}

" Remove blank space from the start of the line to the end of previous line
inoremap ddd <esc>ma^i  <esc>hvk$x`ai
nnoremap <leader>dd ma^i  <esc>hvk$x`a

" highlight last inserted text
nnoremap gV `[v`]

" terminal mappings {{{
if exists(':terminal')
  " Start terminal in insert mode
  augroup TerminalAugroup
    autocmd!
    autocmd BufEnter * if &buftype == 'terminal' | :startinsert | endif

  augroup END
  tnoremap <Esc> <C-\><C-n>
  " nnoremap <leader>term :new term://zsh<cr>
endif
" }}}

" Exit insert mode
inoremap jk <esc>
nnoremap <leader>qq :qall<cr>
"inoremap <esc> <nop>

" Clipboard mappings {{{
" " Copy visual selection to clipboard
" vnoremap <leader>y "*y
" " Copy entire file to clipboard
nnoremap Y :%y+<cr>
" " Copy line from cursor until the end
" nnoremap <leader>ye vg_y
"=============================== }}}

" remap `*`/`#` to search forwards/backwards (resp.) {{{
" w/o moving cursor
" }}}

" Search and Replace {{{
nnoremap <Leader>r :.,$s?<C-r><C-w>?<C-r><C-w>?gc<Left><Left><Left>
" vnoremap <Leader>r :%s/<C-r><C-w>//g<Left><Left>
vnoremap <leader>r "hy:.,$s?<C-r>h?<C-r>h?gc<left><left><left>
" }}}

" Delete/yank mappings {{{
vnoremap <leader>dab "hyqeq:v?\V<c-r>h?d E<cr>:let @"=@e<cr>:noh<cr>
vnoremap <leader>daa "hyqeq:g?\V<c-r>h?d E<cr>:let @"=@e<cr>:noh<cr>

vnoremap <leader>yab "hymmqeq:v?\V<c-r>h?yank E<cr>:let @"=@e<cr>`m:noh<cr>
vnoremap <leader>yaa "hymmqeq:g?\V<c-r>h?yank E<cr>:let @"=@e<cr>`m:noh<cr>

vnoremap <leader>p "_dP

" }}}

" Split long lines {{{
" Change every " -" with " \<cr> -" to break long lines of bash
nnoremap <silent> <leader>\ :.s/ -/ \\\r  -/g<cr>:noh<cr>

" Every parameter in its own line
function SplitParamLines() abort
  let f_line_num = line('.')
  let indent_length = indent(f_line_num)
  exe "normal! 0f(a\<cr>\<esc>"
  exe ".s/\s*,/,\r" . repeat(' ', indent_length + &shiftwidth - 1) . '/g'
  nohlsearch
  exe "normal! 0t)a\<cr>\<esc>"
endfunction
nnoremap <silent> <leader>( :call SplitParamLines()<cr>
" }}}

" move vertically by visual line (don't skip wrapped lines) {{{
nnoremap j gj
nnoremap k gk
" }}}

" Change working directory based on open file
nnoremap <leader>cd :cd %:p:h<CR>:pwd<CR>

" Convert all tabs to spaces
nnoremap <leader>ct<space> :retab<cr>

"" }}}

" Netrw (directory browsing) out-of-the-box plugin {{{
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_browse_split = 4
let g:netrw_altv = 1
let g:netrw_winsize = 25
let g:netrw_keepdir = 1
" augroup ProjectDrawer
"   autocmd!
"   autocmd VimEnter * :if !exists("NERDTree") | Vexplore | endif
" augroup END

map <silent> <C-o> :Lexplore<CR>
" }}}

" Enable folding {{{
set foldenable
set foldmethod=syntax
set foldlevel=999
set foldlevelstart=10
" Enable folding with the leader-f/a
nnoremap <leader>f za
nnoremap <leader>caf zM
nnoremap <leader>oaf zR
" Open level folds
nnoremap <leader>olf zczA

" }}}

" Abbreviations {{{
" inoreabbrev def def () {<cr><tab><cr>}<esc>2k0f(a
" inoreabbrev function function () {<cr><tab><cr>}<esc>2k0f(i
" inoreabbrev if <bs>if () {<cr><tab><cr>}<esc>2k0f(a
inoreabbrev teh the
inoreabbrev seperate separate
inoreabbrev dont don't
" }}}

" Auto-Parentheses {{{
" Auto-insert closing parenthesis/brace - autopairs plugin replaces this
" inoremap ( ()<Left>
" inoremap { {}<Left>
"
" " Auto-delete closing parenthesis/brace {{{
" function! BetterBackSpace() abort
"     let cur_line = getline('.')
"     let before_char = cur_line[col('.')-2]
"     let after_char = cur_line[col('.')-1]
"     if (before_char == '(' && after_char == ')') || (before_char == '{' && after_char == '}')
"         return "\<Del>\<BS>"
"     else
"         return "\<BS>"
" endfunction
" " }}}
" inoremap <silent> <BS> <C-r>=BetterBackSpace()<CR>
"
" " Skip over closing parenthesis/brace
" inoremap <expr> ) getline('.')[col('.')-1] == ")" ? "\<Right>" : ")"
" inoremap <expr> } getline('.')[col('.')-1] == "}" ? "\<Right>" : "}"
" }}}

" Surround {{{
" nnoremap <leader>" viw<esc>a"<esc>bi"<esc>lel
" nnoremap <leader>' viw<esc>a'<esc>bi'<esc>lel
" nnoremap <leader>{ viw<esc>a }<esc>bi{ <esc>lel
" nnoremap <leader>( viw<esc>a)<esc>bi(<esc>lel
" nnoremap <leader>[ viw<esc>a]<esc>bi[<esc>lel

" vnoremap <leader>( c()<esc>P
" vnoremap <leader>[ c[]<esc>P
" vnoremap <leader>{ c{}<esc>P
" vnoremap <leader>" c""<esc>P
" vnoremap <leader>' c''<esc>P
" }}}

" Conceals {{{

let g:conceal_rules = [
      \ ['!=', '≠'],
      \ ['<=', '≤'],
      \ ['>=', '≥'],
      \ ['=>', '⇒'],
      \ ['==', '≡'],
      \ ['===', '≡≡'],
      \ ['\<function\>', 'ƒ'],
      \ ]

" Conceal is not needed when we have FiraCode with ligatures
" for [value, display] in g:conceal_rules
"   execute "call matchadd('Conceal', '".value."', 10, -1, {'conceal': '".display."'})"
" endfor
set conceallevel=1

" call matchadd('Conceal', 'package', 10, 99, {'conceal': 'p'})
"}}}

" Diff with last save function {{{
function! s:DiffWithSaved()
  let filetype=&ft
  diffthis
  vnew | r # | normal! 1Gdd
  exe 'setlocal bt=nofile bh=wipe nobl noswf ro foldlevel=999 ft=' . filetype
  diffthis
  nnoremap <buffer> q :bd!<cr>
  augroup ShutDownDiffOnLeave
    autocmd! * <buffer>
    autocmd BufDelete,BufUnload,BufWipeout <buffer> wincmd p | diffoff |
          \wincmd p
  augroup END

  wincmd p
endfunction
com! DiffSaved call s:DiffWithSaved()
nnoremap <leader>ds :DiffSaved<cr>
" }}}

" Special filetypes {{{
augroup special_filetype
  au!
  autocmd BufNewFile,BufRead *yaml setf yaml
  autocmd FileType json syntax match Comment +\/\/.\+$+
  autocmd BufNewFile,BufRead aliases.sh setf zsh
  autocmd FileType javascript set filetype=javascriptreact | set iskeyword+=-
augroup end
let g:sh_fold_enabled = 4

com! FormatJSON exe '%!python -m json.tool'

function FormatEqual() abort
  let save_cursor = getcurpos()
  normal! gg=G
  silent! %s#)\zs\ze{# #g
  call setpos('.', save_cursor)
endfunction

" }}}

" Run current buffer {{{

nnoremap <silent> <F5> :call ExecuteFile()<CR>

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
  let l:cmd = get(l:filetype_to_command, &filetype, 'bash')
  :%y
  new | 0put
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
  exe '%!'.l:cmd
  normal! ggO
  call setline(1, 'Output of ' . l:cmd . ' command:')
  normal! yypVr=o
endfunction

" }}}

" Grep {{{
" This is only availale in the quickfix window, owing to the filetype
" restriction on the autocmd (see below).
function! <SID>OpenQuickfix(new_split_cmd)
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
if executable('ag')
  let &grepprg='ag --vimgrep --smart-case --hidden --follow --ignore "!{' . &wildignore . '}" $*'
  set grepformat=%f:%l:%c:%m
elseif executable('rg')
  let &grepprg="rg --vimgrep --no-heading --smart-case --hidden --follow -g '!{" . &wildignore . "}' $*"
  set grepformat=%f:%l:%c:%m,%f:%l:%m
else
  let &grepprg='grep -n -r --exclude=' . shellescape(&wildignore) . ' . -- $*'
endif

function s:RipGrepCWORD(bang, visualmode, ...) abort
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
  echom 'Searching for ' . search_word
  " Silent removes the "press enter to continue" prompt, and band (!) is for
  " not jumping to the first result
  let grepcmd = 'silent grep' . a:bang .' -- ' . shellescape(search_word)
  execute grepcmd
endfunction
command! -bang -range -nargs=? RipGrepCWORD call <SID>RipGrepCWORD("<bang>", v:false, <q-args>)
command! -bang -range -nargs=? RipGrepCWORDVisual call <SID>RipGrepCWORD("<bang>", v:true, <q-args>)
nmap <c-f> :RipGrepCWORD!<Space>
vmap <c-f> :RipGrepCWORDVisual!<cr>
" }}}

" Highlight word under cursor {{{
function! s:HighlightWordUnderCursor()
  let disabled_ft = [
        \'qf',
        \'fugitive',
        \'nerdtree',
        \'gundo',
        \'diff',
        \'fzf',
        \'floaterm',
        \'vim-plug'
  \]
  let disabled_buftypes = ['terminal', 'quickfix', 'help']
  let nohl_conditions = getline('.')[col('.')-1] =~# '[[:punct:][:blank:]]' || &diff || index(disabled_buftypes, &buftype) >= 0 || index(disabled_ft, &filetype) >= 0

  if !nohl_conditions
    hi MatchWord cterm=undercurl ctermbg=240 gui=undercurl guibg=#665c54
    exec 'match MatchWord /\V\<' . substitute(expand('<cword>'), '/', '\/', 'g') . '\>/'
  else
    match none
  endif
endfunction

augroup MatchWord
  autocmd!
  autocmd! CursorHold,CursorHoldI * call <SID>HighlightWordUnderCursor()
augroup END
" }}}
