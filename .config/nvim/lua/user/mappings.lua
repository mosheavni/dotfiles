-- leader key - before mapping lsp maps
vim.g.mapleader = ' '

local utils = require 'user.utils'
local opts = utils.map_opts
local keymap = utils.keymap

-- Select all file visually
keymap('n', '<leader>sa', 'gg^<S-v>G$', opts.no_remap)

-- Map 0 to first non-blank character
keymap('n', '0', '^', opts.no_remap)

-- Move to the end of the line
keymap('n', 'L', '$ze10zl', opts.no_remap)
keymap('v', 'L', '$', opts.no_remap)
keymap('n', 'H', '0zs10zh', opts.no_remap)
keymap('v', 'H', '0', opts.no_remap)

-- indent/unindent visual mode selection with tab/shift+tab
keymap('v', '<tab>', '>gv', opts.remap)
keymap('v', '<s-tab>', '<gv', opts.remap)

-- Copy number of lines and paste below
keymap('n', '<leader>cp', ":<c-u>exe 'normal! y' . (v:count == 0 ? 1 : v:count) . 'j' . (v:count == 0 ? 1 : v:count) . 'jo<C-v><Esc>p'<cr>", opts.no_remap)

-- Windows mappings
keymap('n', '<Leader><Leader>', '<C-^>', opts.no_remap)
keymap('n', '<tab>', '<c-w>w', opts.no_remap)
keymap('n', '<c-w><c-c>', '<c-w>c', opts.no_remap)
keymap('n', '<leader>bn', ':bn<cr>', opts.no_remap)
keymap('n', '<c-w>v', ':vnew<cr>', opts.no_remap)
keymap('n', '<c-w>s', ':new<cr>', opts.no_remap)
keymap('n', '<c-w>e', ':enew<cr>', opts.no_remap)
keymap('n', '<C-J>', '<C-W><C-J>', opts.no_remap)
keymap('n', '<C-K>', '<C-W><C-K>', opts.no_remap)
keymap('n', '<C-L>', '<C-W><C-L>', opts.no_remap)
keymap('n', '<C-H>', '<C-W><C-H>', opts.no_remap)

-- entire file text-object
keymap('o', 'ae', '<cmd>normal! ggVG<CR>', opts.no_remap_silent)

-- Run macro
keymap('n', 'Q', '@q', opts.no_remap)

-- Paste in insert mode
keymap('i', '<c-v>', '<c-r>', opts.no_remap)

-- Quickfix
keymap('n', ']q', ':cnext<cr>zz', opts.no_remap)
keymap('n', '[q', ':cprev<cr>zz', opts.no_remap)
keymap('n', ']l', ':lnext<cr>zz', opts.no_remap)
keymap('n', '[l', ':lprev<cr>zz', opts.no_remap)

-- This creates a new line of '=' signs the same length of the line
keymap('n', '<leader>=', 'yypVr=', opts.no_remap)

-- Map dp and dg with leader for diffput and diffget
keymap('n', '<leader>dp', ':diffput<cr>', opts.no_remap)
keymap('n', '<leader>dg', ':diffget<cr>', opts.no_remap)
keymap('n', '<leader>dn', ':windo diffthis<cr>', opts.no_remap)
keymap('n', '<leader>df', ':bufdo diffoff<cr>', opts.no_remap)

-- Map enter to no highlight
keymap('n', '<CR>', ':nohlsearch<CR><CR>', opts.no_remap_silent)

-- Set mouse=v mapping
keymap('n', '<leader>ma', ':set mouse=a<cr>', opts.no_remap)
keymap('n', '<leader>mv', ':set mouse=v<cr>', opts.no_remap)

-- Exit mappings
keymap('i', 'jk', '<esc>', opts.no_remap)
keymap('n', '<leader>qq', ':qall<cr>', opts.no_remap_silent)

-- Search mappings
keymap('n', '*', ':execute "normal! *N"<cr>', opts.no_remap_silent)
keymap('n', '#', ':execute "normal! #n"<cr>', opts.no_remap_silent)
keymap('n', 'n', "'Nn'[v:searchforward]", opts.no_remap_expr)
keymap('x', 'n', "'Nn'[v:searchforward]", opts.no_remap_expr)
keymap('o', 'n', "'Nn'[v:searchforward]", opts.no_remap_expr)
keymap('n', 'N', "'nN'[v:searchforward]", opts.no_remap_expr)
keymap('x', 'N', "'nN'[v:searchforward]", opts.no_remap_expr)
keymap('o', 'N', "'nN'[v:searchforward]", opts.no_remap_expr)
-- Search visually selected text with // or * or #
keymap('v', '//', "y/\\V<C-R>=escape(@\",'/\\')<CR><CR>", opts.no_remap)
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

keymap('v', '*', ":call StarSearch('/')<CR>/<C-R>=@/<CR><CR>", opts.no_remap)
keymap('v', '#', ":call StarSearch('?')<CR>?<C-R>=@/<CR><CR>", opts.no_remap)

-- Map - to move a line down and _ a line up
keymap('n', '-', [["ldd$"lp]], opts.no_remap)
keymap('n', '_', [["ldd2k"lp]], opts.no_remap)

-- Copy entire file to clipboard
keymap('n', 'Y', ':%y+<cr>', opts.no_remap)

