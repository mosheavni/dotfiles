local utils = require 'user.utils'
local keymap = utils.keymap
local tnoremap = utils.inoremap
local nmap = utils.nmap
local nnoremap = utils.nnoremap
local vnoremap = utils.vnoremap
local inoremap = utils.inoremap

-----------------
-- Colorscheme --
-----------------
require('onedark').setup {
  style = 'dark',
}
require('onedark').load()

----------------
-- WinResizer --
----------------
vim.g['winresizer_start_key'] = '<C-E>'
tnoremap('<C-E>', '<Esc><Cmd>WinResizerStartResize<CR>', true)

------------
-- ai.vim --
------------
vim.g.ai_no_mappings = true
nnoremap('<M-a>', ':AI ')
vnoremap('<M-a>', ':AI ')
inoremap('<M-a>', '<Esc>:AI<CR>a')

----------
-- Leap --
----------
nnoremap('s', '<Plug>(leap-forward-to)', true)
nnoremap('S', '<Plug>(leap-backward-to)', true)

--------------------
-- Vim easy align --
--------------------
nmap('ga', '<Plug>(EasyAlign)')

--------------
-- Floaterm --
--------------
vim.g['floaterm_keymap_toggle'] = '<F6>'
nnoremap('<F6>', '<Cmd>FloatermToggle<CR>', true)
vim.g['floaterm_keymap_new'] = '<F7>'
nnoremap('<F7>', '<Cmd>FloatermNew<CR>', true)
vim.g['floaterm_keymap_next'] = '<F8>'
nnoremap('<F8>', '<Cmd>FloatermNext<CR>', true)
vim.g['floaterm_width'] = 0.7
vim.g['floaterm_height'] = 0.9

-------------------
-- Yaml Revealer --
-------------------
vim.g['yaml_revealer_separator'] = '.'
vim.g['yaml_revealer_list_indicator'] = 1

--------------------
-- Github Copilot --
--------------------
vim.cmd [[
imap <silent><script><expr> <M-Enter> copilot#Accept("\<CR>")
" imap <silent> <c-]> <Plug>(copilot-next)
" inoremap <silent> <c-[> <Plug>(copilot-previous)
let g:copilot_no_tab_map = v:true
]]

--------------------
-- Yaml Companion --
--------------------
nnoremap('<leader>cc', ":lua require('yaml-companion').open_ui_select()<cr>", true)

--------------
-- DevIcons --
--------------
vim.g['WebDevIconsOS'] = 'Darwin'
vim.g['DevIconsEnableFoldersOpenClose'] = 1
vim.g['DevIconsEnableFolderExtensionPatternMatching'] = 1

----------------
-- vim.notify --
----------------
-- vim.notify = require 'notify'
-- require('notify').setup {
--   background_colour = '#000000',
-- }
nmap('<Leader>x', ":lua require('notify').dismiss()<cr>", true)

------------
-- Fidget --
------------
-- require('fidget').setup {
--   text = {
--     spinner = 'moon',
--   },
-- }

-------------
-- Ansible --
-------------
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

---------------------
-- Random Requires --
---------------------
require('user.menu').setup()
