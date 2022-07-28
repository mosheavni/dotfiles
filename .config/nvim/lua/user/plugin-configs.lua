local utils = require 'user.utils'
local keymap = utils.keymap
local opts = utils.map_opts
local autocmd = utils.autocmd
local augroup = utils.augroup

-- Colorscheme
vim.g.material_style = 'darker'
vim.cmd [[colorscheme gruvbox]]
-- WinResizer
vim.g['winresizer_start_key'] = '<C-E>'
keymap('t', '<C-E>', '<Esc><Cmd>WinResizerStartResize<CR>', opts.no_remap_silent)
-- Vim json path
vim.g['jsonpath_register'] = '*'
-- Comment.nvim
require('Comment').setup {}
-- Vim easy align
keymap('n', 'ga', '<Plug>(EasyAlign)', {})
-- Floaterm
vim.g['floaterm_keymap_toggle'] = '<F6>'
vim.g['floaterm_keymap_new'] = '<F7>'
vim.g['floaterm_keymap_next'] = '<F8>'
vim.g['floaterm_width'] = 0.7
vim.g['floaterm_height'] = 0.9
-- Dressing.nvim
require('dressing').setup {
  input = {
    winblend = 100,
  },
}
vim.cmd [[hi link FloatTitle Normal]]
-- Diffview
local actions = require 'diffview.actions'
require('diffview').setup {}
--   enhanced_diff_hl = true, -- See ':h diffview-config-enhanced_diff_hl'
--   keymaps = {
--     disable_defaults = true, -- Disable the default keymaps
--     file_panel = {
--       ['cc'] = '<cmd>G commit<cr>',
--     },
--   },
-- }
-- Vim ansible
vim.g['ansible_goto_role_paths'] = '.;,roles;'
-- Yaml Revealer
vim.g['yaml_revealer_separator'] = '.'
vim.g['yaml_revealer_list_indicator'] = 1
-- Spectre
keymap('n', '<leader>S', "<cmd>lua require('spectre').open_visual({select_word=true})<CR>", opts.silent)
keymap('v', '<leader>s', "<cmd>lua require('spectre').open_visual()<CR>", opts.no_remap)
require 'user.spectre'
-- AnyJump
keymap('n', '<leader>j', '<cmd>AnyJump<CR>', opts.no_remap)
-- Editor config
vim.g['EditorConfig_exclude_patterns'] = { 'fugitive://.*' }
-- neoscroll
if not vim.g.neovide then
  require('neoscroll').setup {
    -- All these keys will be mapped to their corresponding default scrolling animation
    mappings = { '<C-u>', '<C-d>', 'zt', 'zz', 'zb' },
  }