-- Copy file path to clipboard
keymap('n', '<leader>cfp', [[:let @+ = expand('%')<cr>:echo   "Copied file path " . expand('%')<cr>]], opts.no_remap_silent)
keymap('n', '<leader>cfa', [[:let @+ = expand('%:p')<cr>:echo "Copied file path " . expand('%:p')<cr>]], opts.no_remap_silent)

-- Change working directory based on open file
keymap('n', '<leader>cd', ':cd %:p:h<CR>:pwd<CR>', opts.no_remap)

-- Move visually selected block
keymap('v', 'J', [[:m '>+1<CR>gv=gv]], opts.no_remap)
keymap('v', 'K', [[:m '<-2<CR>gv=gv]], opts.no_remap)

-- Convert all tabs to spaces
keymap('n', '<leader>ct<space>', ':retab<cr>', opts.no_remap)

-- Enable folding with the leader-f/a
keymap('n', '<leader>ff', 'za', opts.no_remap)
keymap('n', '<leader>fc', 'zM', opts.no_remap)
keymap('n', '<leader>fo', 'zR', opts.no_remap)
-- Open level folds
keymap('n', '<leader>fl', 'zazczA', opts.no_remap)

-- Change \n to new lines
keymap('n', '<leader><cr>', [[:silent! %s?\\n?\r?g<bar>silent! %s?\\t?\t?g<bar>silent! %s?\\r?\r?g<cr>:noh<cr>]], {})

-- Move vertically by visual line (don't skip wrapped lines)
keymap('n', 'j', 'gj', opts.no_remap)
keymap('n', 'k', 'gk', opts.no_remap)

-- Change working directory based on open file
keymap('n', '<leader>cd', ':cd %:p:h<CR>:pwd<CR>', opts.no_remap)

-- Convert all tabs to spaces
keymap('n', '<leader>ct<space>', ':retab<cr>', opts.no_remap)
-- Change every " -" with " \<cr> -" to break long lines of bash
keymap('n', [[<leader>\]], [[:.s/ -/ \\\r  -/g<cr>:noh<cr>]], opts.no_remap_silent)

-- Search and Replace
keymap('n', '<Leader>r', ':.,$s?<C-r><C-w>?<C-r><C-w>?gc<Left><Left><Left>', opts.no_remap)
keymap('v', '<leader>r', '"hy:.,$s?<C-r>h?<C-r>h?gc<left><left><left>', opts.no_remap)
keymap('v', '<leader>dab', [["hyqeq:v?\V<c-r>h?d E<cr>:let @"=@e<cr>:noh<cr>]], opts.no_remap)
keymap('v', '<leader>daa', [["hyqeq:g?\V<c-r>h?d E<cr>:let @"=@e<cr>:noh<cr>]], opts.no_remap)
keymap('v', '<leader>yab', [["hymmqeq:v?\V<c-r>h?yank E<cr>:let @"=@e<cr>`m:noh<cr>]], opts.no_remap)
keymap('v', '<leader>yaa', [["hymmqeq:g?\V<c-r>h?yank E<cr>:let @"=@e<cr>`m:noh<cr>]], opts.no_remap)

-- Paste without saving deleted reg
keymap('v', '<leader>p', '"_dP', opts.no_remap)

-- Base64 dencode
keymap('v', '<leader>46', [[c<c-r>=substitute(system('base64 --decode', @"), '\n$', '', 'g')<cr><esc>]], opts.no_remap_silent)
keymap('v', '<leader>64', [[c<c-r>=substitute(system('base64', @"), '\n$', '', 'g')<cr><esc>]], opts.no_remap_silent)

-- Vimrc edit mappings
keymap('n', '<leader>ev', [[:execute("vsplit " . '~/.config/nvim/lua/user/options.lua')<cr>]], opts.no_remap)
keymap('n', '<leader>ep', [[:execute("vsplit " . '~/.config/nvim/lua/user/plugins.lua')<cr>]], opts.no_remap)

-- Delete current buffer
keymap('n', '<leader>bd', ':bp <bar> bw #<cr>', opts.no_remap_silent)
-- Close current buffer
keymap('n', '<leader>bc', ':close<cr>', opts.no_remap_silent)

-- Highlight last inserted text
keymap('n', 'gV', '`[v`]', opts.no_remap)

-- Change document indentation number
vim.cmd [[
function! s:ChangeIndentNum() abort
  call inputsave()
  let the_num = str2nr(input('Enter new indent: '))
  call inputrestore()
  exe 'setlocal shiftwidth=' . the_num
  exe 'setlocal softtabstop=' . the_num
  exe 'setlocal tabstop=' . the_num
endfunction
nnoremap cii :<C-u>call <SID>ChangeIndentNum()<CR>
]]

-- Every parameter in its own line
vim.cmd [[
function! SplitParamLines() abort
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

-- schema-select
keymap('n', '<leader>cc', ":lua require('user.select-schema').select()<cr>", opts.no_remap_silent)

-- Visual calculator -- TODO: finish...
function VisualCalculator()
  local vis_start = vim.api.nvim_buf_get_mark(0, '<')
  local vis_end = vim.api.nvim_buf_get_mark(0, '>')
  P(vis_start)
  P(vis_end)
  P(vim.api.nvim_buf_get_text(0, vis_start[1], vis_start[2], vis_end[1], vis_end[2], {}))
end

vim.keymap.set('v', '<c-r>', function()
  return VisualCalculator()
end, { expr = false })
