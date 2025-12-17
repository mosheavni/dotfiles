local map = vim.keymap.set

-- better up/down
map({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { desc = 'Down', expr = true, silent = true })
map({ 'n', 'x' }, '<Down>', "v:count == 0 ? 'gj' : 'j'", { desc = 'Down', expr = true, silent = true })
map({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { desc = 'Up', expr = true, silent = true })
map({ 'n', 'x' }, '<Up>', "v:count == 0 ? 'gk' : 'k'", { desc = 'Up', expr = true, silent = true })

-- Map 0 to first non-blank character
map({ 'n', 'v' }, '0', '^', { remap = false, desc = 'Go to the first non-blank character' })

-- Move view left or right
map('n', 'L', '5zl', { remap = false, desc = 'Move view to the right' })
map('v', 'L', '$', { remap = false, desc = 'Move view to the right' })
map('n', 'H', '5zh', { remap = false, desc = 'Move view to the left' })
map('v', 'H', '0', { remap = false, desc = 'Move view to the left' })

-- indent/unindent visual mode selection with tab/shift+tab
map('v', '<tab>', '>gv', { desc = 'Indent selected text' })
map('v', '<s-tab>', '<gv', { desc = 'Unindent selected text' })

-- command line mappings
map('c', '<c-h>', '<left>', { desc = 'Move left in command line' })
map('c', '<c-j>', '<down>', { desc = 'Move down in command line' })
map('c', '<c-k>', '<up>', { desc = 'Move up in command line' })
map('c', '<c-l>', '<right>', { desc = 'Move right in command line' })

-- Add undo break-points
map('i', ',', ',<c-g>u', { remap = false, desc = 'Add undo break point after comma' })
map('i', '.', '.<c-g>u', { remap = false, desc = 'Add undo break point after period' })
map('i', ';', ';<c-g>u', { remap = false, desc = 'Add undo break point after semicolon' })
map('i', '!', '!<c-g>u', { remap = false, desc = 'Add undo break point after exclamation' })
map('i', '?', '?<c-g>u', { remap = false, desc = 'Add undo break point after question mark' })
map('i', '(', '(<c-g>u', { remap = false, desc = 'Add undo break point after open paren' })
map('i', ')', ')<c-g>u', { remap = false, desc = 'Add undo break point after close paren' })

map('i', ';;', '<C-O>A;', { remap = false, desc = 'Add semicolon at end of line' })
map('i', ',,', '<C-O>A,', { remap = false, desc = 'Add comma at end of line' })

-- delete word on insert mode
map('i', '<C-e>', '<C-o>de', { remap = false, desc = 'Delete word after cursor' })
map('i', '<C-b>', '<C-o>db', { remap = false, desc = 'Delete word before cursor' })

map('n', 'gx', require('user.open-url').open_url_under_cursor, { remap = false, desc = 'Open url under cursor' })

-- Search for string within the visual selection
map('x', '/', '<Esc>/\\%V', { remap = false })

-- open github in browser
map({ 'v', 'n' }, '<leader>gh', require('user.gitbrowse').open, { remap = false, desc = 'Open github in browser' })

-- surround with string interpolation with motion
function _G.__surround_with_interpolation(motion)
  if motion == nil or motion == 'line' then
    vim.o.operatorfunc = 'v:lua.__surround_with_interpolation'
    return vim.fn.feedkeys 'g@'
  end
  local start = vim.api.nvim_buf_get_mark(0, '[')
  local finish = vim.api.nvim_buf_get_mark(0, ']')
  local line = vim.api.nvim_buf_get_text(0, start[1] - 1, start[2], finish[1] - 1, finish[2] + 1, {})[1]
  local new_text = { '"${' .. line .. '}"' }
  vim.api.nvim_buf_set_text(0, start[1] - 1, start[2], finish[1] - 1, finish[2] + 1, new_text)
  vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win(), { finish[1], finish[2] })
end
map('n', 'mt', _G.__surround_with_interpolation)

-- Indent block
vim.cmd [[
function! g:__align_based_on_indent(_)
  normal! v%koj$>
endfunction
]]
map('n', '<leader>gt', function()
  vim.go.operatorfunc = '__align_based_on_indent'
  return 'g@l'
end, { expr = true })

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
function! s:BasicGroovyFormat() abort
  silent! %s/\(\w\){/\1 {/gc
  silent %s?\V){?) {?gc
endfunction
com! -bang FormatGroovyMap call s:FormatGroovyMap("<bang>")
com! BasicGroovyFormat call s:BasicGroovyFormat()
]=]

-- Windows mappings
map('n', '<Leader><Leader>', '<C-^>', { remap = false, silent = true, desc = 'Switch to alternate file' })
map('n', '<tab>', '<c-w>w', { remap = false, silent = true })
map('n', '<c-w><c-c>', '<c-w>c', { remap = false, silent = true })
map('n', '<leader>bn', '<cmd>bn<cr>', { remap = false, silent = true, desc = 'Next buffer' })
map('n', '<c-w>v', ':vnew<cr>', { remap = false, silent = true, desc = 'New buffer vertically split' })
map('n', '<c-w>s', ':new<cr>', { remap = false, silent = true, desc = 'New buffer horizontally split' })
map('n', '<c-w>e', ':enew<cr>', { remap = false, silent = true, desc = 'New empty buffer' })

-- Move to window using the <ctrl> hjkl keys
map('n', '<C-h>', '<C-w>h', { remap = true, desc = 'Go to Left Window' })
map('n', '<C-j>', '<C-w>j', { remap = true, desc = 'Go to Lower Window' })
map('n', '<C-k>', '<C-w>k', { remap = true, desc = 'Go to Upper Window' })
map('n', '<C-l>', '<C-w>l', { remap = true, desc = 'Go to Right Window' })

-- Resize window using <ctrl> arrow keys
require('user.winresizer').setup()

-- entire file text-object
map('o', 'ae', '<cmd>normal! ggVG<CR>', { remap = false })
map('v', 'ae', '<esc>gg0vG$', { remap = false })
map('n', '<leader>sa', 'ggVG', { remap = false, desc = 'Visually select entire buffer' })

-- Run and edit macros
for _, key in pairs { 'Q', 'X' } do
  map('n', key, '@' .. key:lower(), { remap = false })
  map('n', '<leader>' .. key, ":<c-u><c-r><c-r>='let @" .. key:lower() .. " = '. string(getreg('" .. key:lower() .. "'))<cr><c-f><left>", { remap = false })
end

-- Quickfix and tabs
map('n', ']q', ':cnext<cr>zz', { remap = false, silent = true })
map('n', '[q', ':cprev<cr>zz', { remap = false, silent = true })
map('n', ']l', ':lnext<cr>zz', { remap = false, silent = true })
map('n', '[l', ':lprev<cr>zz', { remap = false, silent = true })
map('n', ']t', ':tabnext<cr>zz', { remap = false, silent = true })
map('n', '[t', ':tabprev<cr>zz', { remap = false, silent = true })
map('n', ']b', ':bnext<cr>', { remap = false, silent = true })
map('n', '[b', ':bprev<cr>', { remap = false, silent = true })

-- tabs
map('n', '<leader>tn', ':tabnew<cr>', { remap = false, silent = true })
map('n', '<leader>tc', ':tabclose<cr>', { remap = false, silent = true })
map('n', '<leader>th', ':-tabmove<cr>', { remap = false, silent = true })
map('n', '<leader>tl', ':+tabmove<cr>', { remap = false, silent = true })

-- This creates a new line of '=' signs the same length of the line
map('n', '<leader>=', 'yypVr=', { remap = false })

-- Map dp and dg with leader for diffput and diffget
_G.__diffput = function()
  vim.cmd [[diffput]]
end
map('n', '<leader>dp', function()
  vim.go.operatorfunc = 'v:lua.__diffput'
  return 'g@l'
end, { expr = true, desc = 'Diff put current hunk' })
_G.__diffget = function()
  vim.cmd [[diffget]]
end
map('n', '<leader>dg', function()
  vim.go.operatorfunc = 'v:lua.__diffget'
  return 'g@l'
end, { expr = true, desc = 'Diff get current line' })
map('n', '<leader>dn', ':windo diffthis<cr>', { remap = false, silent = true, desc = 'Start diff mode' })
map('n', '<leader>df', ':windo diffoff<cr>', { remap = false, silent = true, desc = 'End diff mode' })

-- Map enter to no highlight
map('n', '<CR>', '<Esc>:nohlsearch<CR><CR>', { remap = false, silent = true, desc = 'Clear search highlighting' })

-- Exit mappings
map('i', 'jk', '<esc>', { remap = false, desc = 'Exit insert mode' })
map('i', 'kj', '<esc>', { remap = false, desc = 'Exit insert mode' })
map('n', '<leader>qq', ':qall<cr>', { remap = false, silent = true, desc = 'Quit all' })

-- Search visually selected text with // or * or #
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
map('v', '*', ":call StarSearch('/')<CR>/<C-R>=@/<CR><CR>", { remap = false, silent = true })
map('v', '#', ":call StarSearch('?')<CR>?<C-R>=@/<CR><CR>", { remap = false, silent = true })

-- Terminal
map('t', '<Esc>', [[<C-\><C-n>]], { remap = false, desc = 'Exit terminal mode' })

-- Map - to move a line down and _ a line up

map('n', '-', [["ldd$"lp==]], { remap = false, desc = 'Move line down' })
map('n', '_', [["ldd2k"lp==]], { remap = false, desc = 'Move line up' })

-- Copy entire file to clipboard
map('n', 'Y', ':%y+<cr>', { remap = false, silent = true, desc = 'Copy buffer content to clipboard' })

-- Copy file path to clipboard
map('n', '<leader>cfa', function()
  local file_path = vim.fn.expand '%:p'
  vim.fn.setreg('+', file_path)
  print('Copied full file path  ' .. file_path)
end, { remap = false, silent = true, desc = 'Copy absolute file path' })
map('n', '<leader>cfd', function()
  local dir_path = vim.fn.expand '%:p:h'
  vim.fn.setreg('+', dir_path)
  print('Copied file directory path ' .. dir_path)
end, { remap = false, silent = true, desc = 'Copy file directory path' })
map('n', '<leader>cfn', function()
  local file_name = vim.fn.expand '%:t'
  vim.fn.setreg('+', file_name)
  print('Copied file name ' .. file_name)
end, { remap = false, silent = true, desc = 'Copy file name' })

-- Copy and paste to/from system clipboard
map('v', 'cp', '"+y', { desc = 'Copy to system clipboard' })
map('n', 'cP', '"+yy', { desc = 'Copy line to system clipboard' })
map('n', 'cp', '"+y', { desc = 'Copy to system clipboard' })
map('n', 'cv', '"+p', { desc = 'Paste from system clipboard' })
map('n', '<C-c>', 'ciw', { desc = 'Change inner word' })
map('n', '<C-c>', 'ciw')

-- Select last inserted text
map('n', 'gV', '`[V`]', { remap = false, desc = 'Visually select last insert' })

-- Convert all tabs to spaces
map('n', '<leader>ct<space>', ':retab<cr>', { remap = false, silent = true })

-- Enable folding with the leader-f/a
map('n', '<leader>ff', 'za', { remap = false, desc = 'Toggle fold' })
map('n', '<leader>fc', 'zM', { remap = false, desc = 'Close all folds' })
map('n', '<leader>fo', 'zR', { remap = false, desc = 'Open all folds' })
-- Open level folds
map('n', '<leader>fl', 'zazczA', { remap = false, desc = 'Open fold level' })

-- Change \n to new lines
map(
  'n',
  '<leader><cr>',
  [[:silent! %s?\\n?\r?g<bar>silent! %s?\\t?\t?g<bar>silent! %s?\\r?\r?g<cr>:noh<cr>]],
  { silent = true, desc = 'Convert escaped newlines' }
)
-- toggle wrap
map('n', '<leader>ww', ':set wrap!<cr>', { remap = false, silent = true, desc = 'Toggle line wrap' })

-- Scroll one line
map('n', '<PageUp>', '<c-y>', { remap = false, desc = 'Scroll one line up' })
map('n', '<PageDown>', '<c-e>', { remap = false, desc = 'Scroll one line down' })

-- Scrolling centralized
map('n', '<C-u>', '<C-u>zz', { remap = false, desc = 'Scroll half page up and center' })
map('n', '<C-d>', '<C-d>zz', { remap = false, desc = 'Scroll half page down and center' })

-- Change working directory based on open file
map('n', '<leader>cd', ':cd %:p:h<CR>:pwd<CR>', { remap = false, silent = true, desc = 'Change directory to current file' })

-- Change every " -" with " \<cr> -" to break long lines of bash
map('n', [[<leader>\]], [[:.s/ -/ \\\r  -/g<cr>:noh<cr>]], { silent = true, desc = 'Break long command line' })

-- global yanks and deletes
map('v', '<leader>dab', [["hyqeq:v?\V<c-r>h?d E<cr>:let @"=@e<cr>:noh<cr>]], { remap = false, desc = 'Delete all but...', silent = true })
map('v', '<leader>daa', [["hyqeq:g?\V<c-r>h?d E<cr>:let @"=@e<cr>:noh<cr>]], { remap = false, desc = 'Delete all ...', silent = true })
map('v', '<leader>yab', [["hymmqeq:v?\V<c-r>h?yank E<cr>:let @"=@e<cr>`m:noh<cr>]], { remap = false, desc = 'Yank all but...', silent = true })
map('v', '<leader>yaa', [["hymmqeq:g?\V<c-r>h?yank E<cr>:let @"=@e<cr>`m:noh<cr>]], { remap = false, desc = 'Yank all...', silent = true })

-- Base64 dencode
local function b64(action)
  local start = vim.api.nvim_buf_get_mark(0, '[')
  local finish = vim.api.nvim_buf_get_mark(0, ']')
  local line = vim.api.nvim_buf_get_text(0, start[1] - 1, start[2], finish[1] - 1, finish[2] + 1, {})[1]
  local b64_action = action == 'encode' and vim.base64.encode or vim.base64.decode
  local result = b64_action(line)

  -- Split result by newlines to handle multi-line decoded text
  local new_text = vim.split(result, '\n', { plain = true })

  vim.api.nvim_buf_set_text(0, start[1] - 1, start[2], finish[1] - 1, finish[2] + 1, new_text)

  -- Update cursor position to end of replaced text
  local new_end_row = start[1] - 1 + #new_text - 1
  local new_end_col = #new_text[#new_text]
  vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win(), { new_end_row + 1, new_end_col })
