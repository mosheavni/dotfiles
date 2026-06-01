vim.pack.add {
  'https://github.com/mrjones2014/smart-splits.nvim',
  'https://github.com/kkharji/sqlite.lua',
  'https://github.com/yorickpeterse/nvim-pqf',
  'https://github.com/junegunn/vim-easy-align',
  'https://github.com/AndrewRadev/switch.vim',
  'https://github.com/axelvc/template-string.nvim',
  'https://github.com/machakann/vim-swap',
  'https://github.com/andymass/vim-matchup',
  'https://github.com/windwp/nvim-autopairs',
  'https://github.com/iamcco/markdown-preview.nvim',
  'https://github.com/AndrewRadev/linediff.vim',
  'https://github.com/chr4/nginx.vim',
  'https://github.com/gbprod/yanky.nvim',
  'https://github.com/LunarVim/bigfile.nvim',
}

local sar_dev = vim.fn.expand '~/Repos/search-replace.nvim'
if vim.env.SAR_DEV == 'true' and vim.fn.isdirectory(sar_dev) == 1 then
  vim.opt.runtimepath:prepend(sar_dev)
else
  vim.pack.add { 'https://github.com/mosheavni/search-replace.nvim' }
end

local M = {}

function M.eager()
  ---@diagnostic disable-next-line: missing-fields
  require('smart-splits').setup {}
  vim.keymap.set('n', '<A-h>', require('smart-splits').resize_left, { desc = 'Resize split left' })
  vim.keymap.set('n', '<A-j>', require('smart-splits').resize_down, { desc = 'Resize split down' })
  vim.keymap.set('n', '<A-k>', require('smart-splits').resize_up, { desc = 'Resize split up' })
  vim.keymap.set('n', '<A-l>', require('smart-splits').resize_right, { desc = 'Resize split right' })
  vim.keymap.set('n', '<C-h>', require('smart-splits').move_cursor_left, { desc = 'Move to left split' })
  vim.keymap.set('n', '<C-j>', require('smart-splits').move_cursor_down, { desc = 'Move to split below' })
  vim.keymap.set('n', '<C-k>', require('smart-splits').move_cursor_up, { desc = 'Move to split above' })
  vim.keymap.set('n', '<C-l>', require('smart-splits').move_cursor_right, { desc = 'Move to right split' })
end

