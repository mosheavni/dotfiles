" =========================================================
colorscheme dracula
set relativenumber
set cursorline
" Map leader to space
let mapleader=" "
" Map leader+sc to no highlight
nnoremap <leader>sc :noh<cr>
" Map - to move a line down
nnoremap - dd$p
" Map - to move a line up
nnoremap _ dd2kp
" Map ctrl+x to delete a line in insert mode
inoremap <c-x> <esc>ddi
" Map ctrl+u to toggle word to uppercase/lowercase in insert and normal
inoremap <c-u> <esc>viw~i
nnoremap <c-u> viw~
" Edit vimrc <leader>ev, source vimrc <leader>sv
nnoremap <leader>ev :vsplit ~/.vimrc<cr>
nnoremap <leader>sv :source ~/.vimrc<cr>
" Exit insert mode
"inoremap jk <esc>
"inoremap <esc> <nop>
" Copy to clipboard
vnoremap <leader>y "*y

" ================= Surround =================
nnoremap <leader>" viw<esc>a"<esc>bi"<esc>lel
nnoremap <leader>' viw<esc>a'<esc>bi'<esc>lel
nnoremap <leader>{ viw<esc>a }<esc>bi{ <esc>lel
nnoremap <leader>( viw<esc>a)<esc>bi(<esc>lel

" Completion
let g:ycm_autoclose_preview_window_after_completion=1
map <leader>g  :YcmCompleter GoToDefinitionElseDeclaration<CR>

" Commenter
noremap <leader>, :NERDCommenterToggle

" highlight reg. ex. in @/ register
set hlsearch
" remap `*`/`#` to search forwards/backwards (resp.)
" w/o moving cursor
nnoremap <silent> * :execute "normal! *N"<cr>
nnoremap <silent> # :execute "normal! #n"<cr>

"split navigations
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
set ignorecase                  " Search case insensitive...

" Enable folding
set foldmethod=indent
set foldlevel=99
" Enable folding with the leader-f/a
nnoremap <leader>f za
" nnoremap <leader><SPC> za
nnoremap <leader>a zM
" let g:SimpylFold_docstring_preview = 1

" Indentation
au BufNewFile,BufRead *.py
    \ set tabstop=4
    \| set softtabstop=4
    \| set shiftwidth=4
    \| set textwidth=79
    \| set expandtab
    \| set autoindent
    \| set fileformat=unix

au BufNewFile,BufRead *.js,*.html,*.css
    \ set tabstop=2
    \| set softtabstop=2
    \| set shiftwidth=2

" Syntax highlighting
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


