" Moshe's vimrc. Custom made for my needs :)
" Function that checks if colorscheme exists

" Basic configurations {{{
set nocompatible
" packadd! dracula
silent! colorscheme elflord
syntax enable

set shell=/bin/zsh
" set shellcmdflag=-ic

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
set guifont=:h

filetype plugin on
filetype plugin indent on

set list
set listchars=tab:>.,trail:.,extends:#,nbsp:.

set path+=** " When searching, search also subdirectories
" set verbose=1
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

" Remove blank spaces from the end of the line
:nnoremap <silent> <leader>a :let _s=@/ <Bar> :%s/\s\+$//e <Bar> :let @/=_s <Bar> :nohl <Bar> :unlet _s <CR>


" Map - to move a line down
nnoremap - dd$p

" Base64 decode
vnoremap <leader>64 y:echo system('base64 --decode', @")<cr>

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

" Change working directory based on open file
nnoremap <leader>cd :cd %:p:h<CR>:pwd<CR>

" Convert all tabs to spaces
nnoremap <leader>ct<space> :retab<cr>


"" }}}

" Split navigations mappings {{{
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
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
inoreabbrev def def () {<cr><tab><cr>}<esc>2k0f(a
inoreabbrev function function () {<cr><tab><cr>}<esc>2k0f(a
inoreabbrev if <bs>if () {<cr><tab><cr>}<esc>2k0f(a
inoreabbrev teh the
inoreabbrev seperate separate
inoreabbrev dont don't
" }}} 

" Auto-Parentheses {{{
" Auto-insert closing parenthesis/brace - autopairs plugin replaces this
" inoremap ( ()<Left>
" inoremap { {}<Left>
" 
" " Auto-delete closing parenthesis/brace
" function! BetterBackSpace() abort
"     let cur_line = getline('.')
"     let before_char = cur_line[col('.')-2]
"     let after_char = cur_line[col('.')-1]
"     if (before_char == '(' && after_char == ')') || (before_char == '{' && after_char == '}')
"         return "\<Del>\<BS>"
"     else
"         return "\<BS>"
" endfunction
" inoremap <silent> <BS> <C-r>=BetterBackSpace()<CR>
" 
" " Skip over closing parenthesis/brace
" inoremap <expr> ) getline('.')[col('.')-1] == ")" ? "\<Right>" : ")"
" inoremap <expr> } getline('.')[col('.')-1] == "}" ? "\<Right>" : "}"
" }}}

" Extras {{{
" Fzf
" nnoremap <c-p> :Files 
nnoremap <silent> <expr> <c-p> (expand('%') =~ 'NERD_tree' ? "\<c-w>\<c-w>" : '').":Files\<cr>"

nnoremap <c-b> :Buffers<cr>

" Nerd Tree
nnoremap <c-o> :NERDTreeToggle<cr>
let g:NERDTreeChDirMode = 2

" Ack
if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif
nnoremap <c-f> :Ack!<Space>

" DevIcons {{{
let g:WebDevIconsOS = 'Darwin'
let g:WebDevIconsUnicodeDecorateFolderNodes = 1
let g:DevIconsEnableFoldersOpenClose = 1
let g:DevIconsEnableFolderExtensionPatternMatching = 1
highlight! link NERDTreeFlags NERDTreeDir
" }}}

" Vim airline (powerline) {{{
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif
let g:airline_symbols.space = "\ua0"
let g:airline_theme='wombat'
" }}}

" Ctags
command! MakeTags !ctags -R . 2>/dev/null

" GitGutter {{{
nnoremap <leader>gc :GitGutterLineHighlightsToggle<cr>
nnoremap <leader>cag :GitGutterFold<cr>
function! GitStatus()
  let [a,m,r] = GitGutterGetHunkSummary()
  return printf('+%d ~%d -%d', a, m, r)
endfunction
set statusline+=%{GitStatus()}
highlight clear SignColumn
highlight GitGutterAdd ctermfg=green
highlight GitGutterChange ctermfg=yellow
highlight GitGutterDelete ctermfg=red
highlight GitGutterChangeDelete ctermfg=yellow
" }}}

" Fugitive {{{
" Better branch choosing using :Gbranch
function! s:changebranch(branch) 
    execute 'Git checkout' . a:branch
    call feedkeys("i")
endfunction

command! -bang Gbranch call fzf#run({
            \ 'source': 'git branch -a --no-color | grep -v "^\* " ', 
            \ 'sink': function('s:changebranch')
            \ })

" Set branch upstream
command! -bang Gpsup !git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)

" Set current working directory based on the file
" autocmd BufEnter * silent! :lcd%:p:h
" }}}
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

" Coc {{{

"" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current
" position. Coc only does snippet and additional edit on confirm.
" <cr> could be remapped by other vim plugin, try `:verbose imap <CR>`.
if exists('*complete_info')
  inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
else
  inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
endif

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder.
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of LS, ex: coc-tsserver
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocAction('format')

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" Add (Neo)Vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" Mappings for CoCList
" Show commands.
nnoremap <silent><nowait> <leader>cc  :<C-u>CocList commands<cr>
" Search workspace symbols.
nnoremap <silent><nowait> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>
" }}}

" Plugins {{{
call plug#begin('~/.vim/plugged')
Plug 'preservim/nerdtree'
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

Plug 'sheerun/vim-polyglot'

Plug 'terryma/vim-multiple-cursors'

Plug 'ryanoasis/vim-devicons'

Plug 'mileszs/ack.vim'

Plug 'jiangmiao/auto-pairs'

Plug 'neoclide/coc.nvim', {'branch': 'release'}

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'
Plug 'idanarye/vim-merginal'

call plug#end()
" }}}