end
function _G.__base64_encode(motion)
  if motion == nil or motion == 'line' then
    vim.o.operatorfunc = 'v:lua.__base64_encode'
    return vim.fn.feedkeys 'g@'
  end
  b64 'encode'
end
function _G.__base64_decode(motion)
  if motion == nil or motion == 'line' then
    vim.o.operatorfunc = 'v:lua.__base64_decode'
    return vim.fn.feedkeys 'g@'
  end
  b64 'decode'
end
map('n', '<leader>64', _G.__base64_encode)
map('n', '<leader>46', _G.__base64_decode)
map('v', '<leader>64', _G.__base64_encode)
map('v', '<leader>46', _G.__base64_decode)

-- Close current buffer
map('n', '<leader>bc', ':close<cr>', { silent = true, desc = 'Close this buffer' })

-- Duplicate a line and comment out the first line
map('n', 'yc', 'yygccp', { remap = true, desc = 'Duplicate and comment line' })

-- Abbreviations
map('!a', 'dont', [[don't]], { remap = false })
map('!a', 'ill', [[i'll]], { remap = false })
map('!a', 'seperate', 'separate', { remap = false })
map('!a', 'adn', 'and', { remap = false })
map('!a', 'waht', 'what', { remap = false })
map('!a', 'tehn', 'then', { remap = false })
map('!a', 'taht', 'that', { remap = false })
map('!a', 'cehck', 'check', { remap = false })

map('!a', 'rbm', [[# TODO: remove before merging]], { remap = false })
map('!a', 'cbm', [[# TODO: change before merging]], { remap = false })
map('!a', 'ubm', [[# TODO: uncomment before merging]], { remap = false })

-----------------
-- Yaml / Json --
-----------------
-- Yaml 2 json
vim.api.nvim_create_user_command('Yaml2Json', function()
  vim.cmd [[%!yq -ojson]]
end, {})

vim.api.nvim_create_user_command('Json2Yaml', function()
  vim.cmd [[%!yq -P]]
end, {})

-----------------
-- Where am I? --
-----------------
vim.api.nvim_create_user_command('Whereami', function()
  local result = vim.system({ 'curl', '-s', 'http://ipconfig.io/json' }):wait()
  vim.print('result: ' .. vim.inspect(result))
  if result.code ~= 0 then
    vim.notify('Failed to fetch location data', vim.log.levels.ERROR)
    return
  end
  local country_data = vim.json.decode(result.stdout)
  local iso = country_data.country_iso
  local country = country_data.country
  local emoji = require('user.utils').country_os_to_emoji(iso)
  if not emoji then
    emoji = '🌎'
  end
  local msg = string.format([[You're in %s %s]], country, emoji)
  vim.notify(msg, vim.log.levels.INFO, { title = 'Where am I?', icon = emoji })
end, {})

------------------------
-- Change indentation --
------------------------
map('n', 'cii', function()
  vim.ui.input({ prompt = 'Enter new indent❯ ' }, function(indent_size)
    local indent_size_normalized = tonumber(indent_size)
    vim.opt_local.shiftwidth = indent_size_normalized
    vim.opt_local.softtabstop = indent_size_normalized
    vim.opt_local.tabstop = indent_size_normalized
  end)
end)

-------------------------
-- Diff with last save --
-------------------------
vim.api.nvim_create_user_command('DiffWithSaved', function()
  -- Get start buffer
  local start = vim.api.nvim_get_current_buf()
  local filetype = vim.api.nvim_get_option_value('filetype', { buf = start })
  vim.cmd 'vnew | set buftype=nofile | read ++edit # | 0d_ | diffthis'
  local scratch = vim.api.nvim_get_current_buf()
  vim.api.nvim_set_option_value('filetype', filetype, { buf = scratch })
  vim.cmd 'wincmd p | diffthis'

  -- Map `q` for both buffers to exit diff view and delete scratch buffer
  for _, buf in ipairs { scratch, start } do
    map('n', 'q', function()
      vim.cmd 'windo diffoff'
      vim.api.nvim_buf_delete(scratch, { force = true })
      vim.keymap.del('n', 'q', { buffer = start })
    end, { buffer = buf })
  end
end, {})

map('n', '<leader>ds', ':DiffWithSaved<cr>', { remap = false, silent = true })

-----------------------
-- Visual calculator --
-----------------------
vim.cmd [[
function s:VisualCalculator() abort
  let save_pos = getpos('.')
  let first_expr = GetMotion('gv')

  " Get arithmetic operation from user input
  call inputsave()
  let operation = input('Enter operation: ')
  call inputrestore()

  " Calculate final result
  let fin_result = eval(str2nr(first_expr) . operation)

  " Replace
  call ReplaceMotion('gv', fin_result)
  call setpos('.', save_pos)
endfunction
command! -range VisualCalculator call <SID>VisualCalculator()
vmap <c-r> :VisualCalculator<cr>
]]

----------
-- Grep --
----------
require('user.grep').setup()

----------------
-- EasyMotion --
----------------
require('user.easymotion').setup()

------------------------
-- Run current buffer --
------------------------
require 'user.run-buffer'

--------------------
-- Clear Terminal --
--------------------
-- selene: allow(unused_variable)
function ClearTerm(reset)
  local scrollback = vim.opt_local.scrollback
  vim.opt_local.scrollback = 1

  vim.api.nvim_command 'startinsert'
  vim.api.nvim_feedkeys(vim.keycode '<c-c>', 't', true)
  if reset == 1 then
    vim.api.nvim_feedkeys('reset', 't', false)
  else
    vim.api.nvim_feedkeys('clear', 't', false)
  end
  vim.api.nvim_feedkeys(vim.keycode '<cr>', 't', true)

  vim.opt_local.scrollback = scrollback
end
vim.api.nvim_create_user_command('ClearTerm', 'lua ClearTerm(<args>)', { nargs = 1 })
map('t', '<C-l><C-l>', [[<C-\><C-N>:ClearTerm 0<CR>]], { remap = false, silent = true })
map('t', '<C-l><C-l><C-l>', [[<C-\><C-N>:ClearTerm 1<CR>]], { remap = false, silent = true })

----------------------------
-- Sort Json Array by key --
----------------------------
vim.cmd [[
function s:JsonSortArrayByKey() abort
  call inputsave()
  let sort_key = input('Sort by key: ')
  call inputrestore()
  let save_pos = getpos('.')
  let save_pos[2] = save_pos[2] - 1
  let entire_selection = GetMotion('gv')
  let formatted_selection = trim(system("jq 'sort_by(" . sort_key . ")'", entire_selection))
  call ReplaceMotion('gv', formatted_selection)
  call setpos('.', save_pos)
  normal! gv=
endfunction
command! -range JsonSortArrayByKey call <SID>JsonSortArrayByKey()
]]

--------------
-- Titleize --
--------------
vim.api.nvim_create_user_command('Titleize', function(opts)
  local title_char = '-'
  if opts.args ~= '' then
    title_char = opts.args
  end
  local current_line = vim.api.nvim_get_current_line()
  local indent = string.match(current_line, '^%s*')
  current_line = vim.trim(current_line)
  local r, _ = unpack(vim.api.nvim_win_get_cursor(0))

  -- delete line
  vim.api.nvim_del_current_line()

  local top_bottom = indent .. title_char:rep(#current_line + 6)
  vim.api.nvim_buf_set_lines(0, r - 1, r - 1, false, {
    top_bottom,
    indent .. title_char:rep(2) .. ' ' .. current_line .. ' ' .. title_char:rep(2),
    top_bottom,
  })
end, { nargs = '?' })

------------------------
-- Search and Replace --
------------------------
vim.cmd('source ' .. vim.fn.stdpath 'config' .. '/lua/user/search-replace.vim')

require('user.tabular-v2').setup {}
require('user.projects').setup()
require 'user.number-separators'

--------------
-- Difftool --
--------------
vim.api.nvim_create_user_command('DirDiff', function(opts)
  if vim.tbl_count(opts.fargs) ~= 2 then
    vim.notify('DirDiff requires exactly two directory arguments', vim.log.levels.ERROR)
    return
  end

  if not opts.bang then
    vim.cmd 'tabnew'
  end

  vim.cmd.packadd 'nvim.difftool'
  require('difftool').open(opts.fargs[1], opts.fargs[2], {
    rename = {
      detect = false,
    },
    ignore = { '.git' },
  })
end, { complete = 'dir', nargs = '*', bang = true, desc = 'Diff two directories (bang to not open in a new tab)' })
