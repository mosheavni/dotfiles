" Moshe's vimrc. Custom made for my needs :)

" .    .         .              .
" |\  /|         |             / \               o
" | \/ | .-. .--.|--. .-.     /___\.    ._.--.   .
" |    |(   )`--.|  |(.-'    /     \\  /  |  |   |
" '    ' `-' `--''  `-`--'  '       ``'   '  `--' `-

" Basic configurations {{{
set nocompatible
syntax enable

set shell=/bin/zsh
" set tags=./tags,tags;$HOME

" set shellcmdflag=-ic

set number         " Show current line number
set relativenumber
set linebreak      " Avoid wrapping a line in the middle of a word.
set cursorcolumn
set cursorline     " Add highlight behind current line
" hi cursorline cterm=none term=none
" highlight CursorLine guibg=#303000 ctermbg=234
set hlsearch       " highlight reg. ex. in @/ register
set incsearch      " Search as characters are typed
set ignorecase     " Search case insensitive...
set smartcase      " ignore case if search pattern is all lowercase, case-sensitive otherwise
set autoread       " Re-read file if it was changed from the outside
set scrolloff=7    " When about to scroll page, see 7 lines below cursor
set cmdheight=2    " Height of the command bar
set hidden         " Hide buffer if abandoned
set showmatch      " When closing a bracket (like {}), show the enclosing bracket for a brief second
set nostartofline  " Stop certain movements from always going to the first character of a line.
set confirm        " Prompt confirmation if exiting unsaved file
set lazyredraw     " redraw only when we need to.
set noswapfile
set nobackup
set wildmenu       " Displays a menu on autocomplete
set title          " Changes the iterm title
set showcmd
set guifont=:h
set mouse=a
set termguicolors
set undofile       " Enables saving undo history to a file

