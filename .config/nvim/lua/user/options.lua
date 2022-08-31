local opt = vim.opt
local utils = require 'user.utils'
local opts = utils.map_opts
local keymap = utils.keymap
opt.compatible = false

-- disable legacy vim filetype detection in favor of new lua based from neovim
-- vim.g.do_filetype_lua = 1
-- vim.g.did_load_filetypes = 0

opt.cursorcolumn = true
opt.cursorline = true -- Add highlight behind current line
opt.shortmess:append { c = true, l = false, q = false, S = false }
opt.list = true
opt.listchars = { tab = '┆·', trail = '·', precedes = '', extends = '', eol = '↲' }
-- set lcscope=tab:┆·,trail:·,precedes:,extends:
opt.fillchars = { vert = '|', fold = '·' }
opt.emoji = false
-- go to previous/next line with h,l,left arrow and right arrow
-- when cursor reaches end/beginning of line
-- opt.whichwrap:append '<>[]hl'

opt.number = true -- Show current line number
opt.relativenumber = true -- Show relative line numbers
opt.linebreak = true -- Avoid wrapping a line in the middle of a word.
opt.wrap = true -- Wrap long lines
opt.hlsearch = true -- highlight reg. ex. in @/ register
opt.incsearch = true -- Search as characters are typed
opt.inccommand = 'split' -- Incremental search and replace with small split window
opt.ignorecase = true -- Search case insensitive...
opt.smartcase = true -- ignore case if search pattern is all lowercase, case-sensitive otherwise
opt.autoread = true -- Re-read file if it was changed from the outside
opt.scrolloff = 7 -- When about to scroll page, see 7 lines below cursor
opt.cmdheight = 2 -- Height of the command bar
opt.hidden = true -- Hide buffer if abandoned
opt.showmatch = true -- When closing a bracket (like {}), show the enclosing
opt.splitbelow = true -- Horizontaly plitted windows open below
opt.splitright = true -- Vertically plitted windows open below bracket for a brief second
opt.startofline = false -- Stop certain movements from always going to the first character of a line.
opt.confirm = true -- Prompt confirmation if exiting unsaved file
opt.lazyredraw = true -- redraw only when we need to.
opt.swapfile = false
opt.backup = false
opt.writebackup = false
opt.wildmenu = true -- Displays a menu on autocomplete
opt.wildmode = { 'longest:full', 'full' } -- Command-line completion mode
opt.completeopt = { 'menu', 'menuone', 'noselect' }
opt.previewheight = 15
opt.title = true -- Changes the iterm title
opt.titlestring = "nvim: %{substitute(getcwd(), $HOME, '~', '')}"
opt.showcmd = true
opt.guifont = 'Fira Code,Hack Nerd Font'
opt.mouse = 'a'
opt.undofile = true -- Enables saving undo history to a file
-- opt.colorcolumn = '80' -- Mark where are 80 characters to start breaking line
opt.textwidth = 80
opt.fileencodings = { 'utf-8', 'cp1251' }
opt.encoding = 'utf-8'
opt.visualbell = true -- Use visual bell instead of beeping
opt.conceallevel = 1
opt.showmode = false -- Redundant as lighline takes care of that
opt.history = 1000
opt.termguicolors = true
opt.signcolumn = 'auto'
-- require 'user.winbar'
-- opt.winbar = "%{%v:lua.require'user.winbar'.eval()%}"

-- Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable delays and poor user experience.
opt.updatetime = 300

-- Ignore node_modules and other dirs
opt.wildignore:append { '**/node_modules/**', '.hg', '.git', '.svn', '*.DS_Store', '*.pyc' }
opt.path:append { '**' }

-- Folding
opt.foldenable = true
opt.foldmethod = 'syntax'
opt.foldlevel = 999
opt.foldlevelstart = 10

-- j = Delete comment character when joining commented lines.
-- t = auto break long lines
-- r = auto insert comment leader after <Enter> (insert mode)
-- o = auto insert comment leader after o (normal mode)
-- l = don't break long lines
opt.formatoptions:append { j = true, t = true, r = true, o = true, l = true }

-- Indenting
opt.breakindent = true -- Maintain indent on wrapping lines
opt.autoindent = true -- always set autoindenting on
opt.copyindent = true -- copy the previous indentation on autoindenting
opt.smartindent = true -- Number of spaces to use for each step of (auto)indent.
opt.shiftwidth = 4 -- Number of spaces for each indent
opt.softtabstop = 4
opt.tabstop = 4
opt.smarttab = true -- insert tabs on the start of a line according to shiftwidth, not tabstop
opt.expandtab = true -- Tab changes to spaces. Format with :retab

