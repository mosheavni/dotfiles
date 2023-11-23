local utils = require 'user.utils'
local opts = utils.map_opts
local keymap = utils.keymap
local tnoremap = utils.tnoremap
local vnoremap = utils.vnoremap
vim.o.compatible = false
vim.g.python3_host_prog = 'python3'

-- disable legacy vim filetype detection in favor of new lua based from neovim
-- vim.g.do_filetype_lua = 1
-- vim.g.did_load_filetypes = 0

vim.o.cursorcolumn = true
vim.o.cursorline = true -- Add highlight behind current line
vim.opt.shortmess:append { c = true, l = false, q = false, S = false, C = true, I = true }
vim.o.list = true
vim.opt.listchars = {
  tab = '┆·',
  -- trail = '·',
  precedes = '',
  extends = '',
  eol = '↲',
}
-- set lcscope=tab:┆·,trail:·,precedes:,extends:
vim.opt.fillchars = {
  vert = '|',
  fold = ' ',
  foldopen = '',
  foldclose = '',
}
-- vim.opt.foldcolumn = '1'
vim.o.emoji = false
-- go to previous/next line with h,l,left arrow and right arrow
-- when cursor reaches end/beginning of line
-- opt.whichwrap:append '<>[]hl'
vim.opt.diffopt:append { linematch = 50 }
vim.opt.diffopt:append 'vertical'
vim.o.splitkeep = 'screen'

vim.o.number = true -- Show current line number
vim.o.numberwidth = 4 -- set number column width to 2 {default 4}
vim.o.relativenumber = true -- Show relative line numbers
vim.o.linebreak = true -- Avoid wrapping a line in the middle of a word.
vim.o.wrap = true -- Wrap long lines
vim.o.hlsearch = true -- highlight reg. ex. in @/ register
vim.o.incsearch = true -- Search as characters are typed
vim.o.inccommand = 'split' -- Incremental search and replace with small split window
vim.o.ignorecase = true -- Search case insensitive...
vim.o.smartcase = true -- ignore case if search pattern is all lowercase, case-sensitive otherwise
vim.o.autoread = true -- Re-read file if it was changed from the outside
vim.o.scrolloff = 4 -- When about to scroll page, see 7 lines below cursor
vim.o.sidescrolloff = 8 -- Columns of context
vim.o.cmdheight = 1 -- Height of the command bar
vim.o.hidden = true -- Hide buffer if abandoned
vim.o.showmatch = true -- When closing a bracket (like {}), show the enclosing
vim.o.splitbelow = true -- Horizontaly plitted windows open below
vim.o.splitright = true -- Vertically plitted windows open below bracket for a brief second
vim.o.startofline = false -- Stop certain movements from always going to the first character of a line.
vim.o.pumheight = 10 -- pop up menu height
vim.o.pumblend = 40 -- Popup blend
vim.o.confirm = true -- Prompt confirmation if exiting unsaved file
vim.o.lazyredraw = false -- redraw only when we need to.
vim.o.swapfile = false
vim.o.backup = false
vim.o.backupdir = vim.fn.stdpath 'state' .. '/backup'
vim.o.writebackup = false
vim.o.wildmenu = true -- Displays a menu on autocomplete
vim.opt.wildmode = { 'longest:full', 'full' } -- Command-line completion mode
vim.opt.completeopt = 'menu,menuone,noselect'
vim.o.previewheight = 15
vim.o.title = true -- Changes the iterm title
vim.o.laststatus = 3 -- Global statusline, only one for all buffers
vim.o.titlestring = "nvim: %{substitute(getcwd(), $HOME, '~', '')}"
vim.o.showcmd = true
vim.o.guifont = 'Fira Code,Hack Nerd Font'
vim.o.mouse = 'a'
vim.o.undofile = true -- Enables saving undo history to a file
vim.o.undolevels = 10000
-- opt.colorcolumn = '80' -- Mark where are 80 characters to start breaking line
vim.o.textwidth = 80
vim.opt.fileencodings = { 'utf-8', 'cp1251' }
vim.o.encoding = 'utf-8'
vim.o.visualbell = true -- Use visual bell instead of beeping
vim.o.conceallevel = 0
vim.o.showmode = false -- Redundant as lighline takes care of that
vim.opt.cpoptions:append '>'
vim.o.equalalways = true -- When splitting window, make new window same size
vim.o.history = 1000
vim.o.termguicolors = true
vim.o.signcolumn = 'yes'
-- require 'user.winbar'
-- opt.winbar = "%{%v:lua.require'user.winbar'.eval()%}"
-- vim.o.statuscolumn = '%=%{v:wrap?"":v:relnum?v:relnum:v:lnum} %s%C'

-- Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable delays and poor user experience.
vim.o.updatetime = 300

-- Ignore node_modules and other dirs
vim.opt.wildignore:append { '**/node_modules/**', '.hg', '.git', '.svn', '*.DS_Store', '*.pyc' }
vim.opt.path:append { '**' }

-- Folding
vim.o.foldenable = true
-- vim.o.foldmethod = 'syntax'
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
vim.o.foldlevel = 999
vim.o.foldlevelstart = 99
vim.o.foldcolumn = '1' -- '0' is not bad
vim.o.foldenable = true

-- Support undercurl
vim.cmd [[
let &t_8u = "\e[58:2:%lu:%lu:%lum"
let &t_Cs = "\e[4:3m"
let &t_Ce = "\e[4:0m"
]]

-- j = Delete comment character when joining commented lines.
-- t = auto break long lines
-- r = auto insert comment leader after <Enter> (insert mode)
-- o = auto insert comment leader after o (normal mode)
-- l = don't break long lines
vim.opt.formatoptions:append {
  j = true, -- Where it makes sense, remove a comment leader when joining lines.
  t = true, -- Auto-wrap text using 'textwidth'
  r = true, -- Automatically insert the current comment leader after hitting
  -- <Enter> in Insert mode.
  o = true,
  l = true,
  c = true,
}

-- Indenting
vim.o.breakindent = true -- Maintain indent on wrapping lines
vim.o.autoindent = true -- always set autoindenting on
vim.o.copyindent = true -- copy the previous indentation on autoindenting
vim.o.smartindent = true -- Number of spaces to use for each step of (auto)indent.
vim.o.shiftwidth = 4 -- Number of spaces for each indent
vim.o.shiftround = true -- use multiple of shiftwidth when indenting with '<' and '>'
vim.o.softtabstop = 4
vim.o.tabstop = 4
vim.o.smarttab = true -- insert tabs on the start of a line according to shiftwidth, not tabstop
vim.o.expandtab = true -- Tab changes to spaces. Format with :retab
vim.opt.indentkeys:remove '0#'
vim.opt.indentkeys:remove '<:>'

-- Allow clipboard copy paste in neovim
keymap('', '<D-v>', '+p<CR>', opts.no_remap_silent)
keymap('!', '<D-v>', '<C-R>+', opts.no_remap_silent)
tnoremap('<D-v>', '<C-R>+', true)
vnoremap('<D-v>', '<C-R>+', true)

vim.cmd [[
" hi ColorColumn ctermbg=238 guibg=lightgrey
" let &t_SI = "\<Esc>]50;CursorShape=1\x7"
" let &t_SR = "\<Esc>]50;CursorShape=2\x7"
set guicursor+=i:blinkon1
]]
--
-- Abbreviations
vim.cmd [[
inoreabbrev seperate separate
inoreabbrev dont don't
inoreabbrev rbm # TODO: remove before merging
inoreabbrev cbm # TODO: change before merging
inoreabbrev ubm # TODO: uncomment before merging
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
nnoremap <c-f> :RipGrepCWORD!<Space>
vnoremap <c-f> :RipGrepCWORDVisual!<cr>
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

-- disable some builtin vim plugins
local default_plugins = {
  '2html_plugin',
  'getscript',
  'getscriptPlugin',
  'gzip',
  'logipat',
  'matchit',
  'matchparen',
  'netrw',
  'netrwFileHandlers',
  'netrwPlugin',
  'netrwSettings',
  'rrhelper',
  'spellfile_plugin',
  'tar',
  'tarPlugin',
  'vimball',
  'vimballPlugin',
  'zip',
  'zipPlugin',
}
for _, plugin in pairs(default_plugins) do
  vim.g['loaded_' .. plugin] = 1
end

local kube_config_pattern = [[.*\.kube/config]]
vim.filetype.add {
  extension = { hcl = 'terraform', tfvars = 'terraform' },
  pattern = {
    ['.*/templates/.*%.yaml'] = {
      function()
        if vim.fn.search('{{.+}}', 'nw') then
          return 'gotmpl'
        end
      end,
      { priority = 200 },
    },
    ['.*Jenkinsfile.*'] = 'groovy',
    ['.*/tasks/.*%.ya?ml'] = { 'yaml.ansible', { priority = 201 } },
    ['.*/playbooks?/.*%.ya?ml'] = { 'yaml.ansible', { priority = 201 } },
    ['playbook%.ya?ml'] = { 'yaml.ansible', { priority = 201 } },
    [kube_config_pattern] = 'yaml',
  },
}
