local map = vim.keymap.set
-- options {{{
vim.cmd [[colorscheme sorbet]]
-- Performance: Defer filetype detection for faster startup (if not set elsewhere)
vim.loader.enable()

-- UI/UX: Highlight on yank
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank { timeout = 200 }
  end,
  desc = 'Highlight selection on yank',
})

-- Jump to last edit position when reopening file
vim.api.nvim_create_autocmd('BufReadPost', {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
  desc = 'Return to last edit pos after reopen',
})

vim.g.mapleader = ' '
vim.o.title = true
vim.o.cursorcolumn = true
vim.o.cursorline = true
vim.opt.shortmess:append { c = true, l = false, q = false, S = false, C = true, I = true }
vim.o.list = true
vim.o.shada = [[!,'1000,s10000,h]]
vim.o.number = true
vim.o.relativenumber = true
vim.o.linebreak = true
vim.o.hlsearch = true
vim.o.incsearch = true
vim.o.inccommand = 'split'
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.autoread = true
vim.o.scrolloff = 4
vim.o.sidescrolloff = 8
vim.o.cmdheight = 1
vim.o.hidden = true
vim.o.showmatch = true
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.startofline = false
vim.o.confirm = true
vim.o.lazyredraw = false
vim.o.swapfile = false
vim.o.wildmenu = true
vim.opt.wildmode = { 'longest:full', 'full' }
vim.opt.completeopt = 'menu,menuone,noselect,noinsert,popup'
vim.o.previewheight = 15
vim.o.laststatus = 3
vim.o.showcmd = true
vim.o.mouse = 'a'
vim.o.undofile = true
vim.o.undolevels = 10000
vim.o.textwidth = 80
vim.opt.cpoptions:append '>'
vim.o.equalalways = true
vim.o.history = 10000
vim.o.signcolumn = 'yes'
vim.o.updatetime = 300
vim.opt.wildignore:append { '**/node_modules/**', '.hg', '.git', '.svn', '*.DS_Store', '*.pyc' }
vim.opt.path:append { '**' }
-- Folding {{{
vim.o.foldenable = true
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
vim.o.foldlevel = 999
vim.o.foldlevelstart = 99
vim.o.foldcolumn = '1' -- '0' is not bad
vim.o.foldtext = 'substitute(getline(v:foldstart),"\t",repeat(" ",&tabstop),"g")."...".trim(getline(v:foldend))'
-- }}}
vim.opt.formatoptions:append {
  c = true,
  j = true,
  l = true,
  o = true,
  r = true,
  t = true,
}
-- Indenting
vim.o.breakindent = true
vim.o.autoindent = true
vim.o.copyindent = true
vim.o.smartindent = true
vim.o.shiftwidth = 2
vim.o.shiftround = true
vim.o.softtabstop = 2
vim.o.tabstop = 2
vim.o.smarttab = true
vim.o.expandtab = true
vim.opt.indentkeys:remove '0#'
vim.opt.indentkeys:remove '<:>'
-- }}}

-- keymaps {{{
map('n', '<CR>', '<Esc>:nohlsearch<CR><CR>', { remap = false, silent = true, desc = 'Clear search highlighting' })
map({ 'n', 'v' }, '0', '^', { remap = false, desc = 'Go to the first non-blank character' })
-- Move view left or right
map('n', 'L', '5zl', { remap = false, desc = 'Move view to the right' })
map('v', 'L', '$', { remap = false, desc = 'Move view to the right' })
map('n', 'H', '5zh', { remap = false, desc = 'Move view to the left' })
map('v', 'H', '0', { remap = false, desc = 'Move view to the left' })

-- indent/unindent visual mode selection with tab/shift+tab
map('v', '<tab>', '>gv', { desc = 'Indent selected text' })
map('v', '<s-tab>', '<gv', { desc = 'Unindent selected text' })

-- Windows mappings
map('n', '<c-w>v', ':vnew<cr>', { remap = false, silent = true, desc = 'New buffer vertically split' })
map('n', '<c-w>s', ':new<cr>', { remap = false, silent = true, desc = 'New buffer horizontally split' })
map('n', '<c-w>e', ':enew<cr>', { remap = false, silent = true, desc = 'New empty buffer' })
map('n', '<C-h>', '<C-w>h', { remap = true, desc = 'Go to Left Window' })
map('n', '<C-j>', '<C-w>j', { remap = true, desc = 'Go to Lower Window' })
map('n', '<C-k>', '<C-w>k', { remap = true, desc = 'Go to Upper Window' })
map('n', '<C-l>', '<C-w>l', { remap = true, desc = 'Go to Right Window' })

map('n', ']q', ':cnext<cr>zz', { remap = false, silent = true })
map('n', '[q', ':cprev<cr>zz', { remap = false, silent = true })

-- Terminal
map('t', '<Esc>', [[<C-\><C-n>]], { remap = false, desc = 'Exit terminal mode' })

-- Copy file path to clipboard
map('n', '<leader>cfp', [[:let @+ = expand('%')<cr>:echo   "Copied relative file path " . expand('%')<cr>]], { remap = false, silent = true })
map('n', '<leader>cfa', [[:let @+ = expand('%:p')<cr>:echo "Copied full file path " . expand('%:p')<cr>]], { remap = false, silent = true })
map('n', '<leader>cfd', [[:let @+ = expand('%:p:h')<cr>:echo "Copied file directory path " . expand('%:p:h')<cr>]], { remap = false, silent = true })
map('n', '<leader>cfn', [[:let @+ = expand('%:t')<cr>:echo "Copied file directory path " . expand('%:t')<cr>]], { remap = false, silent = true })

-- Copy and paste to/from system clipboard
map('v', 'cp', '"+y', { desc = 'Copy to system clipboard' })
map('n', 'cP', '"+yy', { desc = 'Copy line to system clipboard' })
map('n', 'cp', '"+y', { desc = 'Copy to system clipboard' })
map('n', 'cv', '"+p', { desc = 'Paste from system clipboard' })
map('n', '<C-c>', 'ciw', { desc = 'Change inner word' })
map('n', '<C-c>', 'ciw')
-- Copy entire file to clipboard
map('n', 'Y', ':%y+<cr>', { remap = false, silent = true, desc = 'Copy buffer content to clipboard' })

-- Scrolling centralized
map('n', '<C-u>', '<C-u>zz', { remap = false, desc = 'Scroll half page up and center' })
map('n', '<C-d>', '<C-d>zz', { remap = false, desc = 'Scroll half page down and center' })

-- Change working directory based on open file
map('n', '<leader>cd', ':cd %:p:h<CR>:pwd<CR>', { remap = false, silent = true, desc = 'Change directory to current file' })

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
-- }}}

