-- WinResizer
vim.g["winresizer_start_key"]                         = '<C-E>'
-- Vim json path
vim.g["jsonpath_register"]                            = '*'
-- Floaterm
vim.g["floaterm_keymap_toggle"]                       = '<F6>'
vim.g["floaterm_keymap_new"]                          = '<F7>'
vim.g["floaterm_keymap_next"]                         = '<F8>'
vim.g["floaterm_width"]                               = 0.7
vim.g["floaterm_height"]                              = 0.9
-- Vim ansible
vim.g["ansible_goto_role_paths"]                      = '.;,roles;'
-- Yaml Revealer
vim.g["yaml_revealer_separator"]                      = '.'
vim.g["yaml_revealer_list_indicator"]                 = 1
-- Editor config
vim.g["EditorConfig_exclude_patterns"]                = { 'fugitive://.*' }
-- Vim terraform
vim.g["terraform_fmt_on_save"]                        = 1
-- Vim close tag
vim.g["closetag_filenames"]                           = '*.html,*.xhtml,*.phtml,*.erb,*.jsx,*.tsx,*.js'
vim.g["closetag_filetypes"]                           = 'html,xhtml,phtml,javascript,javascriptreact'
-- Nerd Tree
vim.g["NERDTreeChDirMode"]                            = 2
vim.g["NERDTreeHijackNetrw"]                          = 1
vim.g["NERDTreeShowHidden"]                           = 1
vim.g["NERDTreeHighlightCursorline"]                  = 1
vim.g["NERDTreeFileExtensionHighlightFullName"]       = 1
vim.g["NERDTreeGitStatusUseNerdFonts"]                = 1
-- vim.g["NERDTreeGitStatusConcealBrackets"] = 1
vim.g["NERDTreeGitStatusIndicatorMapCustom"]          = {
  Modified  = '✹',
  Staged    = '✚',
  Untracked = '✭',
  Unmerged  = '═',
  Dirty     = '✗',
  Renamed   = '➜',
  Clean     = '✔︎',
  Ignored   = '☒',
  Deleted   = '✖',
  Unknown   = '?'
}
-- DevIcons
vim.g["WebDevIconsOS"]                                = 'Darwin'
vim.g["DevIconsEnableFoldersOpenClose"]               = 1
vim.g["DevIconsEnableFolderExtensionPatternMatching"] = 1
-- Conflict marker
vim.g["conflict_marker_highlight_group"]              = 'VisualNOS'
vim.cmd [[
highlight ConflictMarkerBegin guibg=#2f7366
highlight ConflictMarkerOurs guibg=#2e5049
highlight ConflictMarkerTheirs guibg=#344f69
highlight ConflictMarkerEnd guibg=#2f628e
highlight ConflictMarkerCommonAncestorsHunk guibg=#754a81
]]
-- Startify
vim.g["startify_custom_header"] = {
  [[   😎               🎃              😎]],
  [[    _   _         __     ___]],
  [[   | \ | | ___  __\ \   / (_)_ __ ___]],
  [[   |  \| |/ _ \/ _ \ \ / /| |  _ ` _ \]],
  [[   | |\  |  __/ (_) \ V / | | | | | | |]],
  [[   |_| \_|\___|\___/ \_/  |_|_| |_| |_|]],
  '', '   🚀               ✨              🚀'
}
-- Switch vim
-- The map switch is between underscores to camelCase: moshe_king -> mosheKing -> moshe_king.
vim.g['switch_custom_definitions'] = {
  { 'SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT' },
  { 'yes', 'no' },
  { 'enable', 'disable' },
  { '==', '!=' },
  -- {
  --   [vim.regex([[\<[a-z0-9]\+_\k\+\>]])] = {
  --     [vim.regex([[_\(.\)]])] = vim.regex([[\U\1]])
  --   },
  --   [vim.regex([[\<[a-z0-9]\+[A-Z]\k\+\>]])] = {
  --     [vim.regex([[\([A-Z]\)]])] = vim.regex([[_\l\1]])
  --   },
  -- }
}
-- fidget
vim.notify = require("notify")
require("fidget").setup {
  text = {
    spinner = "moon",
  },
  align = {
    bottom = true,
  },
  window = {
    relative = "editor",
  },
}
-- disable netrw
vim.g['loaded_netrwPlugin'] = 1
-- nvim gps
require("nvim-gps").setup()

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

colorscheme gruvbox

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


" }}}

]]
