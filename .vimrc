" Moshe's vimrc. Custom made for my needs :)
" Function that checks if colorscheme exists

" Basic configurations {{{
set nocompatible
" packadd! dracula
silent! colorscheme elflord
syntax enable
set relativenumber
set linebreak      " Avoid wrapping a line in the middle of a word.
set cursorline     " Add highlight behind current line
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
filetype plugin on
filetype plugin indent on

set list
set listchars=tab:>.,trail:.,extends:#,nbsp:.

set path+=** " When searching, search also subdirectories

" }}}

" Indentation {{{
" Indentation settings for using 4 spaces instead of tabs.
" Do not change 'tabstop' from its default value of 8 with this setup.
filetype indent on
set autoindent    " always set autoindenting on
set copyindent    " copy the previous indentation on autoindenting
set smartindent   " Number of spaces to use for each step of (auto)indent.
set shiftwidth=4  " Number of spaces for each indent
set softtabstop=4
set tabstop=4
set expandtab
" }}}

" Statusline {{{
" set statusline=%.50F\ -\ FileType:\ %y
" set statusline+=%=        " Switch to the right side
" set statusline+=%l    " Current line
" set statusline+=/    " Separator
" set statusline+=%L\   " Total lines
" }}}

" Mappings {{{
" Map leader to space
let mapleader=" "
let maplocalleader = "\\"

" Map 0 to first non-blank character
nnoremap 0 ^

" with this you can save with ;wq
nnoremap ; :

" Switch between last buffers
nnoremap <Leader><Leader> <C-^>

" This creates a new line of '=' signs the same length of the line
nnoremap <leader>= yypVr=

" Map enter to no highlight
nnoremap <CR> :nohlsearch<CR><CR>

" Move to the end of the line
nnoremap E $
vnoremap E $

" Map - to move a line down
nnoremap - dd$p

" Map _ to move a line up
nnoremap _ dd2kp

" Map ctrl+u to toggle word to uppercase/lowercase in insert and normal and
" visual
nnoremap U viw~
vnoremap U ~

" Edit vimrc <leader>ev, source vimrc <leader>sv
nnoremap <leader>ev :vsplit ~/.vimrc<cr>
nnoremap <leader>sv :source ~/.vimrc<cr>

" Remove blank space from the start of the line to the end of previous line
inoremap ddd <esc>^hvk$xi 
nnoremap <leader>d ^hvk$xi <esc>

" highlight last inserted text
nnoremap gV `[v`]

" Exit insert mode
inoremap jk <esc>
"inoremap <esc> <nop>

" ==============================
" Copy to clipboard / yank
" Copy visual selection to clipboard
vnoremap <leader>y "*y
" Copy entire file to clipboard
nnoremap Y :%y+<cr>
" Copy line from cursor until the end
nnoremap <leader>ye vg_y
"===============================
" Movement p: Inside parentheses (delete parameters = dp | change text inside
" parentheses = cp)
onoremap p i(
" remap `*`/`#` to search forwards/backwards (resp.)
" w/o moving cursor
nnoremap <silent> * :execute "normal! *N"<cr>
nnoremap <silent> # :execute "normal! #n"<cr>

" search and replace
nnoremap <Leader>r :%s/<C-r><C-w>//gc<Left><Left><Left>
" vnoremap <Leader>r :%s/<C-r><C-w>//g<Left><Left>
vnoremap <leader>r "hy:%s/<C-r>h//gc<left><left><left>

" Change every " -" with " \<cr> -" to break long lines of bash
nnoremap <silent> <buffer> <leader>\ :.s/ -/ \\\r  -/g<cr>:noh<cr>

" move vertically by visual line (don't skip wrapped lines)
nnoremap j gj
nnoremap k gk

" }}}

" Split navigations mappings {{{
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
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
" }}}

" Filetype vim {{{
augroup filetype_vim
    autocmd!
    autocmd! BufWritePost .vimrc* source %
    autocmd FileType vim |
      setlocal foldlevel=0  foldmethod=marker foldmarker={{{,}}}

augroup END
" }}}

" Filetype yaml {{{
augroup filetype_yaml
    autocmd!
    autocmd BufNewFile,BufReadPost *.{yaml,yml} set filetype=yaml foldmethod=indent
    autocmd FileType yaml |
        setlocal shiftwidth=2 |
        setlocal softtabstop=2 |
        setlocal tabstop=2
augroup END
" }}}

" Filetype bash {{{
augroup filetype_bash
    autocmd!
    autocmd BufNewFile,BufReadPost *.sh set filetype=sh foldmethod=indent
augroup END
" }}}

" Filetype groovy {{{
augroup filetype_groovy
    autocmd!
    au BufNewFile,BufRead *.groovy  setf groovy
    au BufNewFile,BufRead Jenkinsfile setf groovy

    au BufNewFile,BufRead *.groovy  setlocal filetype=groovy
    au BufNewFile,BufRead Jenkinsfile setlocal filetype=groovy
    " autocmd FileType groovy |
    "   setlocal foldmethod=marker foldmarker={,} |
    "   setlocal fillchars=fold:\  foldtext=getline(v:foldstart)

    autocmd FileType groovy |
      setlocal foldmethod=syntax
augroup END

if did_filetype()
  finish
endif
if getline(1) =~ '^#!.*[/\\]groovy\>'
  setf groovy
endif

" }}}

" Abbreviations {{{
inoreabbrev def def () {<cr><tab><cr>}<esc>2k0f(a
inoreabbrev function function () {<cr><tab><cr>}<esc>2k0f(a
inoreabbrev if <bs>if () {<cr><tab><cr>}<esc>2k0f(a
inoreabbrev teh the
inoreabbrev seperate separate
inoreabbrev dont don't
" }}} 

" Auto-Parentheses {{{
" Auto-insert closing parenthesis/brace
inoremap ( ()<Left>
inoremap { {}<Left>

" Auto-delete closing parenthesis/brace
function! BetterBackSpace() abort
    let cur_line = getline('.')
    let before_char = cur_line[col('.')-2]
    let after_char = cur_line[col('.')-1]
    if (before_char == '(' && after_char == ')') || (before_char == '{' && after_char == '}')
        return "\<Del>\<BS>"
    else
        return "\<BS>"
endfunction
inoremap <silent> <BS> <C-r>=BetterBackSpace()<CR>

" Skip over closing parenthesis/brace
inoremap <expr> ) getline('.')[col('.')-1] == ")" ? "\<Right>" : ")"
inoremap <expr> } getline('.')[col('.')-1] == "}" ? "\<Right>" : "}"
" }}}

" Extras {{{
set runtimepath^=~/.vim/bundle/ctrlp.vim

" Ctags
command! MakeTags !ctags -R . 2>/dev/null
" }}}

" Surround {{{
nnoremap <leader>" viw<esc>a"<esc>bi"<esc>lel
nnoremap <leader>' viw<esc>a'<esc>bi'<esc>lel
nnoremap <leader>{ viw<esc>a }<esc>bi{ <esc>lel
nnoremap <leader>( viw<esc>a)<esc>bi(<esc>lel

vnoremap <leader>( c()<esc>P
vnoremap <leader>{ c{}<esc>P
vnoremap <leader>" c""<esc>P
vnoremap <leader>' c''<esc>P

" }}}