end
-- buffertag
require('buffertag').enable()
-- Github Copilot
vim.cmd [[
imap <silent><script><expr> <M-Enter> copilot#Accept("\<CR>")
" imap <silent> <c-]> <Plug>(copilot-next)
" inoremap <silent> <c-[> <Plug>(copilot-previous)
let g:copilot_no_tab_map = v:true
]]
-- Colorizer
require('colorizer').setup()
-- Vim close tag
vim.g['closetag_filenames'] = '*.html,*.xhtml,*.phtml,*.erb,*.jsx,*.tsx,*.js'
vim.g['closetag_filetypes'] = 'html,xhtml,phtml,javascript,javascriptreact'
-- DevIcons
vim.g['WebDevIconsOS'] = 'Darwin'
vim.g['DevIconsEnableFoldersOpenClose'] = 1
vim.g['DevIconsEnableFolderExtensionPatternMatching'] = 1
-- Conflict marker
vim.cmd [[
" disable the default highlight group
let g:conflict_marker_highlight_group = ''

" Include text after begin and end markers
let g:conflict_marker_begin = '^<<<<<<< .*$'
let g:conflict_marker_end   = '^>>>>>>> .*$'

highlight ConflictMarkerBegin guibg=#2f7366
highlight ConflictMarkerOurs guibg=#2e5049
highlight ConflictMarkerTheirs guibg=#344f69
highlight ConflictMarkerEnd guibg=#2f628e
highlight ConflictMarkerCommonAncestorsHunk guibg=#754a81
]]
-- Startify
vim.g['startify_custom_header'] = {
  [[   😎               🎃              😎]],
  [[    _   _         __     ___]],
  [[   | \ | | ___  __\ \   / (_)_ __ ___]],
  [[   |  \| |/ _ \/ _ \ \ / /| |  _ ` _ \]],
  [[   | |\  |  __/ (_) \ V / | | | | | | |]],
  [[   |_| \_|\___|\___/ \_/  |_|_| |_| |_|]],
  '',
  '   🚀               ✨              🚀',
}
-- NERDTree
vim.g['NERDTreeChDirMode'] = 2
vim.g['NERDTreeHijackNetrw'] = 1
vim.g['NERDTreeShowHidden'] = 1
vim.g['NERDTreeHighlightCursorline'] = 1
vim.g['NERDTreeFileExtensionHighlightFullName'] = 1
vim.g['NERDTreeGitStatusUseNerdFonts'] = 1
-- vim.g["NERDTreeGitStatusConcealBrackets"] = 1
vim.g['NERDTreeGitStatusIndicatorMapCustom'] = {
  Modified = '✹',
  Staged = '✚',
  Untracked = '✭',
  Unmerged = '═',
  Dirty = '✗',
  Renamed = '➜',
  Clean = '✔︎',
  Ignored = '☒',
  Deleted = '✖',
  Unknown = '?',
}
vim.cmd [[
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
]]
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
vim.notify = require 'notify'
require('fidget').setup {
  text = {
    spinner = 'moon',
  },
  align = {
    bottom = true,
  },
  window = {
    relative = 'editor',
  },
}
-- Which-Key
require('which-key').setup {}
require 'user.which-key'
-- bulb (code actions)
local lightbulb = require 'nvim-lightbulb'
lightbulb.setup {
  sign = {
    enabled = false,
  },
  virtual_text = {
    enabled = true,
    text = '💡',
    -- highlight mode to use for virtual text (replace, combine, blend), see :help nvim_buf_set_extmark() for reference
    hl_mode = 'replace',
  },
}
local bulb_au = augroup 'BulbAu'
autocmd({ 'CursorHold', 'CursorHoldI' }, {
  group = bulb_au,
  pattern = '*',
  callback = function()
    lightbulb.update_lightbulb()
  end,
})
-- Trouble
require('trouble').setup()
keymap('n', '<leader>xx', '<cmd>TroubleToggle<cr>', opts.no_remap_silent)
keymap('n', '<leader>xw', '<cmd>TroubleToggle workspace_diagnostics<cr>', opts.no_remap_silent)
keymap('n', '<leader>xd', '<cmd>TroubleToggle document_diagnostics<cr>', opts.no_remap_silent)
keymap('n', '<leader>xl', '<cmd>TroubleToggle loclist<cr>', opts.no_remap_silent)
keymap('n', '<leader>xq', '<cmd>TroubleToggle quickfix<cr>', opts.no_remap_silent)
keymap('n', 'gR', '<cmd>TroubleToggle lsp_references<cr>', opts.no_remap_silent)
-- indent_blankline
vim.cmd [[highlight IndentBlanklineIndent1 guifg=#C678DD gui=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent2 guifg=#E06C75 gui=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent3 guifg=#E5C07B gui=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent4 guifg=#98C379 gui=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent5 guifg=#56B6C2 gui=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent6 guifg=#61AFEF gui=nocombine]]
require('indent_blankline').setup {
  filetype_exclude = {
    'help',
    'terminal',
    'alpha',
    'packer',
    'lspinfo',
    'TelescopePrompt',
    'TelescopeResults',
    'NvimTree',
    'nvchad_cheatsheet',
    'lsp-installer',
    '',
  },
  buftype_exclude = { 'terminal' },
  show_trailing_blankline_indent = false,
  show_first_indent_level = false,
  show_current_context = true,
  show_current_context_start = true,
  space_char_blankline = ' ',
  char_highlight_list = {
    'IndentBlanklineIndent1',
    'IndentBlanklineIndent2',
    'IndentBlanklineIndent3',
    'IndentBlanklineIndent4',
    'IndentBlanklineIndent5',
    'IndentBlanklineIndent6',
  },
}
-- Ansible
vim.cmd [[
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
]]
-- Fugitive
vim.cmd [[
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

" Push
function! s:MosheGitPush() abort
  echo 'Pushing to ' . FugitiveHead() . '...'
  exe 'Git! push -u origin ' . FugitiveHead()
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

function! RandomEmoji() abort
  let l:emojis = [
    \ '🤩',
    \ '👻',
    \ '😈',
    \ '✨',
    \ '👰',
    \ '👑',
    \ '💯',
    \ '💖',
    \ '🌒',
    \ '🇮🇱',
    \ '★',
    \ '⚓️',
    \ '🙉',
    \ '☘️',
    \ '🌍',
    \ '🥨',
    \ '🔥',
    \ '🚀'
  \ ]
  return l:emojis[localtime() % len(l:emojis)]
endfunction

function! Enter_Wip_Moshe() abort
  let l:random_emoji = RandomEmoji()
  let l:time_now = strftime('%c')
  let l:commit_message = l:random_emoji . ' wip ' . l:time_now
  echom "Committing: " . l:commit_message
  exe "G commit --quiet -m '" . l:commit_message . "'"
  exe 'Git! push -u origin ' . FugitiveHead()
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

" Git merge origin master
command! -bang Gmom exe 'G merge origin/' . 'master'

function! ToggleGStatus()
  if buflisted(bufname('.git/index'))
    bd .git/index
  else
    Git
    " 17wincmd_
  endif
endfunction
command! ToggleGStatus :call ToggleGStatus()
nnoremap <silent> <leader>gg :ToggleGStatus<cr>
nmap <silent><expr> <leader>gf bufname('.git/index') ? ':exe bufwinnr(bufnr(bufname(".git/index"))) . "wincmd w"<cr>' : ':Git<cr>'

nnoremap <leader>gc :Gcd <bar> echom "Changed directory to Git root"<bar>pwd<cr>

" Gdiffrev
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
]]

local new_branch = function(branch_opts)
  if branch_opts.args ~= '' then
    return vim.cmd('Git checkout -b ' .. branch_opts.args)
  end
  local input = vim.fn.input('Enter new branch name: ', '')
  if input == '' then
    return
  end
  vim.cmd('Git checkout -b ' .. input)
end
vim.api.nvim_create_user_command('Gcb', new_branch, { nargs = '?' })

require 'user.cmpconf'
require 'user.treesitter'
require 'user.lsp'
require 'user.autocommands'
require 'user.gitsigns'
require 'user.telescope'
require 'user.lualine'
require 'user.navigator'

local custom_settings_ok, custom_settings = pcall(require, 'user.custom-settings')
if custom_settings_ok then
  custom_settings.plugin_configs()
end
