-- leader keys
vim.g.mapleader = ' '

local no_remap_opt        = { noremap = true }
local no_remap_expr_opt   = { expr = true, noremap = true }
local no_remap_silent_opt = { silent = true, noremap = true }
local remap_opt           = { noremap = false }

local keymap = vim.api.nvim_set_keymap

-- Select all
keymap('n', '<C-a>', 'gg^<S-v>G$', no_remap_opt)

-- Map 0 to first non-blank character
keymap('n', '0', '^', no_remap_opt)

-- Move to the end of the line
keymap('n', 'L', '$ze10zl', no_remap_opt)
keymap('v', 'L', '$', no_remap_opt)
keymap('n', 'H', '0zs10zh', no_remap_opt)
keymap('v', 'H', '0', no_remap_opt)

-- indent/unindent visual mode selection with tab/shift+tab
keymap('v', '<tab>', '>gv', remap_opt)
keymap('v', '<s-tab>', '<gv', remap_opt)

-- Copy number of lines and paste below
keymap('n', '<leader>cp', ":<c-u>exe 'normal! y' . (v:count == 0 ? 1 : v:count) . 'j' . (v:count == 0 ? 1 : v:count) . 'jo<C-v><Esc>p'<cr>", no_remap_opt)

-- Windows mappings
keymap('n', '<Leader><Leader>', '<C-^>', no_remap_opt)
keymap('n', '<tab>', '<c-w>w', no_remap_opt)
keymap('n', '<c-w><c-c>', '<c-w>c', no_remap_opt)
keymap('n', '<leader>n', ':bn<cr>', no_remap_opt)
keymap('n', '<c-w>v', ':vnew<cr>', no_remap_opt)
keymap('n', '<c-w>s', ':new<cr>', no_remap_opt)
keymap('n', '<c-w>e', ':enew<cr>', no_remap_opt)
keymap('n', '<C-J>', '<C-W><C-J>', no_remap_opt)
keymap('n', '<C-K>', '<C-W><C-K>', no_remap_opt)
keymap('n', '<C-L>', '<C-W><C-L>', no_remap_opt)
keymap('n', '<C-H>', '<C-W><C-H>', no_remap_opt)

-- Run macro
keymap('n', 'Q', '@q', no_remap_opt)

-- Paste in insert mode
keymap('i', '<c-v>', '<c-r>', no_remap_opt)

-- Quickfix
keymap("n", "]q", ":cnext<cr>zz", no_remap_opt)
keymap("n", "[q", ":cprev<cr>zz", no_remap_opt)
keymap("n", "]l", ":lnext<cr>zz", no_remap_opt)
keymap("n", "[l", ":lprev<cr>zz", no_remap_opt)

-- This creates a new line of '=' signs the same length of the line
keymap('n', '<leader>=', "yypVr=", no_remap_opt)

-- Map dp and dg with leader for diffput and diffget
keymap("n", "<leader>dp", ":diffput<cr>", no_remap_opt)
keymap("n", "<leader>dg", ":diffget<cr>", no_remap_opt)
keymap("n", "<leader>dn", ":windo diffthis<cr>", no_remap_opt)
keymap("n", "<leader>df", ":windo diffoff<cr>", no_remap_opt)

-- Map enter to no highlight
keymap("n", "<CR>", ":nohlsearch<CR><CR>", no_remap_silent_opt)

-- Set mouse=v mapping
keymap("n", "<leader>ma", ":set mouse=a<cr>", no_remap_opt)
keymap("n", "<leader>mv", ":set mouse=v<cr>", no_remap_opt)


-- Exit mappings
keymap("i", "jk", '<esc>', no_remap_opt)
keymap("n", "<leader>qq", ':qall<cr>', no_remap_silent_opt)

