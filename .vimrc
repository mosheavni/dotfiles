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
" Map ctrl+u to toggle word to uppercase/lowercase in insert and normal and
" visual
nnoremap U viw~
vnoremap U ~
" Edit vimrc <leader>ev, source vimrc <leader>sv
nnoremap <leader>ev :vsplit ~/.vimrc<cr>
nnoremap <leader>sv :source ~/.vimrc<cr>

" Remove blank space from the start of the line to the end of previous line
inoremap ddd <esc>^hvk$xi 


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
nnoremap <Leader>r :%s/<C-r><C-w>//g<Left><Left>
" vnoremap <Leader>r :%s/<C-r><C-w>//g<Left><Left>
vnoremap <leader>r "hy:%s/<C-r>h//gc<left><left><left>


" move vertically by visual line (don't skip wrapped lines)
nnoremap j gj
nnoremap k gk

" Disable syntastic
nnoremap <leader>s :SyntasticToggleMode<cr>


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
set foldlevel=999
set foldlevelstart=999
" Enable folding with the leader-f/a
nnoremap <leader>f za
nnoremap <leader>caf zM
nnoremap <leader>oaf zR
" }}}

" Filetype python {{{
"augroup python
"    autocmd!
"    autocmd BufNewFile,BufReadPost *.{py,pyc} set filetype=python foldmethod=indent
"    autocmd FileType python |
"        setlocal smartindent |
"        setlocal cinwords=if,elif,else,for,while,with,try,except,finally,def,class |
"        setlocal foldmethod=indent |
"        setlocal autoindent |
"        setlocal backspace=indent,eol,start |
"        setlocal encoding=utf-8 |
"        setlocal expandtab |
"        setlocal fileformat=unix |
"        setlocal shiftwidth=4 |
"        setlocal softtabstop=4 |
"        setlocal tabstop=4
"augroup END
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

" Abbreviations {{{
inoreabbrev bashh #!/bin/bash<cr>
inoreabbrev pythh #!/usr/bin/env python<cr>
" }}}

" Buffers {{{
nnoremap ; :Buffers<CR>
nnoremap <Leader>t :Files<CR>
" close buffer
nnoremap <leader>w :bd<cr>
" }}}
