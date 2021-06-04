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
" if !exists('g:syntax_on') | syntax enable | endif
if has('vim_starting')
  if has('syntax') && !exists('g:syntax_on')
    syntax enable
  endif
endif

if executable('/bin/zsh')
  set shell=/bin/zsh\ -l
elseif executable('/bin/bash')
  set shell=/bin/bash
else
  set shell=/bin/sh
endif
" set tags=./tags,tags;$HOME

colorscheme darkblue
" set shellcmdflag=-ic

set number                     " Show current line number
set relativenumber             " Show relative line numbers
set linebreak                  " Avoid wrapping a line in the middle of a word.
set wrap
if has('nvim')
  set cursorcolumn
  set cursorline                 " Add highlight behind current line
endif
                               " hi cursorline cterm=none term=none
                               " highlight CursorLine guibg=#303000 ctermbg=234
set hlsearch                   " highlight reg. ex. in @/ register
set incsearch                  " Search as characters are typed
if exists('&inccommand')
  set inccommand=split           " Incremental search and replace with small split window
endif
set ignorecase                 " Search case insensitive...
set smartcase                  " ignore case if search pattern is all lowercase,
                               " case-sensitive otherwise
set autoread                   " Re-read file if it was changed from the outside
set scrolloff=7                " When about to scroll page, see 7 lines below cursor
set cmdheight=2                " Height of the command bar
set hidden                     " Hide buffer if abandoned
set showmatch                  " When closing a bracket (like {}), show the enclosing
set splitbelow                 " Horizontaly plitted windows open below
set splitright                 " Vertically plitted windows open below
                               " bracket for a brief second
set nostartofline              " Stop certain movements from always going to the first
                               " character of a line.
set confirm                    " Prompt confirmation if exiting unsaved file
set lazyredraw                 " redraw only when we need to.
set noswapfile
set nobackup
set nowritebackup
set wildmenu                   " Displays a menu on autocomplete
set wildmode=longest:full,full " on first <Tab> it will complete to the
                               " longest common string and will invoke wildmenu
set title                      " Changes the iterm title
set showcmd
set guifont=:h
set mouse=a
set undofile                   " Enables saving undo history to a file
set colorcolumn=80             " Mark where are 80 characters to start breaking line
set textwidth=80
" set guicursor=i:blinkwait700-blinkon400-blinkoff250
hi ColorColumn ctermbg=238 guibg=lightgrey
set fileencodings=utf-8,cp1251
set visualbell                 " Use visual bell instead of beeping
set formatoptions-=t           " auto break long lines"

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

if has('nvim')
  set list
  set listchars=tab:┆·,trail:·,precedes:,extends:,eol:↲,
  " set lcscope=tab:┆·,trail:·,precedes:,extends:
  set fillchars=vert:\|,fold:·
endif

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
elseif exists('&signcolumn')
  set signcolumn=yes
endif
" }}}

" set verbose=1
if has('termguicolors')
  " let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  " let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

let &t_SI = "\<Esc>]50;CursorShape=1\x7"
let &t_SR = "\<Esc>]50;CursorShape=2\x7"

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

" Map 0 to first non-blank character
nnoremap 0 ^

" Move to the end of the line
nnoremap L $zL
vnoremap L $
nnoremap H 0zH
vnoremap H 0

"indent/unindent visual mode selection with tab/shift+tab
vmap <tab> >gv
vmap <s-tab> <gv

" Sudo write
command! W w :term sudo tee % > /dev/null

" Copy number of lines and paste below
nnoremap <leader>cp :<c-u>exe 'normal! y' . (v:count == 0 ? 1 : v:count) . 'j' . (v:count == 0 ? 1 : v:count) . 'jo<C-v><Esc>p'<cr>

" Windows mappings
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

" Run macro
nnoremap Q @q

" Paste in insert mode
inoremap <c-v> <c-r>"

