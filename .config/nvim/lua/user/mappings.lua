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

-- Format groovy map
vim.cmd [=[
function! s:FormatGroovyMap(surround_words)
  silent! %s?\]?\r]?g
  silent! %s/, /,\r/g
  silent! %s?\[?[\r?g
  silent! %s?:\[?:[?g
  silent! %s?\v([^\s]):([^\s])?\1: \2?
  silent! %s?:\[?: [?
  if a:surround_words != "!"
    silent! %s/\v(.*: )([^,\[\]]*)(,?)$/\1"\2"\3/g
  endif
  normal! gg=G
  noh
endfunction
com! -bang FormatGroovyMap call s:FormatGroovyMap("<bang>")
]=]

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
keymap('v', 'ae', '<esc>gg0vG$', opts.no_remap)

-- Run and edit macros
for _, key in pairs { 'Q', 'X' } do
  keymap('n', key, '@' .. key:lower(), opts.no_remap)
  keymap('n', '<leader>' .. key, ":<c-u><c-r><c-r>='let @" .. key:lower() .. " = '. string(getreg('" .. key:lower() .. "'))<cr><c-f><left>", opts.no_remap)
end

-- keymap('n', 'Q', '@q', opts.no_remap)
-- keymap('n', '<leader>Q', ":<c-u><c-r><c-r>='let @q = '. string(getreg('q'))<cr><c-f><left>", opts.no_remap)

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

-- Terminal
keymap('t', '<Esc>', [[<C-\><C-n>]], opts.no_remap)

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
keymap('n', '<leader>cfd', [[:let @+ = expand('%:p:h')<cr>:echo "Copied file path " . expand('%:p:h')<cr>]], opts.no_remap_silent)

-- Copy and paste to/from system clipboard
keymap('n', 'cp', '"+y', {})
keymap('n', 'cP', '"+yy', {})
keymap('v', 'cp', '"+y', {})
keymap('n', 'cv', '"+p', {})

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
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", opts.expr_silent)
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", opts.expr_silent)

-- Scroll one line
keymap('n', '<PageUp>', '<c-y>', opts.no_remap_silent)
keymap('n', '<PageDown>', '<c-e>', opts.no_remap_silent)

-- Change working directory based on open file
keymap('n', '<leader>cd', ':cd %:p:h<CR>:pwd<CR>', opts.no_remap)

-- Convert all tabs to spaces
keymap('n', '<leader>ct<space>', ':retab<cr>', opts.no_remap)
-- Change every " -" with " \<cr> -" to break long lines of bash
keymap('n', [[<leader>\]], [[:.s/ -/ \\\r  -/g<cr>:noh<cr>]], opts.no_remap_silent)

-- Search and Replace
keymap('n', '<Leader>r', ':.,$s?\\V<C-r><C-w>?<C-r><C-w>?gc<Left><Left><Left>', opts.no_remap)
keymap('v', '<leader>r', '"hy:.,$s?\\V<C-r>h?<C-r>h?gc<left><left><left>', opts.no_remap)
keymap('v', '<leader>dab', [["hyqeq:v?\V<c-r>h?d E<cr>:let @"=@e<cr>:noh<cr>]], vim.tbl_extend('force', opts.no_remap, { desc = 'Delete all but ...' }))
keymap('v', '<leader>daa', [["hyqeq:g?\V<c-r>h?d E<cr>:let @"=@e<cr>:noh<cr>]], opts.no_remap)
keymap('v', '<leader>yab', [["hymmqeq:v?\V<c-r>h?yank E<cr>:let @"=@e<cr>`m:noh<cr>]], opts.no_remap)
keymap('v', '<leader>yaa', [["hymmqeq:g?\V<c-r>h?yank E<cr>:let @"=@e<cr>`m:noh<cr>]], opts.no_remap)

-- Paste without saving deleted reg
keymap('n', '<leader>p', '<Plug>ReplaceWithRegisterOperator', {})
keymap('n', '<leader>P', '<Plug>ReplaceWithRegisterLine', {})
keymap('x', '<leader>P', '<Plug>ReplaceWithRegisterVisual', {})

-- Base64 dencode
keymap('v', '<leader>46', [[c<c-r>=substitute(system('base64 --decode', @"), '\n$', '', 'g')<cr><esc>]], opts.no_remap_silent)
keymap('v', '<leader>64', [[c<c-r>=substitute(system('base64', @"), '\n$', '', 'g')<cr><esc>]], opts.no_remap_silent)

-- Vimrc edit mappings
keymap('n', '<leader>ev', [[:execute("vsplit " . '~/.config/nvim/lua/user/options.lua')<cr>]], opts.no_remap)
keymap('n', '<leader>ep', [[:execute("vsplit " . '~/.config/nvim/lua/user/plugins.lua')<cr>]], opts.no_remap)
keymap('n', '<leader>ec', [[:execute("vsplit " . '~/.config/nvim/lua/user/plugin-configs.lua')<cr>]], opts.no_remap)
keymap('n', '<leader>el', [[:execute("vsplit " . '~/.config/nvim/lua/user/lsp/config.lua')<cr>]], opts.no_remap)
keymap('n', '<leader>em', [[:execute("vsplit " . '~/.config/nvim/lua/user/mappings.lua')<cr>]], opts.no_remap)

-- Delete current buffer
keymap('n', '<leader>bd', '<cmd>BDelete this<cr>', opts.no_remap_silent)
-- Close current buffer
keymap('n', '<leader>bc', ':close<cr>', opts.no_remap_silent)

-- Highlight last inserted text
keymap('n', 'gV', '`[v`]', opts.no_remap)

-- Yaml 2 json
vim.api.nvim_create_user_command('Yaml2Json', function()
  vim.cmd [[%!yq -ojson]]
end, {})

vim.api.nvim_create_user_command('Json2Yaml', function()
  vim.cmd [[%!yq -P]]
end, {})

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
  lefta vnew | r # | normal! 1Gdd
  exe 'setlocal bt=nofile bh=wipe nobl noswf ro foldlevel=999 ft=' . filetype
  diffthis
  nnoremap <buffer> q :bd!<cr>
  augroup ShutDownDiffOnLeave
    autocmd! * <buffer>
    autocmd BufDelete,BufUnload,BufWipeout <buffer> wincmd p | diffoff | wincmd p
  augroup END

  wincmd p
endfunction
com! DiffSaved call s:DiffWithSaved()
nnoremap <leader>ds :DiffSaved<cr>
]]

-- Visual calculator -- TODO: finish...
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
-- keymap('v', '<c-r>', function()
--   local selection = utils.get_selection()
--   local num = tonumber(selection)
--   P(selection)
--   -- return VisualCalculator()
-- end, opts.no_remap)

----------
-- Titleize --
--------------
vim.api.nvim_create_user_command('Titleize', function(options)
  local title_char = '-'
  if options.args ~= '' then
    title_char = options.args
  end
  local current_line = vim.api.nvim_get_current_line()
  local r, _ = unpack(vim.api.nvim_win_get_cursor(0))

  -- delete line
  vim.api.nvim_del_current_line()

  local top_bottom = title_char:rep(#current_line + 6)
  vim.api.nvim_buf_set_lines(0, r - 1, r - 1, false, {
    top_bottom,
    title_char:rep(2) .. ' ' .. current_line .. ' ' .. title_char:rep(2),
    top_bottom,
  })
end, { nargs = '?' })

-------------
-- AutoRun --
-------------
local attach_to_buffer = function(output_bufnr, pattern, command)
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = vim.api.nvim_create_augroup('AutoRun', { clear = true }),
    pattern = pattern,
    callback = function()
      local append_data = function(_, data)
        if data then
          vim.api.nvim_buf_set_lines(output_bufnr, -1, -1, false, data)
        end
      end
      vim.api.nvim_buf_set_lines(output_bufnr, 0, -1, false, { table.concat(command, ' ') .. ' output:' })
      vim.fn.jobstart(command, {
        stdout_buffered = true,
        on_stdout = append_data,
        on_stderr = append_data,
      })
    end,
  })
end
vim.api.nvim_create_user_command('AutoRun', function()
  local pattern = vim.fn.expand '%:p'
  vim.ui.input({ prompt = 'Command: ' }, function(command_text)
    if command_text == nil then
      return
    end
    if command_text:find [[%%]] then
      command_text = command_text:gsub('%%', vim.fn.expand '%')
    end
    local command = vim.split(command_text, ' ')
    print 'AutoRun starts now...'
    -- Open split and focus on it
    vim.cmd 'vsplit'
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_win_set_buf(win, buf)

    -- Resize
    local win_width = vim.o.columns
    local split_size = 25 * win_width / 100
    vim.cmd('vertical resize ' .. tostring(split_size))

    attach_to_buffer(tonumber(buf), pattern, command)
  end)
end, {})

------------------------
-- Plugins Management --
------------------------
vim.api.nvim_create_user_command('PluginsList', function()
  require('user.plugins-mgmt').display_awesome_plugins()
end, {})

vim.api.nvim_create_user_command('PluginsReload', function()
  require('user.plugins-mgmt').reload_plugin()
end, {})