" Ignore node_modules
set wildignore+=**/node_modules/**

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

filetype plugin on
filetype plugin indent on

set list
set listchars=tab:▸\ ,trail:·

set path+=** " When searching, search also subdirectories

" Set python path
let g:python3_host_prog="/usr/local/bin/python3"

" Auto load file changes when focus or buffer is entered
au FocusGained,BufEnter * :checktime

" Set relativenumber when focused {{{
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave * set number relativenumber
  autocmd BufLeave,FocusLost,InsertEnter   * set number norelativenumber
augroup END
" }}}
" set verbose=1
" }}}

" Indentation {{{
" Indentation settings for using 4 spaces instead of tabs.
" Do not change 'tabstop' from its default value of 8 with this setup.
filetype indent on
set breakindent   " Maintain indent on wrapping lines
set autoindent    " always set autoindenting on
set copyindent    " copy the previous indentation on autoindenting
set smartindent   " Number of spaces to use for each step of (auto)indent.
set shiftwidth=4  " Number of spaces for each indent
set smarttab      " insert tabs on the start of a line according to shiftwidth, not tabstop
set softtabstop=4
set tabstop=4
set expandtab
" }}}

" Statusline {{{
set statusline=%.50F\ -\ FileType:\ %y
set statusline+=%=        " Switch to the right side
set statusline+=%l    " Current line
set statusline+=/    " Separator
set statusline+=%L\   " Total lines
" }}}

" Mappings {{{
" Map leader to space
let mapleader=" "
let maplocalleader = "\\"

" Toggle number sets
nnoremap <leader>num :set number! \| set relativenumber!<cr>

" Map 0 to first non-blank character
nnoremap 0 ^

" with this you can save with ;wq
" nnoremap ; :

" Switch between last buffers
nnoremap <Leader><Leader> <C-^>

" Close current buffer
nnoremap <silent> <leader>bd :bp <bar> bd #<cr>

" This creates a new line of '=' signs the same length of the line
nnoremap <leader>= yypVr=

" Resize split
nnoremap <silent> <Leader>+ :exe "resize " . (winheight(0) * 3/2)<CR>
nnoremap <silent> <Leader>- :exe "resize " . (winheight(0) * 2/3)<CR>

" Map dp and dg with leader for diffput and diffget
nnoremap <leader>dp :diffput<cr>
nnoremap <leader>dg :diffget<cr>

" Map enter to no highlight
nnoremap <CR> :nohlsearch<CR><CR>

" Move to the end of the line
nnoremap E $
vnoremap E $

" Remove blank spaces from the end of the line
nnoremap <silent> <leader>a :let _s=@/ <Bar> :%s/\s\+$//e <Bar> :let @/=_s <Bar> :nohl <Bar> :unlet _s <CR>

" Set mouse=v mapping
nnoremap <leader>ma :set mouse=a<cr>
nnoremap <leader>mv :set mouse=v<cr>

" Don't lose seletion when indenting
xnoremap <  <gv
xnoremap >  >gv

" Map n to search forward and N to search badkward {{{
nnoremap <expr> n  'Nn'[v:searchforward]
xnoremap <expr> n  'Nn'[v:searchforward]
onoremap <expr> n  'Nn'[v:searchforward]

nnoremap <expr> N  'nN'[v:searchforward]
xnoremap <expr> N  'nN'[v:searchforward]
onoremap <expr> N  'nN'[v:searchforward]

" Search visually selected text with // or * or #
vnoremap // y/\V<C-R>=escape(@",'/\')<CR><CR>

vnoremap <silent> * :<C-U>
  \let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
  \gvy/<C-R>=&ic?'\c':'\C'<CR><C-R><C-R>=substitute(
  \escape(@", '/\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
  \gVzv:call setreg('"', old_reg, old_regtype)<CR>
vnoremap <silent> # :<C-U>
  \let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
  \gvy?<C-R>=&ic?'\c':'\C'<CR><C-R><C-R>=substitute(
  \escape(@", '?\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
  \gVzv:call setreg('"', old_reg, old_regtype)<CR>

" }}}

" Map - to move a line down and _ a line up
nnoremap -  :<c-u>execute 'move +'. v:count1<cr>
nnoremap _  :<c-u>execute 'move -1-'. v:count1<cr>
" nnoremap - dd$p
" nnoremap _ dd2kp

" Base64 decode
vnoremap <leader>64 y:echo system('base64 --decode', @")<cr>

" Map ctrl+u to toggle word to uppercase/lowercase in insert and normal and
" visual
nnoremap U viw~
vnoremap U ~

" Edit vimrc <leader>ev, source vimrc <leader>sv , reload on save {{{
let g:myvimrc = "~/.vimrc"
let g:myvimrcplugins = "~/.vimrcplugins"

nnoremap <silent> <leader>ev :execute("vsplit ".g:myvimrc)<cr>
nnoremap <silent> <leader>sv :execute("source ".g:myvimrc)<cr>
exe("autocmd BufWritePost ".g:myvimrc." source ".g:myvimrc)

function! LoadPlugins() abort
    execute("so ".g:myvimrcplugins)
    PlugInstall
    echom "Ran PlugInstall"
    execute("windo so ".g:myvimrcplugins)
    echom "Sourced ".g:myvimrcplugins." on all windows"
endfunction

nnoremap <silent> <leader>ep :execute("vsplit ".g:myvimrcplugins)<cr>
nnoremap <silent> <leader>sp :call LoadPlugins()<cr>
" }}}

" Remove blank space from the start of the line to the end of previous line
inoremap ddd <esc>^hvk$xi
nnoremap <leader>d ^hvk$xi <esc>

" highlight last inserted text
nnoremap gV `[v`]

" terminal mappings
tnoremap <Esc> <C-\><C-n>
nnoremap <leader>term :new term://zsh<cr>

" Exit insert mode
inoremap jk <esc>
nnoremap <leader>qq :qall<cr>
"inoremap <esc> <nop>


" " Copy to clipboard / yank - this is replaced by christoomey/vim-system-copy {{{
" " Copy visual selection to clipboard
" vnoremap <leader>y "*y
" " Copy entire file to clipboard
nnoremap Y :%y+<cr>
" " Copy line from cursor until the end
" nnoremap <leader>ye vg_y
"=============================== }}}

" Movement p: Inside parentheses (delete parameters = dp | change text inside
" parentheses = cp)
onoremap p i(

" remap `*`/`#` to search forwards/backwards (resp.) {{{
" w/o moving cursor
nnoremap <silent> * :execute "normal! *N"<cr>
nnoremap <silent> # :execute "normal! #n"<cr>
" }}}

" Search and Replace {{{
nnoremap <Leader>r :%s/<C-r><C-w>/<C-r><C-w>/gc<Left><Left><Left>
" vnoremap <Leader>r :%s/<C-r><C-w>//g<Left><Left>
vnoremap <leader>r "hy:%s/<C-r>h/<C-r>h/gc<left><left><left>
" }}}

" Change every " -" with " \<cr> -" to break long lines of bash
nnoremap <silent> <leader>\ :.s/ -/ \\\r  -/g<cr>:noh<cr>

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
let g:netrw_liststyle = 4
let g:netrw_browse_split = 4
" let g:netrw_altv = 1
let g:netrw_winsize = 25
let g:netrw_keepdir = 0
" augroup ProjectDrawer
"   autocmd!
"   autocmd VimEnter * :if !exists("NERDTree") | Vexplore | endif
" augroup END

" Toggle Vexplore with Ctrl-E {{{
function! ToggleVExplorer()
  if exists("t:expl_buf_num")
      let expl_win_num = bufwinnr(t:expl_buf_num)
      if expl_win_num != -1
          let cur_win_nr = winnr()
          exec expl_win_num . 'wincmd w'
          close
          exec cur_win_nr . 'wincmd w'
          unlet t:expl_buf_num
      else
          unlet t:expl_buf_num
      endif
  else
      exec '1wincmd w'
      Vexplore
      let t:expl_buf_num = bufnr("%")
  endif
endfunction
" }}}
map <silent> <C-E> :call ToggleVExplorer()<CR>
" }}}

" Split navigations mappings {{{
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
set splitbelow
set splitright
" }}}

" Enable folding {{{
set foldenable
setlocal foldmethod=syntax
set foldlevel=999
set foldlevelstart=10
" Enable folding with the leader-f/a
nnoremap <leader>f za
nnoremap <leader>caf zM
nnoremap <leader>oaf zR
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
nnoremap <leader>" viw<esc>a"<esc>bi"<esc>lel
nnoremap <leader>' viw<esc>a'<esc>bi'<esc>lel
nnoremap <leader>{ viw<esc>a }<esc>bi{ <esc>lel
nnoremap <leader>( viw<esc>a)<esc>bi(<esc>lel
nnoremap <leader>[ viw<esc>a]<esc>bi[<esc>lel

vnoremap <leader>( c()<esc>P
vnoremap <leader>[ c[]<esc>P
vnoremap <leader>{ c{}<esc>P
vnoremap <leader>" c""<esc>P
vnoremap <leader>' c''<esc>P
" }}}

" Conceals {{{

let g:conceal_rules = [
      \ ['!=', '≠'],
      \ ['<=', '≤'],
      \ ['>=', '≥'],
      \ ['=>', '⇒'],
      \ ['===', '≡'],
      \ ['\<function\>', 'ƒ'],
      \ ]

for [value, display] in g:conceal_rules
  execute "call matchadd('Conceal', '".value."', 10, -1, {'conceal': '".display."'})"
endfor

" call matchadd('Conceal', 'package', 10, 99, {'conceal': 'p'})
"}}}
