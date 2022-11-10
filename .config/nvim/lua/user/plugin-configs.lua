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

---------------------
-- Plugin requires --
---------------------
require 'user.git'

----------------
-- WinResizer --
----------------
vim.g['winresizer_start_key'] = '<C-E>'
keymap('t', '<C-E>', '<Esc><Cmd>WinResizerStartResize<CR>', opts.no_remap_silent)

-------------------
-- Vim json path --
-------------------
vim.g['jsonpath_register'] = '*'

------------------
-- Comment.nvim --
------------------
require('Comment').setup {}

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
    winblend = 0,
    border = 'rounded',
    width = '1.0',
    prompt_align = 'center',
    winhighlight = 'NormalFloat:Normal',
    -- get_config = function()
    --   if vim.api.nvim_buf_get_option(0, 'filetype') == 'NvimTree' then
    --     return { enabled = false }
    --   end
    -- end,
  },
}
vim.cmd [[hi link FloatTitle Normal]]

--------------
-- Diffview --
--------------
-- local actions = require 'diffview.actions'
-- require('diffview').setup {}
--   enhanced_diff_hl = true, -- See ':h diffview-config-enhanced_diff_hl'
--   keymaps = {
--     disable_defaults = true, -- Disable the default keymaps
--     file_panel = {
--       ['cc'] = '<cmd>G commit<cr>',
--     },
--   },
-- }

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

-------------------
-- Editor config --
-------------------
vim.g['EditorConfig_exclude_patterns'] = { 'fugitive://.*' }

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

----------------
-- Yaml Buddy --
----------------
keymap('n', '<leader>cc', ":lua require('yaml-companion').open_ui_select()<cr>", opts.no_remap_silent)

-------------------
-- Vim close tag --
-------------------
vim.g['closetag_filenames'] = '*.html,*.xhtml,*.phtml,*.erb,*.jsx,*.tsx,*.js'
vim.g['closetag_filetypes'] = 'html,xhtml,phtml,javascript,javascriptreact'

--------------
-- DevIcons --
--------------
vim.g['WebDevIconsOS'] = 'Darwin'
vim.g['DevIconsEnableFoldersOpenClose'] = 1
vim.g['DevIconsEnableFolderExtensionPatternMatching'] = 1

---------------------
-- Conflict marker --
---------------------
require('git-conflict').setup()

----------------
-- Switch vim --
----------------
-- The map switch is between underscores to camelCase: moshe_king -> mosheKing -> moshe_king.
vim.g['switch_custom_definitions'] = {
  { 'SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT' },
  { 'yes', 'no' },
  { 'enable', 'disable' },
  { '==', '!=' },
  -- {
  --   [vim.regex([[\<[a-z0-9]\+_\k\+\>]])] = {
  --     [vim.regex([[_\(.\)]])] = vim.regex([[\U\1]])
  --   },
  --   [vim.regex([[\<[a-z0-9]\+[A-Z]\k\+\>]])] = {
  --     [vim.regex([[\([A-Z]\)]])] = vim.regex([[_\l\1]])
  --   },
  -- }
}

-------------------
-- Close Buffers --
-------------------
require('close_buffers').setup {}

----------------
-- vim.notify --
----------------
vim.notify = require 'notify'
require('notify').setup {
  background_colour = '#000000',
}

---------------
-- Which-Key --
---------------
require('which-key').setup {}
require 'user.which-key'

-------------------------
-- bulb (code actions) --
-------------------------
local lightbulb = require 'nvim-lightbulb'
lightbulb.setup {
  autocmd = { enabled = true },
  sign = {
    enabled = false,
  },
  virtual_text = {
    enabled = true,
    text = '💡',
    -- highlight mode to use for virtual text (replace, combine, blend), see :help nvim_buf_set_extmark() for reference
    hl_mode = 'replace',
  },
}

----------------
-- Scope.Nvim --
----------------
require('scope').setup()

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
