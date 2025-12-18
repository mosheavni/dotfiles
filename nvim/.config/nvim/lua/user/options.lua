vim.o.compatible = false
vim.g.python3_host_prog = 'python3'
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- disable legacy vim filetype detection in favor of new lua based from neovim
-- vim.g.do_filetype_lua = 1
-- vim.g.did_load_filetypes = 0

-- titlestring
vim.cmd [[
  function! CleanTitle()
    return "💻 nvim: " . substitute(getcwd(), $HOME . '/\(Repos/\)\?', '', '')
  endfunction
]]
vim.o.titlestring = '%{CleanTitle()}'

vim.o.title = true -- Changes the wezterm title
vim.o.cursorcolumn = true
vim.o.cursorline = true -- Add highlight behind current line
vim.opt.shortmess:append { c = true, l = false, q = false, S = false, C = true, I = true }
vim.o.list = true -- Show some invisible characters (tabs...
vim.opt.listchars = {
  -- trail = '·',
  eol = '↲',
  extends = '',
  precedes = '',
  tab = '┆·',
  -- leadmultispace = '│ ',
}

-- set lcscope=tab:┆·,trail:·,precedes:,extends:
vim.opt.fillchars = {
  vert = '│',
  fold = ' ',
  foldopen = '',
  foldclose = '',
  foldsep = ' ',
  foldinner = ' ',
  diff = ' ',
  eob = ' ',
}
vim.o.shada = [[!,'50,s100,h]]
-- vim.opt.foldcolumn = '1'
vim.o.emoji = true
-- go to previous/next line with h,l,left arrow and right arrow
-- when cursor reaches end/beginning of line
-- opt.whichwrap:append '<>[]hl'
vim.opt.diffopt = {
  'internal',
  'filler',
  'closeoff',
  'indent-heuristic',
  'linematch:60',
  'vertical',
  'algorithm:histogram',
  'inline:char',
}

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
vim.o.pumborder = 'rounded' -- Popup border style
vim.o.pumblend = 40 -- Popup blend
vim.o.confirm = true -- Prompt confirmation if exiting unsaved file
vim.o.lazyredraw = false -- redraw only when we need to.
vim.o.swapfile = false
vim.o.backup = false
vim.o.backupdir = vim.fn.stdpath 'state' .. '/backup'
vim.o.writebackup = false
vim.o.wildmenu = true -- Displays a menu on autocomplete
vim.opt.wildoptions:append { 'fuzzy', 'pum' }
vim.opt.wildmode = { 'longest:full', 'full' } -- Command-line completion mode
vim.opt.completeopt = 'menu,menuone,noselect,noinsert,popup'
vim.o.previewheight = 15
vim.o.laststatus = 3 -- Global statusline, only one for all buffers
vim.o.showcmd = true
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
vim.o.history = 10000
vim.o.termguicolors = true
vim.o.signcolumn = 'yes'
vim.o.virtualedit = 'block' -- Allow cursor to move to the end of the line
vim.opt.nrformats:append 'blank'
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
vim.opt.foldmethod = 'expr'
vim.o.foldlevel = 999
vim.o.foldlevelstart = 99
vim.o.foldcolumn = '1' -- '0' is not bad
local function fold_virt_text(result, s, lnum, coloff)
  if not coloff then
    coloff = 0
  end
  local text = ''
  local hl
  for i = 1, #s do
    local char = s:sub(i, i)
    local hls = vim.treesitter.get_captures_at_pos(0, lnum, coloff + i - 1)
    local _hl = hls[#hls]
    if _hl then
      local new_hl = '@' .. _hl.capture
      if new_hl ~= hl then
        table.insert(result, { text, hl })
        text = ''
        hl = nil
      end
      text = text .. char
      hl = new_hl
    else
      text = text .. char
    end
  end
  table.insert(result, { text, hl })
end
function _G.custom_foldtext()
  local start = vim.fn.getline(vim.v.foldstart):gsub('\t', string.rep(' ', vim.o.tabstop))
  local end_str = vim.fn.getline(vim.v.foldend)
  local end_ = vim.trim(end_str)
  local result = {}
  fold_virt_text(result, start, vim.v.foldstart - 1)
  table.insert(result, { ' ⋯ ', 'Delimiter' })
  fold_virt_text(result, end_, vim.v.foldend - 1, #(end_str:match '^(%s+)' or ''))
  return result
end
vim.opt.foldtext = 'v:lua.custom_foldtext()'

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
-- t = Auto-wrap text using 'textwidth'
vim.opt.formatoptions:append {
  c = true,
  j = true,
  l = true,
  o = true,
  r = true,
  t = true,
}

-- Indenting
vim.o.breakindent = true -- Maintain indent on wrapping lines
vim.o.autoindent = true -- always set autoindenting on
vim.o.copyindent = true -- copy the previous indentation on autoindenting
vim.o.smartindent = true -- Number of spaces to use for each step of (auto)indent.
vim.o.shiftwidth = 2 -- Number of spaces for each indent
vim.o.shiftround = true -- use multiple of shiftwidth when indenting with '<' and '>'
vim.o.softtabstop = 2
vim.o.tabstop = 2
vim.o.smarttab = true -- insert tabs on the start of a line according to shiftwidth, not tabstop
vim.o.expandtab = true -- Tab changes to spaces. Format with :retab
vim.opt.indentkeys:remove '0#'
vim.opt.indentkeys:remove '<:>'

local kube_config_pattern = [[.*\.kube/config]]
vim.filetype.add {
  extension = { tfvars = 'terraform' },
  filename = {
    Brewfile = 'ruby',
  },
  pattern = {
    ['.*/templates/.*%.yaml'] = {
      function()
        if vim.fn.search('{{.+}}', 'nw') then
          return 'helm'
        end
      end,
      { priority = 200 },
    },
    ['.*Jenkinsfile.*'] = 'groovy',
    [kube_config_pattern] = 'yaml',
    ['.*'] = function()
      -- loop through the first 20 lines of the file and search a line
      -- that starts with kind: or apiVersion: to determine the filetype is yaml
      for i = 1, 20 do
        local line = vim.fn.getline(i)
        if line:match '^kind:' or line:match '^apiVersion:' then
          return 'yaml'
        end
      end
    end,
  },
}

require('user.input').setup()

-----------
-- EXTUI --
-----------
-- require('vim._extui').enable { enable = true, msg = { target = 'cmd' } }
