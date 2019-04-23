" Moshe's vimrc. Custom made for my needs :)
" Function that checks if colorscheme exists

" Basic configurations {{{
silent! colorscheme dracula
" colorscheme dracula
set relativenumber
set cursorline
set hlsearch " highlight reg. ex. in @/ register
set ignorecase                  " Search case insensitive...
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
" Map leader+sc to no highlight
nnoremap <leader>sc :noh<cr>
" Map - to move a line down
nnoremap - dd$p
" Map - to move a line up
nnoremap _ dd2kp
" Map ctrl+x to delete a line in insert and normal mode
inoremap <c-x> <esc>ddi
nnoremap <c-x> dd
" Map ctrl+u to toggle word to uppercase/lowercase in insert and normal
inoremap <c-u> <esc>viw~i
nnoremap U viw~
" Edit vimrc <leader>ev, source vimrc <leader>sv
nnoremap <leader>ev :vsplit ~/.vimrc<cr>
nnoremap <leader>sv :source ~/.vimrc<cr>
" Exit insert mode
"inoremap jk <esc>
"inoremap <esc> <nop>
" Copy to clipboard
vnoremap <leader>y "*y
nnoremap <leader>ya :%y+<cr>
" Movement p: Inside parentheses (delete parameters = dp)
onoremap p i(
" remap `*`/`#` to search forwards/backwards (resp.)
" w/o moving cursor
nnoremap <silent> * :execute "normal! *N"<cr>
nnoremap <silent> # :execute "normal! #n"<cr>

" search and replace
nnoremap <Leader>r :%s/\<<C-r><C-w>\>//g<Left><Left>
" }}}

" Surround {{{
"nnoremap <leader>" viw<esc>a"<esc>bi"<esc>lel
"nnoremap <leader>' viw<esc>a'<esc>bi'<esc>lel
"nnoremap <leader>{ viw<esc>a }<esc>bi{ <esc>lel
"nnoremap <leader>( viw<esc>a)<esc>bi(<esc>lel
"
"vnoremap <leader>( iw<esc>a)<esc>bi(<esc>lel
" }}}

" Completion {{{
let g:ycm_autoclose_preview_window_after_completion=1
let g:ycm_key_list_stop_completion = [ '<C-y>', '<Enter>' ]
map <leader>g  :YcmCompleter GoToDefinitionElseDeclaration<CR>
" }}}

" Commenter {{{
noremap <leader>, :NERDCommenterToggle
" }}}

" Split navigations mappings {{{
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
" }}}

" Enable folding {{{
set foldmethod=indent
set foldlevel=99
" Enable folding with the leader-f/a
nnoremap <leader>f za
nnoremap <leader>caf zM
nnoremap <leader>oaf zR
let g:SimpylFold_docstring_preview = 1
" }}}

" Vimscript file settings {{{
augroup filetype_vim
    autocmd!
    autocmd FileType vim setlocal foldmethod=marker
augroup END
" }}}

" Syntax highlighting {{{
let python_highlight_all=1
syntax on

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

let g:syntastic_python_checkers = ['flake8']
let g:syntastic_yaml_checkers = ['yamllint']
let g:syntastic_javascript_checkers = ['eslint']
" }}}

" test autocmd {{{
augroup filetype_html
    autocmd!
    autocmd FileType html nnoremap <buffer> <localleader>f Vatzf
augroup END
" }}}