" Quickfix
nnoremap ]q :cnext<cr>zz
nnoremap [q :cprev<cr>zz
nnoremap ]l :lnext<cr>zz
nnoremap [l :lprev<cr>zz

" This creates a new line of '=' signs the same length of the line
nnoremap <leader>= yypVr=

" Map dp and dg with leader for diffput and diffget
nmap <leader>dp :diffput<cr>
nmap <leader>dg :diffget<cr>
nmap <leader>du :windo diffoff <bar> windo diffupdate<cr>
nmap <leader>dn :windo diffthis<cr>
nmap <leader>df :windo diffoff<cr>

" Map enter to no highlight
nnoremap <silent> <CR> :nohlsearch<CR><CR>

" Set mouse=v mapping
nnoremap <leader>ma :set mouse=a<cr>
nnoremap <leader>mv :set mouse=v<cr>

" Search mappings
nnoremap <silent> * :execute "normal! *N"<cr>
nnoremap <silent> # :execute "normal! #n"<cr>
nnoremap <expr> n  'Nn'[v:searchforward]
xnoremap <expr> n  'Nn'[v:searchforward]
onoremap <expr> n  'Nn'[v:searchforward]
nnoremap <expr> N  'nN'[v:searchforward]
xnoremap <expr> N  'nN'[v:searchforward]
onoremap <expr> N  'nN'[v:searchforward]

" Search visually selected text with // or * or #
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

" Map - to move a line down and _ a line up
nnoremap - "ldd$"lp
nnoremap _ "ldd2k"lp

" Base64 decode
vnoremap <silent><leader>64 c<c-r>=substitute(system('base64 --decode', @"), '\n$', '', 'g')<cr><esc>
vnoremap <silent><leader>46 c<c-r>=substitute(system('base64', @"), '\n$', '', 'g')<cr><esc>

" Map U to toggle word to uppercase/lowercase in insert and normal and
" visual
nnoremap U viw~
vnoremap U ~

" Vimrc edit mappings
nnoremap <silent> <leader>ev :execute("vsplit ".'~/.vimrc')<cr>
nnoremap <silent> <leader>ep :execute("vsplit ".'~/.vimrcplugins')<cr>

" highlight last inserted text
nnoremap gV `[v`]

" Exit insert mode
inoremap jk <esc>
nnoremap <leader>qq :qall<cr>

" Copy entire file to clipboard
nnoremap Y :%y+<cr>

" Search and Replace
nnoremap <Leader>r :.,$s?<C-r><C-w>?<C-r><C-w>?gc<Left><Left><Left>
vnoremap <leader>r "hy:.,$s?<C-r>h?<C-r>h?gc<left><left><left>

vnoremap <leader>dab "hyqeq:v?\V<c-r>h?d E<cr>:let @"=@e<cr>:noh<cr>
vnoremap <leader>daa "hyqeq:g?\V<c-r>h?d E<cr>:let @"=@e<cr>:noh<cr>

vnoremap <leader>yab "hymmqeq:v?\V<c-r>h?yank E<cr>:let @"=@e<cr>`m:noh<cr>
vnoremap <leader>yaa "hymmqeq:g?\V<c-r>h?yank E<cr>:let @"=@e<cr>`m:noh<cr>

vnoremap <leader>p "_dP

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

" Change \n to new lines
nmap <silent> <leader><cr> :silent! %s?\\n?\r?g<bar>silent! %s?\\t?\t?g<bar>silent! %s?\\r?\r?g<cr>:noh<cr>

" move vertically by visual line (don't skip wrapped lines)
nnoremap j gj
nnoremap k gk

" Change working directory based on open file
nnoremap <leader>cd :cd %:p:h<CR>:pwd<CR>

" Move visually selected block
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

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
nnoremap <leader>olf zazczA

" }}}

" Abbreviations {{{
inoreabbrev teh the
inoreabbrev seperate separate
inoreabbrev dont don't
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
  autocmd FileType json syntax match Comment +\/\/.\+$+
  autocmd BufNewFile,BufRead aliases.sh setf zsh
  autocmd FileType javascript set filetype=javascriptreact | set iskeyword+=-
augroup end

let g:sh_fold_enabled = 4

com! FormatJSON exe '%!python -m json.tool'

function FormatEqual() abort
  let save_cursor = getcurpos()
  normal! gg=G
  silent! exe '%s#)\zs\ze{# #g'
  call setpos('.', save_cursor)
  echom 'Formatted with equalprg'
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
if executable('rg')
  let &grepprg="rg --vimgrep --no-heading --smart-case --hidden --follow -g '!{" . &wildignore . "}' $*"
  set grepformat=%f:%l:%c:%m,%f:%l:%m
elseif executable('ag')
  let &grepprg='ag --vimgrep --smart-case --hidden --follow --ignore "!{' . &wildignore . '}" $*'
  set grepformat=%f:%l:%c:%m
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

" Terminal configurations {{{
if exists(':terminal')

  " Terminal colors
  " let g:terminal_ansi_colors = [
  "     \'#1d1f21',
  "     \'#cc342b',
  "     \'#198844',
  "     \'#af8760',
  "     \'#3971ed',
  "     \'#a36ac7',
  "     \'#3971ed',
  "     \'#f5f5f5',
  "     \'#989698',
  "     \'#cc342b',
  "     \'#198844',
  "     \'#d8865f',
  "     \'#3971ed',
  "     \'#a36ac7',
  "     \'#3971ed',
  "     \'#ffffff'
  " \]

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

" }}}

" {{{ Visual Calculator
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
" }}}

" Last position on document {{{
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
" }}}

" YamlToJson JsonToYaml {{{
function! YamlToJson() abort
  % !python -c 'import yaml, json, sys; json.dumps(yaml.safe_load(sys.stdin));'
  set filetype=json
  FormatJSON
endfunction

function! JsonToYaml() abort
  % !python -c 'import yaml, json, sys; yaml.safe_dump(json.load(sys.stdin), sys.stdout, default_flow_style=False)'
  set filetype=yaml
endfunction

com! JsonToYaml call JsonToYaml()
com! YamlToJson call YamlToJson()
" }}}

" Decrypt encrypt ansible secret {{{
function DencryptAnsibleSecretFile(...) abort
  let action = 'decrypt'
  if get(a:, 1, v:false)
    let action = 'encrypt'
  endif

  silent! exe '!ansible-vault ' . action . ' --vault-password-file ~/ansible_secret %'
endfunction
com! EncryptAnsible call DencryptAnsibleSecretFile(1)
com! DecryptAnsible call DencryptAnsibleSecretFile()
" }}}
