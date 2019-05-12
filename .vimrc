" Moshe's vimrc. Custom made for my needs :)
" Function that checks if colorscheme exists

" Basic configurations {{{
silent! colorscheme dracula
set relativenumber
set cursorline     " Add highlight behind current line
set hlsearch       " highlight reg. ex. in @/ register
set incsearch      " Search as characters are typed
set ignorecase     " Search case insensitive...
set smartcase
set autoread       " Re-read file if it was changed from the outside
set scrolloff=7    " When about to scroll page, see 7 lines below cursor
set cmdheight=2    " Height of the command bar
set hidden         " Hide buffer if abandoned
set showmatch      " When closing a bracket (like {}), show the enclosing bracket for a brief second
set nostartofline  " Stop certain movements from always going to the first character of a line.
set confirm        " Prompt confirmation if exiting unsaved file
set lazyredraw     " redraw only when we need to.
set noswapfile
filetype plugin on
" }}}

" Indentation {{{
" Indentation settings for using 4 spaces instead of tabs.
" Do not change 'tabstop' from its default value of 8 with this setup.
filetype indent on
set autoindent
set smartindent
set shiftwidth=4
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

" Map enter to no highlight
nnoremap <CR> :nohlsearch<CR><CR>

" Move to the end of the line
nnoremap E $

" Map leader+sc to no highlight
" nnoremap <leader>sc :noh<cr>
" Map - to move a line down
nnoremap - dd$p
" Map - to move a line up
nnoremap _ dd2kp
" Map ctrl+u to toggle word to uppercase/lowercase in insert and normal
inoremap U <esc>viw~i
nnoremap U viw~
" Edit vimrc <leader>ev, source vimrc <leader>sv
nnoremap <leader>ev :vsplit ~/.vimrc<cr>
nnoremap <leader>sv :source ~/.vimrc<cr>



" Exit insert mode
"inoremap jk <esc>
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
" Movement p: Inside parentheses (delete parameters = dp)
onoremap p i(
" remap `*`/`#` to search forwards/backwards (resp.)
" w/o moving cursor
nnoremap <silent> * :execute "normal! *N"<cr>
nnoremap <silent> # :execute "normal! #n"<cr>

" search and replace
nnoremap <Leader>r :%s/\<<C-r><C-w>\>//g<Left><Left>

" move vertically by visual line (don't skip wrapped lines)
nnoremap j gj
nnoremap k gk

" Gundo undo
nnoremap <leader>u :GundoToggle<CR>
" }}}

" Surround {{{
nnoremap <leader>" viw<esc>a"<esc>bi"<esc>lel
nnoremap <leader>' viw<esc>a'<esc>bi'<esc>lel
nnoremap <leader>{ viw<esc>a }<esc>bi{ <esc>lel
nnoremap <leader>( viw<esc>a)<esc>bi(<esc>lel

vnoremap <leader>( iw<esc>a)<esc>bi(<esc>lel
vnoremap <leader>" iw<esc>a"<esc>bi"<esc>lel
vnoremap <leader>' iw<esc>a'<esc>bi'<esc>lel
vnoremap <leader>{ iw<esc>a }<esc>bi{ <esc>lel
" }}}

" Completion {{{
let g:ycm_autoclose_preview_window_after_completion=1
let g:ycm_key_list_stop_completion = [ '<C-y>', '<Enter>' ]
map <leader>g  :YcmCompleter GoToDefinitionElseDeclaration<CR>
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

" Syntax highlighting {{{
let python_highlight_all=1
syntax on

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_aggregate_errors = 1
let g:syntastic_enable_signs=1
let g:syntastic_error_symbol='✗'
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" let g:syntastic_python_checkers = ['flake8']
" let g:syntastic_yaml_checkers = ['yamllint']
" let g:syntastic_javascript_checkers = ['eslint']
" }}}

" Filetype vim {{{
augroup filetype_vim
    autocmd!
    autocmd! BufWritePost .vimrc* source %
    autocmd FileType vim |
      setlocal foldlevel=0 |
      setlocal foldmethod=marker

augroup END
" }}}

" Filetype HTML {{{
augroup filetype_yaml
    autocmd!
    autocmd BufNewFile,BufReadPost *.{yaml,yml} set filetype=yaml foldmethod=indent
    autocmd FileType yaml |
        setlocal shiftwidth=2 |
        setlocal softtabstop=2 |
        setlocal tabstop=2

augroup END
" }}}

" Minify and uglify {{{
" nnoremap <leader>mcss :%!uglifycss<cr>
" nnoremap <leader>ucss :%!uglifycss<cr>
" nnoremap <leader>bcss :%!prettier --stdin-filepath %<cr>
" }}}


" Buffers {{{
nnoremap ; :Buffers<CR>
nnoremap <Leader>t :Files<CR>
" close buffer
nnoremap <leader>w :bd<cr>
" }}}