function M.deferred()
  require('pqf').setup {}

  vim.g.swap_no_default_key_mappings = true
  vim.keymap.set({ 'n', 'v' }, '<leader>sw', '<Plug>(swap-interactive)', { desc = 'Swap function arguments interactively' })

  vim.g.loaded_matchparen = 1
  vim.g.matchup_matchparen_offscreen = { method = 'status_manual' }
  require('match-up').setup {}

  require('nvim-autopairs').setup {}

  vim.g.mkdp_filetypes = { 'markdown' }
  require('user.menu').add_actions('Markdown', {
    ['Preview in Browser'] = function()
      vim.cmd.MarkdownPreview()
    end,
  })

  require('yanky').setup {
    ring = {
      history_length = 100,
      storage = 'sqlite',
      sync_with_numbered_registers = true,
      cancel_event = 'update',
    },
  }
  vim.keymap.set({ 'n', 'x' }, 'p', '<Plug>(YankyPutAfter)', { desc = 'Paste yank after' })
  vim.keymap.set({ 'n', 'x' }, 'P', '<Plug>(YankyPutBefore)', { desc = 'Paste yank before' })
  vim.keymap.set('n', '<c-n>', '<Plug>(YankyCycleForward)', { desc = 'Cycle yank forward' })
  vim.keymap.set('n', '<c-m>', '<Plug>(YankyCycleBackward)', { desc = 'Cycle yank backward' })
  vim.keymap.set('n', '<leader>y', '<Cmd>YankyRingHistory<cr>', { desc = 'Yank history' })
  require('user.menu').add_actions('Yanky', {
    ['Yank history'] = function()
      vim.cmd 'YankyRingHistory'
    end,
  })

  require('search-replace').setup()

  local fk = [=[\<\(\l\)\(\l\+\(\u\l\+\)\+\)\>]=]
  local sk = [=[\<\(\u\l\+\)\(\u\l\+\)\+\>]=]
  local tk = [=[\<\(\l\+\)\(_\l\+\)\+\>]=]
  local fok = [=[\<\(\u\+\)\(_\u\+\)\+\>]=]
  local folk = [=[\<\(\l\+\)\(\-\l\+\)\+\>]=]
  local fik = [=[\<\(\l\+\)\(\.\l\+\)\+\>]=]
  vim.g['switch_custom_definitions'] = {
    vim.fn['switch#NormalizedCaseWords'] { 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday' },
    vim.fn['switch#NormalizedCase'] { 'yes', 'no' },
    vim.fn['switch#NormalizedCase'] { 'on', 'off' },
    vim.fn['switch#NormalizedCase'] { 'left', 'right' },
    vim.fn['switch#NormalizedCase'] { 'up', 'down' },
    vim.fn['switch#NormalizedCase'] { 'enable', 'disable' },
    vim.fn['switch#NormalizedCase'] { 'Always', 'Never' },
    vim.fn['switch#NormalizedCase'] { 'debug', 'info', 'warning', 'error', 'critical' },
    { '==', '!=', '~=' },
    {
      [fk] = [=[\=toupper(submatch(1)) . submatch(2)]=],
      [sk] = [=[\=tolower(substitute(submatch(0), '\(\l\)\(\u\)', '\1_\2', 'g'))]=],
      [tk] = [=[\U\0]=],
      [fok] = [=[\=tolower(substitute(submatch(0), '_', '-', 'g'))]=],
      [folk] = [=[\=substitute(submatch(0), '-', '.', 'g')]=],
      [fik] = [=[\=substitute(submatch(0), '\.\(\l\)', '\u\1', 'g')]=],
    },
  }
  local custom_switches = vim.api.nvim_create_augroup('CustomSwitches', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    group = custom_switches,
    pattern = { 'gitrebase' },
    callback = function()
      vim.b['switch_custom_definitions'] = {
        { 'pick', 'reword', 'edit', 'squash', 'fixup', 'exec', 'drop' },
      }
    end,
  })
  vim.api.nvim_create_autocmd('FileType', {
    group = custom_switches,
    pattern = { 'markdown' },
    callback = function()
      local mfk = [=[\v^(\s*[*+-] )?\[ \]]=]
      local msk = [=[\v^(\s*[*+-] )?\[x\]]=]
      local mtk = [=[\v^(\s*[*+-] )?\[-\]]=]
      local mfok = [=[\v^(\s*\d+\. )?\[ \]]=]
      local mfik = [=[\v^(\s*\d+\. )?\[x\]]=]
      local msik = [=[\v^(\s*\d+\. )?\[-\]]=]
      vim.b['switch_custom_definitions'] = {
        { [mfk] = [=[\1[x]]=], [msk] = [=[\1[-]]=], [mtk] = [=[\1[ ]]=] },
        { [mfok] = [=[\1[x]]=], [mfik] = [=[\1[-]]=], [msik] = [=[\1[ ]]=] },
      }
    end,
  })

  require('template-string').setup {}

  vim.keymap.set({ 'v', 'n' }, 'ga', '<Plug>(EasyAlign)', { desc = 'Align by motion' })

  require('bigfile').setup()

  local function notify_lsp_rename(old_path, new_path)
    local changes = { { oldUri = vim.uri_from_fname(old_path), newUri = vim.uri_from_fname(new_path) } }
    for _, client in ipairs(vim.lsp.get_clients()) do
      if client:supports_method 'workspace/willRenameFiles' then
        ---@diagnostic disable-next-line: param-type-mismatch
        local resp = client:request_sync('workspace/willRenameFiles', { files = changes }, 1000)
        if resp and resp.result then
          vim.lsp.util.apply_workspace_edit(resp.result, client.offset_encoding)
        end
      end
      if client:supports_method 'workspace/didRenameFiles' then
        client:notify('workspace/didRenameFiles', { files = changes })
      end
    end
  end

  _G._notify_lsp_rename = notify_lsp_rename

  vim.api.nvim_create_user_command('Rename', function()
    local old = vim.api.nvim_buf_get_name(0)
    vim.ui.input({ prompt = 'New filename: ', default = old }, function(new)
      if not new or new == old then
        return
      end
      vim.fn.rename(old, new)
      vim.cmd('keepalt saveas ' .. vim.fn.fnameescape(new))
      notify_lsp_rename(old, new)
    end)
  end, { desc = 'Rename file' })
end

return M