-- packages {{{
vim.pack.add {
  'https://github.com/ibhagwan/fzf-lua',
  'https://github.com/nvim-treesitter/nvim-treesitter',
  'https://github.com/folke/lazydev.nvim',
  'https://github.com/echasnovski/mini.surround',
  'https://github.com/nvim-lualine/lualine.nvim',
}
require('mini.surround').setup {
  mappings = {
    add = 'ys',
    delete = 'ds',
    find = '',
    find_left = '',
    highlight = '',
    replace = 'cs',
    update_n_lines = '',

    -- Add this only if you don't want to use extended mappings
    suffix_last = '',
    suffix_next = '',
  },
  search_method = 'cover_or_next',
}
require('lualine').setup {
  sections = {
    lualine_a = { 'mode' },
    lualine_b = { 'branch', 'diff', 'diagnostics' },
    lualine_c = { 'filename' },
    lualine_x = {
      {
        function()
          local clients = vim.lsp.get_clients { bufnr = 0 }
          if not next(clients) then
            return 'No Active Lsp'
          end
          return 'LSP: '
            .. table.concat(
              vim.tbl_map(function(client)
                return client.name
              end, clients),
              ', '
            )
        end,
        icon = { ' ' },
      },
      'fileformat',
      'filetype',
    },
    lualine_y = { 'progress' },
    lualine_z = { 'location' },
  },
}
require('lazydev').setup { path = '${3rd}/luv/library', words = { 'vim%.uv' } }
-- }}}

-- treesitter {{{
local configs = require 'nvim-treesitter.configs'
---@diagnostic disable: missing-fields
configs.setup {
  highlight = { enable = true },
  ensure_installed = {
    'bash',
    'comment',
    'diff',
    'embedded_template',
    'javascript',
    'json',
    'lua',
    'luadoc',
    'markdown',
    'markdown_inline',
    'python',
    'query',
    'regex',
    'terraform',
    'tsx',
    'typescript',
    'vim',
    'vimdoc',
    'xml',
    'yaml',
  },
  matchup = { enable = true },
  indent = { enable = true, disable = { 'yaml' } },
}
-- }}}

-- fzf {{{
require('fzf-lua').setup {
  opts = {
    'default-title',
    files = { git_icons = true },
    oldfiles = { cwd_only = true, include_current_session = true },
    grep = { hidden = true },
    keymap = { fzf = { ['ctrl-q'] = 'select-all+accept' } },
  },
}
vim.keymap.set('n', '<C-p>', ':FzfLua files<cr>', { desc = 'FzfLua files' })
vim.keymap.set('n', '<C-b>', ':FzfLua buffers<cr>', { desc = 'FzfLua buffers' })
vim.keymap.set('n', '<leader>hh', ':FzfLua help_tags<cr>', { desc = 'FzfLua help tags' })
vim.keymap.set('n', '<leader>i', ':FzfLua oldfiles<cr>', { desc = 'FzfLua old files' })
vim.keymap.set('n', '<leader>/', function()
  require('fzf-lua').live_grep {
    multiprocess = true,
    rg_opts = [=[--column --line-number --hidden --no-heading --color=always --smart-case --max-columns=4096 -g '!.git' -e]=],
  }
end, { desc = 'FzfLua live grep' })
-- }}}

-- lsp {{{
local lsp_au = vim.api.nvim_create_augroup('my.lsp', { clear = true })
vim.api.nvim_create_autocmd('LspAttach', { -- {{{
  group = lsp_au,
  callback = function(args)
    vim.lsp.set_log_level 'trace'
    require('vim.lsp.log').set_format_func(vim.inspect)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    if client:supports_method 'textDocument/implementation' then
      vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, {
        buffer = args.buf,
        desc = 'Go to implementation',
      })
    end

    -- Enable auto-completion. Note: Use CTRL-Y to select an item. |complete_CTRL-Y|
    if client:supports_method 'textDocument/completion' then
      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
    end

    -- Auto-format ("lint") on save.
    -- Usually not needed if server supports "textDocument/willSaveWaitUntil".
    if not client:supports_method 'textDocument/willSaveWaitUntil' and client:supports_method 'textDocument/formatting' then
      vim.api.nvim_create_autocmd('BufWritePre', {
        group = lsp_au,
        buffer = args.buf,
        callback = function()
          vim.lsp.buf.format { bufnr = args.buf, id = client.id, timeout_ms = 1000 }
        end,
      })
    end
  end,
}) -- }}}

vim.lsp.config('lua_ls', {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = {
    '.luarc.json',
    '.luarc.jsonc',
    '.luacheckrc',
    '.stylua.toml',
    'stylua.toml',
    'selene.toml',
    'selene.yml',
    '.git',
  },
})
vim.lsp.enable { 'lua_ls' }
-- }}}