-- Neovide
vim.g.neovide_cursor_vfx_mode = 'railgun'
vim.g.neovide_scroll_animation_length = 0.5
vim.g.neovide_fullscreen = true
-- Allow clipboard copy paste in neovim
vim.g.neovide_input_use_logo = 1
keymap('', '<D-v>', '+p<CR>', opts.no_remap_silent)
keymap('!', '<D-v>', '<C-R>+', opts.no_remap_silent)
keymap('t', '<D-v>', '<C-R>+', opts.no_remap_silent)
keymap('v', '<D-v>', '<C-R>+', opts.no_remap_silent)

-- Set shell
if vim.fn.executable '/bin/zsh' == 1 then
  opt.shell = '/bin/zsh -l'
elseif vim.fn.executable '/bin/bash' == 1 then
  opt.shell = '/bin/bash'
else
  opt.shell = '/bin/sh'
end

-- Set python path
if vim.fn.executable '/usr/local/bin/python3' == 1 then
  vim.g.python3_host_prog = '/usr/local/bin/python3'
elseif vim.fn.executable '/usr/bin/python3' == 1 then
  vim.g.python3_host_prog = '/usr/bin/python3'
end

vim.cmd [[
hi ColorColumn ctermbg=238 guibg=lightgrey

let &t_SI = "\<Esc>]50;CursorShape=1\x7"
let &t_SR = "\<Esc>]50;CursorShape=2\x7"

filetype indent on
]]

-- Abbreviations
vim.cmd [[
inoreabbrev teh the
inoreabbrev seperate separate
inoreabbrev dont don't
inoreabbrev rbm # TODO: remove before merging
inoreabbrev cbm # TODO: change before merging
inoreabbrev ubm # TODO: uncomment before merging
inoreabbrev funciton function
inoreabbrev functiton function
inoreabbrev fucntion function
inoreabbrev funtion function
inoreabbrev erturn return
inoreabbrev retunr return
inoreabbrev reutrn return
inoreabbrev reutn return
inoreabbrev queyr query
inoreabbrev htis this
inoreabbrev foreahc foreach
inoreabbrev forech foreach
]]

vim.cmd [[
let g:sh_fold_enabled = 4

com! FormatJSON exe '%!python -m json.tool'

function! FormatEqual() abort
  let save_cursor = getcurpos()
  normal! gg=G
  silent! exe '%s#)\zs\ze{# #g'
  call setpos('.', save_cursor)
  echom 'Formatted with equalprg'
endfunction

]]

-- Run current buffer
vim.cmd [[
" Will attempt to execute the current file based on the `&filetype`
" You need to manually map the filetypes you use most commonly to the
" correct shell command.
function! ExecuteFile()
  let l:filetype_to_command = {
        \   'javascript': 'node',
        \   'python': 'python3',
        \   'html': 'open',
        \   'sh': 'bash'
        \ }
  call inputsave()
  let sure = input('Are you sure you want to run the current file? (y/n): ')
  call inputrestore()
  if sure !=# 'y'
    return ''
  endif
  echo ''
  let l:cmd = get(l:filetype_to_command, &filetype, 'bash')
  :%y
  new | 0put
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
  exe '%!'.l:cmd
  normal! ggO
  call setline(1, 'Output of ' . l:cmd . ' command:')
  normal! yypVr=o
endfunction

nnoremap <silent> <F3> :call ExecuteFile()<CR>
]]

-- Grep
vim.cmd [[
" Set grepprg as RipGrep or ag (the_silver_searcher), fallback to grep
if executable('rg')
  let &grepprg="rg --vimgrep --no-heading --smart-case --hidden --follow -g '!{" . &wildignore . "}' -uu $*"
  let g:grep_literal_flag="-F"
  set grepformat=%f:%l:%c:%m,%f:%l:%m
elseif executable('ag')
  let &grepprg='ag --vimgrep --smart-case --hidden --follow --ignore "!{' . &wildignore . '}" $*'
  let g:grep_literal_flag="-Q"
  set grepformat=%f:%l:%c:%m
else
  let &grepprg='grep -n -r --exclude=' . shellescape(&wildignore) . ' . $*'
  let g:grep_literal_flag="-F"
endif

function! RipGrepCWORD(bang, visualmode, ...) abort
  let search_word = a:1

  if a:visualmode
    " Get the line and column of the visual selection marks
    let [lnum1, col1] = getpos("'<")[1:2]
    let [lnum2, col2] = getpos("'>")[1:2]

    " Get all the lines represented by this range
    let lines = getline(lnum1, lnum2)

    " The last line might need to be cut if the visual selection didn't end on the last column
    let lines[-1] = lines[-1][: col2 - (&selection ==? 'inclusive' ? 1 : 2)]
    " The first line might need to be trimmed if the visual selection didn't start on the first column
    let lines[0] = lines[0][col1 - 1:]

    " Get the desired text
    let search_word = join(lines, "\n")
  endif
  if search_word ==? ''
    let search_word = expand('<cword>')
  endif

  " Set bang command for literal search (no regexp expansion)
  let search_message_literally = "for " . search_word
  if a:bang == "!"
    let search_message_literally = "literally for " . search_word
    let search_word = get(g:, 'grep_literal_flag', "") . ' ' . shellescape(search_word)
  endif

  echom 'Searching ' . search_message_literally

  " Silent removes the "press enter to continue" prompt
  " Bang (!) is for literal search (no regexp expansion)
  let grepcmd = 'silent grep! ' . search_word
  execute grepcmd
endfunction
command! -bang -range -nargs=? RipGrepCWORD call RipGrepCWORD("<bang>", v:false, <q-args>)
command! -bang -range -nargs=? RipGrepCWORDVisual call RipGrepCWORD("<bang>", v:true, <q-args>)
nmap <c-f> :RipGrepCWORD!<Space>
vmap <c-f> :RipGrepCWORDVisual!<cr>
]]