-- Search mappings
keymap("n", "*", ':execute "normal! *N"<cr>', no_remap_silent_opt)
keymap("n", "#", ':execute "normal! #n"<cr>', no_remap_silent_opt)
keymap("n", "n", "'Nn'[v:searchforward]", no_remap_expr_opt)
keymap("x", "n", "'Nn'[v:searchforward]", no_remap_expr_opt)
keymap("o", "n", "'Nn'[v:searchforward]", no_remap_expr_opt)
keymap("n", "N", "'nN'[v:searchforward]", no_remap_expr_opt)
keymap("x", "N", "'nN'[v:searchforward]", no_remap_expr_opt)
keymap("o", "N", "'nN'[v:searchforward]", no_remap_expr_opt)
-- Search visually selected text with // or * or #
keymap("v", "//", "y/\\V<C-R>=escape(@\",'/\\')<CR><CR>", no_remap_opt)
vim.cmd [[
function! StarSearch(cmdtype) abort
  let old_reg=getreg('"')
  let old_regtype=getregtype('"')
  norm! gvy
  let @/ = '\V' . substitute(escape(@", a:cmdtype . '\.*$^~['), '\_s\+', '\\_s\\+', 'g')
  norm! gVzv
  call setreg('"', old_reg, old_regtype)
endfunction
]]

-- local function star_search(cmdtype)
--   local old_reg = vim.fn.getreg('"')
--   local old_regtype = vim.fn.getregtype('"')
--   vim.cmd("norm! gvy")
--   vim.cmd [[let @/ = '\V' . substitute(escape(@", cmdtype . '\.*$^~['), '\_s\+', '\\_s\\+', 'g')]]
--   vim.cmd [[norm! gVzv]]
--   vim.fn.setreg('"', old_reg, old_regtype)
--   vim.cmd [[exe 'norm! ' . cmdtype . '<c-r>@/<cr><cr>']]
-- end

-- vim.keymap.set('v', '*', function()
--   return star_search('*')
-- end)

keymap("v", "*", ":call StarSearch('/')<CR>/<C-R>=@/<CR><CR>", no_remap_opt)
keymap("v", "#", ":call StarSearch('?')<CR>?<C-R>=@/<CR><CR>", no_remap_opt)


-- Map - to move a line down and _ a line up
keymap("n", "-", [["ldd$"lp]], no_remap_opt)
keymap("n", "_", [["ldd2k"lp]], no_remap_opt)

-- Copy entire file to clipboard
keymap("n", "Y", ':%y+<cr>', no_remap_opt)


-- Copy file path to clipboard
keymap("n", "<leader>cfp", [[:let @+ = expand('%')<cr>:echo   "Copied file path " . expand('%')<cr>]], no_remap_silent_opt)
keymap("n", "<leader>cap", [[:let @+ = expand('%:p')<cr>:echo "Copied file path " . expand('%:p')<cr>]], no_remap_silent_opt)

-- move vertically by visual line (don't skip wrapped lines)
keymap("n", "j", "gj", no_remap_opt)
keymap("n", "k", "gk", no_remap_opt)

-- Change working directory based on open file
keymap("n", "<leader>cd", ':cd %:p:h<CR>:pwd<CR>', no_remap_opt)

-- Move visually selected block
keymap("v", "J", [[:m '>+1<CR>gv=gv]], no_remap_opt)
keymap("v", "K", [[:m '<-2<CR>gv=gv]], no_remap_opt)

-- Convert all tabs to spaces
keymap("n", "<leader>ct<space>", ':retab<cr>', no_remap_opt)


-- Enable folding with the leader-f/a
keymap("n", "<leader>f", "za", no_remap_opt)
keymap("n", "<leader>caf", "zM", no_remap_opt)
keymap("n", "<leader>oaf", "zR", no_remap_opt)
-- Open level folds
keymap("n", "<leader>olf", "zazczA", no_remap_opt)

-- Change \n to new lines
keymap('n', '<leader><cr>', ':silent! %s?\\n?\r?g<bar>silent! %s?\\t?\t?g<bar>silent! %s?\\r?\r?g<cr>:noh<cr>', {})

-- Move vertically by visual line (don't skip wrapped lines)
keymap("n", "j", "gj", no_remap_opt)
keymap("n", "k", "gk", no_remap_opt)

-- Change working directory based on open file
keymap('n', '<leader>cd', ':cd %:p:h<CR>:pwd<CR>', no_remap_opt)

-- Convert all tabs to spaces
keymap("n", '<leader>ct<space>', ':retab<cr>', no_remap_opt)
-- Change every " -" with " \<cr> -" to break long lines of bash
keymap('n', [[<leader>\]], [[:.s/ -/ \\\r  -/g<cr>:noh<cr>]], no_remap_silent_opt)

-- Search and Replace
keymap('n', '<Leader>r', ':.,$s?<C-r><C-w>?<C-r><C-w>?gc<Left><Left><Left>', no_remap_opt)
keymap('v', '<leader>r', '"hy:.,$s?<C-r>h?<C-r>h?gc<left><left><left>', no_remap_opt)
keymap('v', '<leader>dab', [["hyqeq:v?\V<c-r>h?d E<cr>:let @"=@e<cr>:noh<cr>]], no_remap_opt)
keymap('v', '<leader>daa', [["hyqeq:g?\V<c-r>h?d E<cr>:let @"=@e<cr>:noh<cr>]], no_remap_opt)
keymap('v', '<leader>yab', [["hymmqeq:v?\V<c-r>h?yank E<cr>:let @"=@e<cr>`m:noh<cr>]], no_remap_opt)
keymap('v', '<leader>yaa', [["hymmqeq:g?\V<c-r>h?yank E<cr>:let @"=@e<cr>`m:noh<cr>]], no_remap_opt)

-- Paste without saving deleted reg
keymap('v', '<leader>p', '"_dP', no_remap_opt)

-- Base64 dencode
keymap('v', '<leader>46', [[c<c-r>=substitute(system('base64 --decode', @"), '\n$', '', 'g')<cr><esc>]], no_remap_silent_opt)
keymap('v', '<leader>64', [[c<c-r>=substitute(system('base64', @"), '\n$', '', 'g')<cr><esc>]], no_remap_silent_opt)

-- Vimrc edit mappings
keymap('n', '<leader>ev', [[:execute("vsplit " . '~/.config/nvim/lua/user/options.lua')<cr>]], no_remap_opt)
keymap('n', '<leader>ep', [[:execute("vsplit " . '~/.config/nvim/lua/user/plugins.lua')<cr>]], no_remap_opt)

-- Delete current buffer
keymap('n', '<leader>bd', ':bp <bar> bw #<cr>', no_remap_silent_opt)
-- Close current buffer
keymap('n', '<leader>bc', ':close<cr>', no_remap_silent_opt)

-- Highlight last inserted text
keymap('n', 'gV', '`[v`]', no_remap_opt)

vim.cmd [[
function! s:ChangeIndentNum() abort
  call inputsave()
  let the_num = str2nr(input('Enter new indent: '))
  call inputrestore()
  exe 'set shiftwidth=' . the_num
  exe 'set softtabstop=' . the_num
  exe 'set tabstop=' . the_num
endfunction
nnoremap cii :<C-u>call <SID>ChangeIndentNum()<CR>
]]

vim.cmd [[
" Every parameter in its own line
function SplitParamLines() abort
  let f_line_num = line('.')
  let indent_length = indent(f_line_num)
  exe "normal! 0f(a\<cr>\<esc>"
  exe ".s/\s*,/,\r" . repeat(' ', indent_length + &shiftwidth - 1) . '/g'
  nohlsearch
  exe "normal! 0t)a\<cr>\<esc>"
endfunction
nnoremap <silent> <leader>( :call SplitParamLines()<cr>
]]

-- Diff with last save function
vim.cmd [[
function! s:DiffWithSaved()
  let filetype=&ft
  diffthis
  vnew | r # | normal! 1Gdd
  exe 'setlocal bt=nofile bh=wipe nobl noswf ro foldlevel=999 ft=' . filetype
  diffthis
  nnoremap <buffer> q :bd!<cr>
  augroup ShutDownDiffOnLeave
    autocmd! * <buffer>
    autocmd BufDelete,BufUnload,BufWipeout <buffer> wincmd p | diffoff |
          \wincmd p
  augroup END

  wincmd p
endfunction
com! DiffSaved call s:DiffWithSaved()
nnoremap <leader>ds :DiffSaved<cr>
]]
