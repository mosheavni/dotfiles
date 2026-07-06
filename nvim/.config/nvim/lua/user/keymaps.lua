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

-- Add undo break-points
for _, c in ipairs { ',', '.', ';', '!', '?', '(', ')' } do
  map('i', c, c .. '<C-g>u', { desc = 'Insert ' .. c .. ' with undo break-point' })
end

map('i', ';;', '<C-O>A;', { remap = false, desc = 'Add semicolon at end of line' })
map('i', ',,', '<C-O>A,', { remap = false, desc = 'Add comma at end of line' })

-- delete word on insert mode
map('i', '<C-e>', '<C-o>de', { remap = false, desc = 'Delete word after cursor' })
map('i', '<C-b>', '<C-o>db', { remap = false, desc = 'Delete word before cursor' })

-- Search for string within the visual selection
map('x', '/', '<Esc>/\\%V', { remap = false, desc = 'Search within visual selection' })

-- operators
_G.op = _G.op or {}

---0-indexed bounds of the last operator/motion region (`[ to `]), for nvim_buf_get_text.
---@param motion 'char'|'line'|'block'
---@return integer srow, integer scol, integer erow, integer ecol
local function region_bounds(motion)
  local start = vim.api.nvim_buf_get_mark(0, '[')
  local finish = vim.api.nvim_buf_get_mark(0, ']')
  if motion == 'line' then
    return start[1] - 1, 0, finish[1] - 1, #vim.fn.getline(finish[1])
  end
  -- `] points at the first byte of the last character; advance by its full byte length
  local last_char = vim.fn.strpart(vim.fn.getline(finish[1]), finish[2], 1, 1)
  return start[1] - 1, start[2], finish[1] - 1, finish[2] + #last_char
end

---@param fn string operatorfunc name (v:lua....)
local function arm(fn)
  return function()
    vim.o.operatorfunc = fn
    return 'g@'
  end
end

-- surround with string interpolation with motion
function _G.op.surround_with_interpolation(motion)
  local srow, scol, erow, ecol = region_bounds(motion)
  local lines = vim.api.nvim_buf_get_text(0, srow, scol, erow, ecol, {})
  lines[1] = '"${' .. lines[1]
  lines[#lines] = lines[#lines] .. '}"'
  vim.api.nvim_buf_set_text(0, srow, scol, erow, ecol, lines)
  vim.api.nvim_win_set_cursor(0, { srow + 1, scol })
end
map('n', 'mt', arm 'v:lua.op.surround_with_interpolation', { expr = true, desc = 'Surround with string interpolation' })

-- Indent block
vim.cmd [[
function! g:__align_based_on_indent(_)
  normal! v%koj$>
endfunction
]]
map('n', '<leader>>', function()
  vim.go.operatorfunc = '__align_based_on_indent'
  return 'g@l'
end, { expr = true, desc = 'Align based on indent' })

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
map('n', '<tab>', '<c-w>w', { remap = false, silent = true, desc = 'Go to next window' })
map('n', '<c-w><c-c>', '<c-w>c', { remap = false, silent = true, desc = 'Close current window' })
map('n', '<c-w>v', '<cmd>vnew<cr>', { remap = false, silent = true, desc = 'New buffer vertically split' })
map('n', '<c-w>s', '<cmd>new<cr>', { remap = false, silent = true, desc = 'New buffer horizontally split' })
map('n', '<c-w>e', '<cmd>enew<cr>', { remap = false, silent = true, desc = 'New empty buffer' })

-- Move to window using the <ctrl> hjkl keys
map('n', '<C-h>', '<C-w>h', { remap = false, desc = 'Go to Left Window' })
map('n', '<C-j>', '<C-w>j', { remap = false, desc = 'Go to Lower Window' })
map('n', '<C-k>', '<C-w>k', { remap = false, desc = 'Go to Upper Window' })
map('n', '<C-l>', '<C-w>l', { remap = false, desc = 'Go to Right Window' })

-- entire file text-object
map('o', 'ae', '<cmd>normal! ggVG<CR>', { remap = false, desc = 'Entire buffer text-object' })
map('v', 'ae', '<esc>ggVG', { remap = false, desc = 'Select entire buffer' })
map('n', '<leader>sa', 'ggVG', { remap = false, desc = 'Visually select entire buffer' })

-- Run and edit macros
for _, key in pairs { 'Q', 'X' } do
  ---@diagnostic disable-next-line: undefined-field
  map('n', key, '@' .. key:lower(), { remap = false, desc = 'Run macro ' .. key:lower() })
  map(
    'n',
    '<leader>' .. key,
    ":<c-u><c-r><c-r>='let @" .. key:lower() .. " = '. string(getreg('" .. key:lower() .. "'))<cr><c-f><left>",
    { remap = false, desc = 'Edit macro ' .. key:lower() }
  )
end

-- tabs (on managed terminals, ]t/[t cycle terminals instead)
map('n', ']t', function()
  local term = require 'user.terminal'
  if term.is_tracked_buf() then
    term.cycle 'next'
  else
    vim.cmd.tabnext()
  end
end, { remap = false, silent = true, desc = 'Next tab / terminal' })
map('n', '[t', function()
  local term = require 'user.terminal'
  if term.is_tracked_buf() then
    term.cycle 'prev'
  else
    vim.cmd.tabprev()
  end
end, { remap = false, silent = true, desc = 'Previous tab / terminal' })
map('n', '<leader>tn', '<cmd>tabnew<cr>', { remap = false, silent = true, desc = 'New tab' })
map('n', '<leader>tc', '<cmd>tabclose<cr>', { remap = false, silent = true, desc = 'Close tab' })
map('n', '<leader>th', '<cmd>-tabmove<cr>', { remap = false, silent = true, desc = 'Move tab left' })
map('n', '<leader>tl', '<cmd>+tabmove<cr>', { remap = false, silent = true, desc = 'Move tab right' })

-- This creates a new line of '=' signs the same length of the line
map('n', '<leader>=', 'yypVr=', { remap = false, desc = 'Duplicate line with = signs' })

-- Map dp and dg with leader for diffput and diffget
-- Routed through operatorfunc + g@l (rather than plain <cmd>diffput<cr>) solely
-- to make the mappings dot-repeatable; the callbacks ignore the motion.
_G.op.diffput = function()
  vim.cmd [[diffput]]
end
map('n', '<leader>dp', function()
  vim.go.operatorfunc = 'v:lua.op.diffput'
  return 'g@l'
end, { expr = true, desc = 'Diff put current hunk' })
_G.op.diffget = function()
  vim.cmd [[diffget]]
end
map('n', '<leader>dg', function()
  vim.go.operatorfunc = 'v:lua.op.diffget'
  return 'g@l'
end, { expr = true, desc = 'Diff get current line' })
map('n', '<leader>dn', '<cmd>windo diffthis<cr>', { remap = false, silent = true, desc = 'Start diff mode' })
map('n', '<leader>df', '<cmd>diffoff!<cr>', { remap = false, silent = true, desc = 'End diff mode' })

-- Map enter to no highlight
map('n', '<CR>', '<Esc>:nohlsearch<CR><CR>', { remap = false, silent = true, desc = 'Clear search highlighting' })

-- Exit mappings
map('i', 'jk', '<esc>', { remap = false, desc = 'Exit insert mode' })
map('n', '<leader>qq', '<cmd>qall<cr>', { remap = false, silent = true, desc = 'Quit all' })

-- Terminal
map('t', '<Esc>', [[<C-\><C-n>]], { remap = false, desc = 'Exit terminal mode' })

-- Map - to move a line down and _ a line up
map('n', '-', '<cmd>m+1<CR>==', { silent = true, desc = 'Move line down' })
map('n', '_', '<cmd>m-2<CR>==', { silent = true, desc = 'Move line up' })

-- Copy entire file to clipboard
map('n', 'Y', '<cmd>%y+<cr>', { remap = false, silent = true, desc = 'Copy buffer content to clipboard' })

-- Copy file path to clipboard
for _, spec in ipairs {
  { key = 'cfp', mods = '%', what = 'relative file path' },
  { key = 'cfa', mods = '%:p', what = 'absolute file path' },
  { key = 'cfd', mods = '%:p:h', what = 'file directory path' },
  { key = 'cfn', mods = '%:t', what = 'file name' },
} do
  map('n', '<leader>' .. spec.key, function()
    local value = vim.fn.expand(spec.mods)
    vim.fn.setreg('+', value)
    print('Copied ' .. spec.what .. ' ' .. value)
  end, { remap = false, silent = true, desc = 'Copy ' .. spec.what })
end

-- Copy and paste to/from system clipboard
map({ 'n', 'v' }, 'cp', '"+y', { desc = 'Copy to system clipboard' })
map('n', 'cP', '"+yy', { desc = 'Copy line to system clipboard' })
map('n', 'cv', '"+p', { desc = 'Paste from system clipboard' })
map('n', '<C-c>', 'ciw', { desc = 'Change inner word' })

-- Select last inserted text
map('n', 'gV', '`[V`]', { remap = false, desc = 'Visually select last insert' })

-- Treesitter-based selection (vim.treesitter.select)
-- [N / ]N (built-in visual): jump to sibling node
map({ 'n', 'x' }, '<leader>V', function()
  vim.treesitter.select 'parent'
end, { desc = 'TS: select/expand to parent node' })

-- Convert all tabs to spaces
map('n', '<leader>ct<space>', ':retab<cr>', { remap = false, silent = true, desc = 'Convert tabs to spaces' })

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

-- Center search navigation
map('n', 'n', 'nzz', { remap = false, desc = 'Next search result, centered' })
map('n', 'N', 'Nzz', { remap = false, desc = 'Previous search result, centered' })

-- Change working directory based on open file
map('n', '<leader>.', ':cd %:p:h<CR>:pwd<CR>', { remap = false, silent = true, desc = 'Change directory to current file' })

-- Change every " -" with " \<cr> -" to break long lines of bash
map('n', [[<leader>\]], [[:.s/ -/ \\\r  -/g<cr>:noh<cr>]], { silent = true, desc = 'Break long command line' })

-- global yanks and deletes (single buffer write instead of :global per-line delete)
do
  local function select_lines(lines, pattern, matching)
    local result = {}
    for _, line in ipairs(lines) do
      local matches = pattern ~= '' and vim.fn.match(line, '\\V' .. vim.fn.escape(pattern, '\\')) ~= -1
      if matches == matching then
        result[#result + 1] = line
      end
    end
    return result
  end
  local function visual_context()
    local pattern = require('user.utils').get_visual_selection()
    if pattern == '' then
      return
    end
    return { pattern = pattern, lines = vim.api.nvim_buf_get_lines(0, 0, -1, false) }
  end
  local function filter_delete(matching)
    local ctx = visual_context()
    if not ctx then
      return
    end
    local saved = vim.fn.getreg '"'
    vim.api.nvim_buf_set_lines(0, 0, -1, false, select_lines(ctx.lines, ctx.pattern, matching))
    vim.fn.setreg('"', saved)
    vim.cmd.noh()
  end
  local function filter_yank(matching)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local ctx = visual_context()
    if not ctx then
      return
    end
    local saved = vim.fn.getreg '"'
    vim.fn.setreg('E', table.concat(select_lines(ctx.lines, ctx.pattern, matching), '\n'), 'l')
    vim.fn.setreg('"', saved)
    vim.api.nvim_win_set_cursor(0, cursor)
    vim.cmd.noh()
  end
  for _, spec in ipairs {
    { '<leader>dab', filter_delete, true, 'Delete all but...' },
    { '<leader>daa', filter_delete, false, 'Delete all ...' },
    { '<leader>yab', filter_yank, false, 'Yank all but...' },
    { '<leader>yaa', filter_yank, true, 'Yank all...' },
  } do
    map('v', spec[1], function()
      spec[2](spec[3])
    end, { remap = false, desc = spec[4], silent = true })
  end
end

-- Base64 dencode
local function b64(action, motion)
  local srow, scol, erow, ecol = region_bounds(motion)
  local text = table.concat(vim.api.nvim_buf_get_text(0, srow, scol, erow, ecol, {}), '\n')
  local b64_action = action == 'encode' and vim.base64.encode or vim.base64.decode
  local ok, result = pcall(b64_action, text)
  if not ok then
    vim.notify(('Base64 %s failed: invalid input'):format(action), vim.log.levels.ERROR)
    return
  end

  -- Split result by newlines to handle multi-line decoded text
  local new_text = vim.split(result, '\n', { plain = true })

  vim.api.nvim_buf_set_text(0, srow, scol, erow, ecol, new_text)

  -- Update cursor position to end of replaced text
  local new_end_row = srow + #new_text - 1
  local new_end_col = #new_text[#new_text]
  vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win(), { new_end_row + 1, new_end_col })
end
function _G.op.base64_encode(motion)
  b64('encode', motion)
end
function _G.op.base64_decode(motion)
  b64('decode', motion)
end
map({ 'n', 'x' }, '<leader>64', arm 'v:lua.op.base64_encode', { expr = true, desc = 'Base64 encode' })
map({ 'n', 'x' }, '<leader>46', arm 'v:lua.op.base64_decode', { expr = true, desc = 'Base64 decode' })

-- Close current buffer
map('n', '<leader>bc', ':close<cr>', { silent = true, desc = 'Close this buffer' })

map('n', '<leader>bh', function()
  local count = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and not vim.bo[buf].modified and #vim.fn.win_findbuf(buf) == 0 then
      if pcall(vim.api.nvim_buf_delete, buf, {}) then
        count = count + 1
      end
    end
  end
  vim.notify(count .. ' hidden buffer(s) deleted')
end, { desc = 'Delete Hidden Buffers' })

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
map('!a', 'wip', 'work in progress', { remap = false })
map('!a', 'asap', 'as soon as possible', { remap = false })
map('!a', 'fyi', 'for your information', { remap = false })
map('!a', 'idk', "I don't know", { remap = false })

map('!a', 'rbm', [[# TODO: remove before merging]], { remap = false })
map('!a', 'cbm', [[# TODO: change before merging]], { remap = false })
map('!a', 'ubm', [[# TODO: uncomment before merging]], { remap = false })
