local utils = require 'user.utils'
local keymap = utils.keymap
local opts = utils.map_opts

-----------------
-- Colorscheme --
-----------------
-- vim.g.material_style = 'darker'
-- vim.g.neon_style = 'doom'
-- vim.g.neon_italic_keyword = true
-- vim.g.neon_italic_function = true
-- vim.g.neon_transparent = true
-- vim.g.neon_overrides = {
--   CursorColumn = { fg = 'NONE', bg = '#3f444a' },
-- }
-- vim.cmd [[colorscheme neon]]
require('one_monokai').setup()

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
vim.g['floaterm_keymap_new'] = '<F7>'
vim.g['floaterm_keymap_next'] = '<F8>'
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

------------------
-- Fold Preview --
------------------
local fold_preview = require 'fold-preview'
fold_preview.setup {}

--------------
-- Diffview --
--------------
-- local actions = require 'diffview.actions'
require('diffview').setup {}
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
keymap('n', 'n', [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]], opts.no_remap_silent)
keymap('n', 'N', [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]], opts.no_remap_silent)
keymap('n', '*', [[*<Cmd>lua require('hlslens').start()<CR>]], opts.no_remap_silent)
keymap('n', '#', [[#<Cmd>lua require('hlslens').start()<CR>]], opts.no_remap_silent)
keymap('n', 'g*', [[g*<Cmd>lua require('hlslens').start()<CR>]], opts.no_remap_silent)
keymap('n', 'g#', [[g#<Cmd>lua require('hlslens').start()<CR>]], opts.no_remap_silent)

----------------
-- Bufferline --
----------------
require('bufferline').setup {
  options = {
    numbers = 'ordinal',
    diagnostics = 'nvim_lsp',
    separator_style = 'thin',
    show_tab_indicators = true,
    show_buffer_close_icons = true,
    show_close_icon = true,
  },
}
vim.keymap.set('n', '<leader>1', '<cmd>BufferLineGoToBuffer 1<cr>')
vim.keymap.set('n', '<leader>2', '<cmd>BufferLineGoToBuffer 2<cr>')
vim.keymap.set('n', '<leader>3', '<cmd>BufferLineGoToBuffer 3<cr>')
vim.keymap.set('n', '<leader>4', '<cmd>BufferLineGoToBuffer 4<cr>')
vim.keymap.set('n', '<leader>5', '<cmd>BufferLineGoToBuffer 5<cr>')

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

---------------
-- Colorizer --
---------------
require('colorizer').setup()

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
local conflict_patterns = {
  { pattern = 'GitConflictDetected', notify = P, text = 'detected' },
  { pattern = 'GitConflictResolved', notify = vim.notify, text = 'resolved' },
}
for _, conflict_data in ipairs(conflict_patterns) do
  vim.api.nvim_create_autocmd('User', {
    pattern = conflict_data.pattern,
    callback = function()
      conflict_data.notify('Conflict ' .. conflict_data.text .. ' in ' .. vim.fn.expand '<afile>')
    end,
  })
end

--------------
-- NERDTree --
--------------
-- vim.g['NERDTreeChDirMode'] = 2
-- vim.g['NERDTreeHijackNetrw'] = 1
-- vim.g['NERDTreeShowHidden'] = 1
-- vim.g['NERDTreeHighlightCursorline'] = 1
-- vim.g['NERDTreeFileExtensionHighlightFullName'] = 1
-- vim.g['NERDTreeGitStatusUseNerdFonts'] = 1
-- -- vim.g["NERDTreeGitStatusConcealBrackets"] = 1
-- vim.g['NERDTreeGitStatusIndicatorMapCustom'] = {
--   Modified = '✹',
--   Staged = '✚',
--   Untracked = '✭',
--   Unmerged = '═',
--   Dirty = '✗',
--   Renamed = '➜',
--   Clean = '✔︎',
--   Ignored = '☒',
--   Deleted = '✖',
--   Unknown = '?',
-- }
-- vim.cmd [[
-- " Check if NERDTree is open or active
-- function! IsNERDTreeOpen()
--   return exists('t:NERDTreeBufName') && (bufwinnr(t:NERDTreeBufName) != -1)
-- endfunction
-- " Call NERDTreeFind iff NERDTree is active, current window contains a modifiable
-- " file, and we're not in vimdiff
-- function! SyncTree()
--   if &modifiable && IsNERDTreeOpen() && strlen(expand('%')) > 0 && !&diff
--     NERDTreeFind
--     wincmd p
--   endif
-- endfunction
-- function! ToggleNerdTree()
--   set eventignore=BufEnter
--   NERDTreeToggle
--   set eventignore=
-- endfunction
-- augroup nerd_tree_augroup
--   autocmd!
--   " Highlight currently open buffer in NERDTree
--   autocmd BufEnter * call SyncTree()
--   " Close VIM if NERDTree is the only buffer left
--   autocmd BufEnter * if (winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree()) | q | endif
-- augroup END
-- nmap <silent> <C-o> :call ToggleNerdTree()<CR>
-- nmap <silent> <expr> <Leader>v ':'.(IsNERDTreeOpen() ? '' : 'call ToggleNerdTree()<bar>wincmd p<bar>').'NERDTreeFind<CR>'
-- ]]

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

-------------
-- Trouble --
-------------
require('trouble').setup()
keymap('n', '<leader>xx', '<cmd>TroubleToggle<cr>', opts.no_remap_silent)
keymap('n', '<leader>xw', '<cmd>TroubleToggle workspace_diagnostics<cr>', opts.no_remap_silent)
keymap('n', '<leader>xd', '<cmd>TroubleToggle document_diagnostics<cr>', opts.no_remap_silent)
keymap('n', '<leader>xl', '<cmd>TroubleToggle loclist<cr>', opts.no_remap_silent)
keymap('n', '<leader>xq', '<cmd>TroubleToggle quickfix<cr>', opts.no_remap_silent)
keymap('n', 'gR', '<cmd>TroubleToggle lsp_references<cr>', opts.no_remap_silent)

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

----------------------
-- indent_blankline --
----------------------
vim.cmd [[highlight IndentBlanklineIndent1 guifg=#C678DD gui=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent2 guifg=#E06C75 gui=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent3 guifg=#E5C07B gui=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent4 guifg=#98C379 gui=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent5 guifg=#56B6C2 gui=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent6 guifg=#61AFEF gui=nocombine]]
require('indent_blankline').setup {
  char = '┊',
  filetype_exclude = {
    'NvimTree',
    'TelescopePrompt',
    'TelescopeResults',
    'alpha',
    'help',
    'lspinfo',
    'mason.nvim',
    'nvchad_cheatsheet',
    'packer',
    'terminal',
    '',
  },
  buftype_exclude = { 'terminal' },
  show_trailing_blankline_indent = false,
  show_first_indent_level = false,
  show_current_context = true,
  show_current_context_start = true,
  space_char_blankline = ' ',
  -- char_highlight_list = {
  --   'IndentBlanklineIndent1',
  --   'IndentBlanklineIndent2',
  --   'IndentBlanklineIndent3',
  --   'IndentBlanklineIndent4',
  --   'IndentBlanklineIndent5',
  --   'IndentBlanklineIndent6',
  -- },
}

--------------------------------
-- Nvim PQF (pretty quickfix) --
--------------------------------
require('pqf').setup()

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
-- Plugin requires --
---------------------
require 'user.cmpconf'
require 'user.treesitter'
require 'user.lsp'
require 'user.autocommands'
require 'user.gitsigns'
require 'user.telescope'
require 'user.lualine'
require 'user.tree'
require 'user.git'
require 'user.dap'

local custom_settings_ok, custom_settings = pcall(require, 'user.custom-settings')
if custom_settings_ok then
  custom_settings.plugin_configs()
end
