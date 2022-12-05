local utils = require 'user.utils'
local keymap = utils.keymap
local opts = utils.map_opts

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
keymap('t', '<C-E>', '<Esc><Cmd>WinResizerStartResize<CR>', opts.no_remap_silent)

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
keymap({ 'n', 'x' }, 'gp', '<Plug>(YankyGPutAfter)')
keymap({ 'n', 'x' }, 'gP', '<Plug>(YankyGPutBefore)')
keymap('n', '<c-n>', '<Plug>(YankyCycleForward)')
keymap('n', '<c-m>', '<Plug>(YankyCycleBackward)')

----------
-- Leap --
----------
keymap('n', 's', '<Plug>(leap-forward-to)', opts.silent)
keymap('n', 'S', '<Plug>(leap-backward-to)', opts.silent)

-----------------
-- Projections --
-----------------
require('projections').setup {
  workspaces = { -- Default workspaces to search for
    -- "~/dev",                               dev is a workspace. default patterns is used (specified below)
    -- { "~/Documents/dev", { ".git" } },     Documents/dev is a workspace. patterns = { ".git" }
    { '~/Repos', {} }, --                    An empty pattern list indicates that all subfolders are considered projects
  },
}

-- Bind <leader>fp to Telescope projections
require('telescope').load_extension 'projections'
vim.keymap.set('n', '<leader>fp', function()
  vim.cmd 'Telescope projections'
end)

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
keymap('n', 'ga', '<Plug>(EasyAlign)', {})

--------------
-- Floaterm --
--------------
vim.g['floaterm_keymap_toggle'] = '<F6>'
keymap('n', '<F6>', '<Cmd>FloatermToggle<CR>', opts.no_remap_silent)
vim.g['floaterm_keymap_new'] = '<F7>'
keymap('n', '<F7>', '<Cmd>FloatermNew<CR>', opts.no_remap_silent)
vim.g['floaterm_keymap_next'] = '<F8>'
keymap('n', '<F8>', '<Cmd>FloatermNext<CR>', opts.no_remap_silent)
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
keymap('n', '<leader>j', '<cmd>AnyJump<CR>', opts.no_remap)

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
keymap('n', 'n', [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]], opts.no_remap_silent)
keymap('n', 'N', [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]], opts.no_remap_silent)
keymap('n', '*', [[*<Cmd>lua require('hlslens').start()<CR>]], opts.no_remap_silent)
keymap('n', '#', [[#<Cmd>lua require('hlslens').start()<CR>]], opts.no_remap_silent)
keymap('n', 'g*', [[g*<Cmd>lua require('hlslens').start()<CR>]], opts.no_remap_silent)
keymap('n', 'g#', [[g#<Cmd>lua require('hlslens').start()<CR>]], opts.no_remap_silent)

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
keymap('n', '<leader>cc', ":lua require('yaml-companion').open_ui_select()<cr>", opts.no_remap_silent)

--------------
-- DevIcons --
--------------
vim.g['WebDevIconsOS'] = 'Darwin'
vim.g['DevIconsEnableFoldersOpenClose'] = 1
vim.g['DevIconsEnableFolderExtensionPatternMatching'] = 1

------------------
-- Nvim Toggler --
------------------
require('nvim-toggler').setup {
  remove_default_keybinds = true,
  inverses = {
    ['enable'] = 'disable',
  },
}
keymap({ 'n', 'v' }, 'gs', require('nvim-toggler').toggle)

----------------
-- vim.notify --
----------------
vim.notify = require 'notify'
require('notify').setup {
  background_colour = '#000000',
}
keymap('n', '<Leader>x', ":lua require('notify').dismiss()<cr>", opts.silent)

---------------
-- Which-Key --
---------------
require('which-key').setup {}
require 'user.which-key'

-----------
-- ISwap --
-----------
require('iswap').setup()
keymap('n', '<leader>sw', ':ISwapWith<CR>')

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
require 'user.menu'
