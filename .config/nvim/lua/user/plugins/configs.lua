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
  style = 'warmer',
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

-------------------
-- Vim json path --
-------------------
vim.g['jsonpath_register'] = '*'

-----------
-- Yanky --
-----------
require('yanky').setup {
  ring = {
    history_length = 100,
    storage = 'sqlite',
    sync_with_numbered_registers = true,
    cancel_event = 'update',
  },
}
keymap({ 'n', 'x' }, 'p', '<Plug>(YankyPutAfter)')
keymap({ 'n', 'x' }, 'P', '<Plug>(YankyPutBefore)')
-- keymap({ 'n', 'x' }, 'gp', '<Plug>(YankyGPutAfter)')
-- keymap({ 'n', 'x' }, 'gP', '<Plug>(YankyGPutBefore)')
nmap('<c-n>', '<Plug>(YankyCycleForward)')
nmap('<c-m>', '<Plug>(YankyCycleBackward)')

----------
-- Leap --
----------
nnoremap('s', '<Plug>(leap-forward-to)', true)
nnoremap('S', '<Plug>(leap-backward-to)', true)

-- Autostore session on DirChange and VimExit
local Session = require 'projections.session'
vim.api.nvim_create_autocmd({ 'DirChangedPre', 'VimLeavePre' }, {
  callback = function()
    Session.store(vim.loop.cwd())
  end,
})
vim.api.nvim_create_user_command('StoreProjectSession', function()
  Session.store(vim.loop.cwd())
end, {})

vim.api.nvim_create_user_command('RestoreProjectSession', function()
  Session.restore(vim.loop.cwd())
end, {})

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
-- Dressing.nvim --
-------------------
require('dressing').setup {
  input = {
    override = function(conf)
      conf.col = -1
      conf.row = 0
      return conf
    end,
    win_options = {
      winhighlight = 'NormalFloat:Normal',
      winblend = 0,
    },
    border = 'rounded',
    width = '1.0',
    prompt_align = 'center',
    -- get_config = function()
    --   if vim.api.nvim_buf_get_option(0, 'filetype') == 'NvimTree' then
    --     return { enabled = false }
    --   end
    -- end,
  },
}
vim.cmd [[hi link FloatTitle Normal]]

-----------------
-- Vim ansible --
-----------------
vim.g['ansible_goto_role_paths'] = '.;,roles;'

-------------------
-- Yaml Revealer --
-------------------
vim.g['yaml_revealer_separator'] = '.'
vim.g['yaml_revealer_list_indicator'] = 1

-- AnyJump --
-------------
nnoremap('<leader>j', '<cmd>AnyJump<CR>')

---------------
-- neoscroll --
---------------
-- if not vim.g.neovide then
--   require('neoscroll').setup {
--     -- All these keys will be mapped to their corresponding default scrolling animation
--     mappings = { '<C-u>', '<C-d>', 'zt', 'zz', 'zb' },
--   }
-- end

-------------
-- hlslens --
-------------
require('hlslens').setup()
nnoremap('n', [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]], true)
nnoremap('N', [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]], true)
nnoremap('*', [[*<Cmd>lua require('hlslens').start()<CR>]], true)
nnoremap('#', [[#<Cmd>lua require('hlslens').start()<CR>]], true)
nnoremap('g*', [[g*<Cmd>lua require('hlslens').start()<CR>]], true)
nnoremap('g#', [[g#<Cmd>lua require('hlslens').start()<CR>]], true)

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
vim.notify = require 'notify'
require('notify').setup {
  background_colour = '#000000',
}
nmap('<Leader>x', ":lua require('notify').dismiss()<cr>", true)

---------------
-- Which-Key --
---------------
require('which-key').setup {}
require 'user.which-key'

------------
-- Fidget --
------------
require('fidget').setup {
  text = {
    spinner = 'moon',
  },
}

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
