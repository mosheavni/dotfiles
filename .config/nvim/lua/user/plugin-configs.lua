vim.cmd [[
" Color settings {{{
" Random color {{{
function! RandomColorChooser() abort
  let l:liked_colors =  [
        \ 'OceanicNext',
        \ 'apprentice',
        \ 'deep-space',
        \ 'dracula',
        \ 'onedark',
        \ 'onehalfdark',
        \ 'purify',
        \ 'quantum',
        \ 'sonokai',
        \ 'two-firewatch'
        \ ]
  let l:random_color = l:liked_colors[localtime() % len(l:liked_colors)]
  exe 'colorscheme '. l:random_color
endfunction
" call RandomColorChooser()
" }}}

colorscheme gruvbox

" }}}

" Telescope {{{
" nnoremap <c-p> :Files
nnoremap <silent> <expr> <c-p> (expand('%') =~ 'NERD_tree' ? "\<c-w>\<c-w>" : '').":Telescope find_files\<cr>"
" let $FZF_DEFAULT_COMMAND = "rg --files --hidden -g '!.git/' --color=never"
" let $FZF_DEFAULT_COMMAND = 'ag --hidden --ignore .git -l -g ""'
" let $FZF_DEFAULT_OPTS    = '--bind ctrl-a:select-all'
" nnoremap <c-t> :Tags<cr>
nnoremap <c-b> :Telescope buffers<cr>
nnoremap <F4>  :Telescope git_branches<cr>
" nnoremap <silent><expr> <c-f> '<cmd>Telescope live_grep default_text=' . expand('<cword>') . '<cr>'
" nnoremap <c-y> :History<cr>
" }}}

" Ultisnip {{{
let g:UltiSnipsExpandTrigger='<c-s>'
" }}}

" Vim json path {{{
let g:jsonpath_register = '*'
" }}}

" WinResizer {{{
let g:winresizer_start_key = '<C-E>'
" }}}

" Floaterm {{{
let g:floaterm_keymap_toggle = '<F6>'
let g:floaterm_keymap_new    = '<F7>'
let g:floaterm_keymap_next   = '<F8>'
let g:floaterm_width = 0.7
let g:floaterm_height = 0.9

" }}}

" Yaml Revealer {{{
let g:yaml_revealer_separator = '.'
let g:yaml_revealer_list_indicator = 1
" }}}

" DirDiff {{{
" let g:DirDiffEnableMappings = 1
" let g:DirDiffNextKeyMap = ']q'
" let g:DirDiffPrevKeyMap = '[q'

" }}}

" Switch vim {{{
" let g:switch_mapping = '-'
" The map switch is between underscores to camelCase: moshe_king -> mosheKing
" -> moshe_king
let g:switch_custom_definitions = [
      \   ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'],
      \   ['yes', 'no'],
      \   ['enable', 'disable'],
      \   ['==', '!='],
      \   {
      \     '\<[a-z0-9]\+_\k\+\>': {
      \       '_\(.\)': '\U\1'
      \     },
      \     '\<[a-z0-9]\+[A-Z]\k\+\>': {
      \       '\([A-Z]\)': '_\l\1'
      \     },
      \   }
      \ ]
" }}}

" Vim ansible {{{
let g:ansible_goto_role_paths = '.;,roles;'

function! FindAnsibleRoleUnderCursor()
  let l:role_paths = get(g:, 'ansible_goto_role_paths', './roles')
  let l:tasks_main = expand('<cfile>') . '/tasks/main.yml'
  let l:found_role_path = findfile(l:tasks_main, l:role_paths)
  if l:found_role_path == ''
    echo l:tasks_main . ' not found'
  else
    execute 'edit ' . fnameescape(l:found_role_path)
  endif
endfunction
augroup AnsibleFind
  autocmd!

  au BufRead,BufNewFile */ansible/*.yml nnoremap <silent> <leader>gr :call FindAnsibleRoleUnderCursor()<CR>
  au BufRead,BufNewFile */ansible/*.yml vnoremap <silent> <leader>gr :call FindAnsibleRoleUnderCursor()<CR>
augroup END
" }}}

" Editor config {{{
let g:EditorConfig_exclude_patterns = ['fugitive://.*']
" }}}

" Vim terraform {{{
let g:terraform_fmt_on_save=1
" }}}

" Vim easy align {{{
nmap ga <Plug>(EasyAlign)
" }}}

" Vim close tag {{{
let g:closetag_filenames = '*.html,*.xhtml,*.phtml,*.erb,*.jsx,*.tsx,*.js'
let g:closetag_filetypes = 'html,xhtml,phtml,javascript,javascriptreact'
" }}}

" Startify {{{

let g:startify_custom_header = [
      \'   😎               🎃              😎',
      \'    _   _         __     ___',
      \'   | \ | | ___  __\ \   / (_)_ __ ___',
      \'   |  \| |/ _ \/ _ \ \ / /| | ''_ ` _ \',
      \'   | |\  |  __/ (_) \ V / | | | | | | |',
      \'   |_| \_|\___|\___/ \_/  |_|_| |_| |_|',
      \'', '   🚀               ✨              🚀'
      \]

" }}}

" DevIcons {{{
let g:WebDevIconsOS = 'Darwin'
let g:DevIconsEnableFoldersOpenClose = 1
let g:DevIconsEnableFolderExtensionPatternMatching = 1
" }}}

" Nvim blame line {{{
" TODO: fix diff
let g:nvimblame_disabled_buftypes = [
      \'qf',
      \'fugitive',
      \'nerdtree',
      \'gundo',
      \'diff',
      \'floaterm',
      \'vim-plug'
\]

function EnableBlameLineWrapper() abort
  if index(get(g:, 'nvimblame_disabled_buftypes', []), &buftype) == -1 && !&diff
    EnableBlameLine
  else
    DisableBlameLine
  endif
endfunction

augroup NvimBlameLine
  au!
  autocmd BufEnter,DiffUpdated * call EnableBlameLineWrapper()
augroup END
" }}}

" BarBar Nvim {{{
nnoremap <silent> <leader>bd :BufferClose<CR>
nnoremap <silent> <leader>abc :BufferCloseAllButCurrent<cr>:only<cr>
" Goto buffer in position...
nnoremap <silent>    <leader>1 :BufferGoto 1<CR>
nnoremap <silent>    <leader>2 :BufferGoto 2<CR>
nnoremap <silent>    <leader>3 :BufferGoto 3<CR>
nnoremap <silent>    <leader>4 :BufferGoto 4<CR>
nnoremap <silent>    <leader>5 :BufferGoto 5<CR>
nnoremap <silent>    <leader>6 :BufferGoto 6<CR>
nnoremap <silent>    <leader>7 :BufferGoto 7<CR>
nnoremap <silent>    <leader>8 :BufferGoto 8<CR>
" }}}

" Coc {{{

" Plugins backup {{{
let g:coc_global_extensions = [
      \    'coc-css',
      \    'coc-diagnostic',
      \    'coc-dictionary',
      \    'coc-docker',
      \    'coc-emmet',
      \    'coc-emoji',
      \    'coc-eslint',
      \    'coc-gitignore',
      \    'coc-groovy',
      \    'coc-highlight',
      \    'coc-html',
      \    'coc-html-css-support',
      \    'coc-json',
      \    'coc-markdownlint',
      \    'coc-marketplace',
      \    'coc-neosnippet',
      \    'coc-pairs',
      \    'coc-prettier',
      \    'coc-pyright',
      \    'coc-react-refactor',
      \    'coc-scssmodules',
      \    'coc-sh',
      \    'coc-snippets',
      \    'coc-styled-components',
      \    'coc-sumneko-lua',
      \    'coc-swagger',
      \    'coc-syntax',
      \    'coc-tabnine',
      \    'coc-tag',
      \    'coc-tsserver',
      \    'coc-vimlsp',
      \    'coc-xml',
      \    'coc-yaml'
      \]
" }}}

" Configurations
let g:coc_disable_transparent_cursor = 1

" use <tab> for trigger completion and navigate to the next complete item
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Mappings {{{
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

" Use <c-space> to trigger completion.
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current
" position. Coc only does snippet and additional edit on confirm.
" <cr> could be remapped by other vim plugin, try `:verbose imap <CR>`.
if exists('*complete_info')
  inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
else
  inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
endif

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
" nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of LS, ex: coc-tsserver
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)

nmap <silent><expr> <leader>p CocHasProvider('format') ? "\<Plug>(coc-format)" : ":call FormatEqual()\<cr>"
" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Project replace word
nnoremap <leader>prn :CocSearch <C-R>=expand("<cword>")<CR><CR>
vnoremap <leader>prn "iy:<c-u>CocSearch <C-R>i<CR><CR>
" Mappings for CoCList
" Show commands.
nnoremap <silent><nowait> <leader>cc  :<C-u>CocList commands<cr>
nnoremap <silent><nowait> <leader>a   <Plug>(coc-codeaction)
" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)
" Search workspace symbols.
" nnoremap <silent><nowait> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>

" Run the Code Lens action on the current line.
nmap <leader>cl  <Plug>(coc-codelens-action)
" }}}

hi CocHighlightText ctermbg=241 guibg=#665c54
hi! link CocHoverRange CocHighlightText

augroup format_coc_group
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder.
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
  " Highlight the symbol and its references when holding the cursor.
  autocmd CursorHold * silent call CocActionAsync('highlight')
augroup end

function! s:show_documentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocActionAsync('format')

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocActionAsync('runCommand', 'editor.action.organizeImport')
" }}}

" Nerd Tree {{{

let g:NERDTreeChDirMode = 2
let g:NERDTreeHijackNetrw = 1
let g:NERDTreeShowHidden=1
let g:NERDTreeHighlightCursorline = 1
let g:NERDTreeFileExtensionHighlightFullName = 1

" " ### nerdtree-git-plugin ###
let g:NERDTreeGitStatusUseNerdFonts = 1
" let g:NERDTreeGitStatusConcealBrackets = 1

let g:NERDTreeGitStatusIndicatorMapCustom = {
    \ 'Modified'  : '✹',
    \ 'Staged'    : '✚',
    \ 'Untracked' : '✭',
    \ 'Unmerged'  : '═',
    \ 'Dirty'     : '✗',
    \ 'Renamed'   : '➜',
    \ 'Clean'     : '✔︎',
    \ 'Ignored'   : '☒',
    \ 'Deleted'   : '✖',
    \ 'Unknown'   : '?'
    \ }
" " Set icon for Jenkinsfile
" let g:WebDevIconsUnicodeDecorateFileNodesPatternSymbols = {}
" let g:WebDevIconsUnicodeDecorateFileNodesPatternSymbols['Jenkinsfile'] = ''
" let g:WebDevIconsUnicodeDecorateFileNodesPatternSymbols['\..*ignore.*'] = ''

" let g:NERDTreePatternMatchHighlightColor = {}
" let g:NERDTreePatternMatchHighlightColor['\..*ignore.*'] = 'EE6E73'
" let g:NERDTreePatternMatchHighlightColor['Jenkinsfile'] = '62a2bf'

" If more than one window and previous buffer was NERDTree, go back to it.
" autocmd BufEnter * if bufname('#') =~# "^NERD_tree_" && winnr("$") > 1 | b# | endif


" Check if NERDTree is open or active
function! IsNERDTreeOpen()
  return exists('t:NERDTreeBufName') && (bufwinnr(t:NERDTreeBufName) != -1)
endfunction

" Call NERDTreeFind iff NERDTree is active, current window contains a modifiable
" file, and we're not in vimdiff
function! SyncTree()
  if &modifiable && IsNERDTreeOpen() && strlen(expand('%')) > 0 && !&diff
    NERDTreeFind
    wincmd p
  endif
endfunction

function! ToggleNerdTree()
  set eventignore=BufEnter
  NERDTreeToggle
  set eventignore=
endfunction

augroup nerd_tree_augroup
  autocmd!
  " Highlight currently open buffer in NERDTree
  autocmd BufEnter * call SyncTree()
  " Close VIM if NERDTree is the only buffer left
  autocmd BufEnter * if (winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree()) | q | endif
augroup END

nmap <silent> <C-o> :call ToggleNerdTree()<CR>
nmap <silent> <expr> <Leader>v ':'.(IsNERDTreeOpen() ? '' : 'call ToggleNerdTree()<bar>wincmd p<bar>').'NERDTreeFind<CR>'

" }}}

" Fugitive {{{

" Remove all conflict markers command
"Delete all Git conflict markers
"Creates the command :GremoveConflictMarkers
function! RemoveConflictMarkers() range
  echom a:firstline.'-'.a:lastline
  execute a:firstline.','.a:lastline . ' g/^<\{7}\|^|\{7}\|^=\{7}\|^>\{7}/d'
endfunction
"-range=% default is whole file
command! -range=% GremoveConflictMarkers <line1>,<line2>call RemoveConflictMarkers()


" Better branch choosing using :Gbranch
function! s:changebranch(...)
  let name = a:1
  if name ==? ''
    call inputsave()
    let name = input('Enter branch name: ')
    call inputrestore()
  endif
  execute 'Git checkout ' . name
endfunction

command! -nargs=? Gco call s:changebranch("<args>")

" Git push + pull + autocmd {{{

" Push
function! s:MosheGitPush() abort
  echo 'Pushing to ' . FugitiveHead() . '...'
  exe 'Git push -u origin ' . FugitiveHead()
  let l:exit_status = get(FugitiveResult(), 'exit_status', 1)
  if l:exit_status != 0
    echo 'Failed pushing 😒'
  else
    echo 'Pushed! 🤩'
  endif
endfunction
command! Gp call <sid>MosheGitPush()
nmap <silent> <leader>gp :Gp<cr>

" Pull
function! s:MosheGitPull() abort
  echo 'Pulling...'
  Git pull --quiet
  let l:exit_status = get(FugitiveResult(), 'exit_status', 1)
  if l:exit_status != 0
    echo 'Failed pulling 😒'
  else
    echo 'Pulled! 😎'
  endif
endfunction
command! -bang Gl call <sid>MosheGitPull()
nmap <silent> <leader>gl :Gl<cr>

function Enter_Wip_Moshe() abort
  G commit --quiet -m 'wip'
  exe 'Git push -u origin ' . FugitiveHead()
endfunction
" Autocmd
function! s:ftplugin_fugitive() abort
  nnoremap <buffer> <silent> cc :Git commit --quiet<CR>
  nnoremap <buffer> <silent> gl :Gl<CR>
  nnoremap <buffer> <silent> gp :Gp<CR>
  nnoremap <buffer> <silent> pr :silent! !cpr<CR>
  nnoremap <buffer> <silent> wip :call Enter_Wip_Moshe()<cr>

endfunction
augroup moshe_fugitive
  autocmd!
  autocmd FileType fugitive call s:ftplugin_fugitive()
augroup END

" }}}

" Git merge origin master
command! -bang Gmom exe 'G merge origin/' . 'master'

" Create a new branch
function! Gcb(...)
  let name = a:1
  if name ==? ''
    call inputsave()
    let name = input('Enter branch name: ')
    call inputrestore()
  endif
  echom ''
  execute 'Git checkout -b ' . name
endfunction
command! -nargs=? Gcb call Gcb("<args>")

function! ToggleGStatus()
  if buflisted(bufname('.git/index'))
    bd .git/index
  else
    Git
    " 20wincmd_
  endif
endfunction
command! ToggleGStatus :call ToggleGStatus()
nnoremap <silent> <leader>gg :ToggleGStatus<cr>

" Gdiffrev {{{
nmap <leader>dh :DiffHistory<Space>
command! -nargs=? DiffHistory call s:view_git_history('<args>')
command! DiffFile call s:view_git_history('current_file')
nmap <silent> <leader>gh :DiffFile<cr>

function! s:view_git_history(...) abort
  let branch_name = a:1
  if branch_name ==# 'current_file'
    0Gclog
  elseif branch_name !=? ''
    execute 'Git difftool --name-only ' . branch_name . '...@'
  else
    Git difftool --name-only ! !^@
  endif
  call s:diff_current_quickfix_entry()
  " Bind <CR> for current quickfix window to properly set up diff split layout after selecting an item
  " There's probably a better way to map this without changing the window
  copen
  nnoremap <buffer> <CR> <CR><BAR>:call <sid>diff_current_quickfix_entry()<CR>
  wincmd p
endfunction

function s:diff_current_quickfix_entry() abort
  " Cleanup windows
  for window in getwininfo()
    if window.winnr !=? winnr() && bufname(window.bufnr) =~? '^fugitive:'
      exe 'bdelete' window.bufnr
    endif
  endfor
  cc
  call s:add_mappings()
  let qf = getqflist({'context': 0, 'idx': 0})
  if get(qf, 'idx') && type(get(qf, 'context')) == type({}) && type(get(qf.context, 'items')) == type([])
    let diff = get(qf.context.items[qf.idx - 1], 'diff', [])
    for i in reverse(range(len(diff)))
      exe (i ? 'leftabove' : 'rightbelow') 'vert diffsplit' fnameescape(diff[i].filename)
      call s:add_mappings()
    endfor
  endif
endfunction

function! s:add_mappings() abort
  nnoremap <buffer>]q :cnext <BAR> :call <sid>diff_current_quickfix_entry()<CR>
  nnoremap <buffer>[q :cprevious <BAR> :call <sid>diff_current_quickfix_entry()<CR>
  " Reset quickfix height. Sometimes it messes up after selecting another item
  11copen
  wincmd p
endfunction
" }}}

function Unpushed_Unpulled() abort
  " Don't operate if not on git directory
  if empty(FugitiveGitDir())
    return '↑- ↓-'
  endif
  let last_run = get(g:, 'unpushed_unpulled_last_run', 0)
  if last_run != 0 && last_run + 10 > strftime('%s')
    " Return already existing status
    return get(g:, 'unpushed_unpulled_last_status', 0)
  endif

  let unpushed_unpulled_line_string = '# branch.ab '
  let status_output = systemlist(FugitiveShellCommand([ 'status', '--porcelain=v2', '--branch' ]))
  let unpushed_unpulled_index = match(status_output, unpushed_unpulled_line_string)
  if unpushed_unpulled_index ==# -1
    return '↑- ↓-'
  endif
  let g:unpushed_unpulled_last_run = strftime('%s')
  let g:unpushed_unpulled_last_status = substitute(
          \ substitute(
            \ substitute(status_output[unpushed_unpulled_index], unpushed_unpulled_line_string, '', ''),
            \ '+', '↑', ''
          \ ),
          \ '-', '↓', ''
        \ )
  return g:unpushed_unpulled_last_status
endfunction

" }}}

" Conflict marker {{{
let g:conflict_marker_highlight_group = 'VisualNOS'
highlight ConflictMarkerBegin guibg=#2f7366
highlight ConflictMarkerOurs guibg=#2e5049
highlight ConflictMarkerTheirs guibg=#344f69
highlight ConflictMarkerEnd guibg=#2f628e
highlight ConflictMarkerCommonAncestorsHunk guibg=#754a81

" }}}

]]