-- Terminal configurations
vim.cmd [[
if exists(':terminal')

  if !exists('g:terminal_ansi_colors')
    let g:terminal_ansi_colors = [
          \'#21222C',
          \'#FF5555',
          \'#69FF94',
          \'#FFFFA5',
          \'#D6ACFF',
          \'#FF92DF',
          \'#A4FFFF',
          \'#FFFFFF',
          \'#636363',
          \'#F1FA8C',
          \'#BD93F9',
          \'#FF79C6',
          \'#8BE9FD',
          \'#F8F8F2',
          \'#6272A4',
          \'#FF6E6E'
    \]
  endif

  " Function to set terminal colors
  fun! s:setTerminalColors()
    if exists('g:terminal_ansi_colors')
      for i in range(len(g:terminal_ansi_colors))
          exe 'let g:terminal_color_' . i . ' = g:terminal_ansi_colors[' . i . ']'
      endfor
      unlet! g:terminal_ansi_colors
    endif
  endfunction

  augroup TerminalAugroup
    autocmd!

    " Start terminal in insert mode
    autocmd BufEnter * if &buftype == 'terminal' | :startinsert | endif

    " Call terminal colors function only after colorscheme changed
    autocmd Colorscheme * call <sid>setTerminalColors()
  augroup END

  tnoremap <Esc> <C-\><C-n>

  " To force using 256 colors
  set t_Co=256
endif

]]

-- Visual Calculator
vim.cmd [[
function s:VisualCalculator() abort
  let save_pos = getpos('.')
  " Get visual selection
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][: col2 - (&selection ==? 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][col1 - 1:]
  let first_expr = join(lines, "\n")

  " Get arithmetic operation from user input
  call inputsave()
  let operation = input('Enter operation: ')
  call inputrestore()

  " Calculate final result
  let fin_result = eval(str2nr(first_expr) . operation)

  " Replace
  exe 's/\%V' . first_expr . '/' . fin_result . '/'

  call setpos('.', save_pos)
endfunction
command! -range VisualCalculator call <SID>VisualCalculator()
vmap <c-r> :VisualCalculator<cr>
]]

-- SynStack - see highlight under cursor
vim.cmd [[
function! s:SynStack()
  if !exists("*synstack")
    return
  endif
  return map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunc
command! SynStack echo <SID>SynStack()
]]

vim.cmd [[
" Better yanking {{{
" note:
"   the register 1 is reserved for deletion
"   there's no "small yank" register
"   can break :h redo-register
"   still misses any manual register 0 change
augroup YankShift | au!
    let s:regzero = [getreg(0), getregtype(0)]
    autocmd TextYankPost * call <SID>yankshift(v:event)
augroup end

function! s:yankshift(event)
    if a:event.operator ==# 'y' && (empty(a:event.regname) || a:event.regname == '"')
        for l:regno in range(8, 2, -1)
            call setreg(l:regno + 1, getreg(l:regno), getregtype(l:regno))
        endfor
        call setreg(2, s:regzero[0], s:regzero[1])
        let s:regzero = [a:event.regcontents, a:event.regtype]
    elseif a:event.regname == '0'
        let s:regzero = [a:event.regcontents, a:event.regtype]
    endif
endfunction
" }}}
]]

-- disable some builtin vim plugins
local default_plugins = {
  '2html_plugin',
  'getscript',
  'getscriptPlugin',
  'gzip',
  'logipat',
  -- 'netrw',
  -- 'netrwPlugin',
  'netrwSettings',
  'netrwFileHandlers',
  'matchit',
  'tar',
  'tarPlugin',
  'rrhelper',
  'spellfile_plugin',
  'vimball',
  'vimballPlugin',
  'zip',
  'zipPlugin',
}
for _, plugin in pairs(default_plugins) do
  vim.g['loaded_' .. plugin] = 1
end
