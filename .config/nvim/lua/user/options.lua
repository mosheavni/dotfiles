vim.cmd [[
if has('vim_starting')
  if has('syntax') && !exists('g:syntax_on')
    syntax enable
  endif
endif
]]

vim.opt.compatible = false

-- disable legacy vim filetype detection in favor of new lua based from neovim
vim.g.do_filetype_lua    = true
vim.g.did_load_filetypes = false

if vim.fn.has('nvim') == 1 then
  vim.opt.cursorcolumn = true
  vim.opt.cursorline   = true -- Add highlight behind current line
  vim.opt.shortmess:append { c = true, l = false, q = false, S = false }
  vim.opt.list = true
  vim.opt.listchars = { tab = '┆·', trail = '·', precedes = '', extends = '', eol = '↲', }
  -- set lcscope=tab:┆·,trail:·,precedes:,extends:
  vim.opt.fillchars = { vert = '|', fold = '·' }
  vim.opt.emoji = false
end

vim.opt.number         = true -- Show current line number
vim.opt.relativenumber = true -- Show relative line numbers
vim.opt.linebreak      = true -- Avoid wrapping a line in the middle of a word.
vim.opt.wrap           = true -- Wrap long lines
vim.opt.hlsearch       = true -- highlight reg. ex. in @/ register
vim.opt.incsearch      = true -- Search as characters are typed
vim.opt.inccommand     = "split" -- Incremental search and replace with small split window
vim.opt.ignorecase     = true -- Search case insensitive...
vim.opt.smartcase      = true -- ignore case if search pattern is all lowercase, case-sensitive otherwise
vim.opt.autoread       = true -- Re-read file if it was changed from the outside
vim.opt.scrolloff      = 7 -- When about to scroll page, see 7 lines below cursor
vim.opt.cmdheight      = 2 -- Height of the command bar
vim.opt.hidden         = true -- Hide buffer if abandoned
vim.opt.showmatch      = true -- When closing a bracket (like {}), show the enclosing
vim.opt.splitbelow     = true -- Horizontaly plitted windows open below
vim.opt.splitright     = true -- Vertically plitted windows open below bracket for a brief second
vim.opt.startofline    = false -- Stop certain movements from always going to the first character of a line.
vim.opt.confirm        = true -- Prompt confirmation if exiting unsaved file
vim.opt.lazyredraw     = true -- redraw only when we need to.
vim.opt.swapfile       = false
vim.opt.backup         = false
vim.opt.writebackup    = false
vim.opt.wildmenu       = true -- Displays a menu on autocomplete
vim.opt.wildmode       = { 'longest:full', 'full' } -- Command-line completion mode
vim.opt.title          = true -- Changes the iterm title
vim.opt.showcmd        = true
vim.opt.guifont        = ':h'
vim.opt.mouse          = 'a'
vim.opt.undofile       = true -- Enables saving undo history to a file
vim.opt.colorcolumn    = '80' -- Mark where are 80 characters to start breaking line
vim.opt.textwidth      = 80
vim.opt.fileencodings  = { "utf-8", "cp1251" }
vim.opt.encoding       = 'utf-8'
vim.opt.visualbell     = true -- Use visual bell instead of beeping
-- Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable delays and poor user experience.
vim.opt.updatetime     = 300
-- Ignore node_modules and other dirs
vim.opt.wildignore:append { '**/node_modules/**', '.hg', '.git', '.svn', '*.DS_Store', '*.pyc' }
vim.opt.path:append { '**' }

if vim.v.version > 703 and vim.v.version == 703 or vim.fn.has('patch541') == 1 then
  vim.opt.formatoptions:append { j = true, t = false, r = true, o = true, l = true } -- j = Delete comment character when joining commented lines. t = auto break long lines
end


-- Set shell
if vim.fn.executable('/bin/zsh') == 1 then
  vim.opt.shell = '/bin/zsh -l'
elseif vim.fn.executable('/bin/bash') == 1 then
  vim.opt.shell = '/bin/bash'
else
  vim.opt.shell = '/bin/sh'
end


vim.cmd [[hi ColorColumn ctermbg=238 guibg=lightgrey]]
