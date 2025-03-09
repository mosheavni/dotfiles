local M = {}

-- Default options
-- Default options
local default_opts = {
  keymap = {
    search = '<C-f>', -- The keybinding to trigger search
  },
  grep = {
    literal_flag = '-F', -- Default literal search flag
    format = '%f:%l:%c:%m', -- Default grep format
    -- Built-in grep command fallback
    cmd = 'grep -n -r --exclude=%s . $*',
  },
  -- ripgrep configuration
  rg = {
    cmd = "rg --vimgrep --no-heading --smart-case --hidden --follow -g '!{%s}' -uu $*",
    literal_flag = '-F',
    format = '%f:%l:%c:%m,%f:%l:%m',
  },
  -- silver searcher configuration
  ag = {
    cmd = "ag --vimgrep --smart-case --hidden --follow --ignore '!{%s}' $*",
    literal_flag = '-Q',
    format = '%f:%l:%c:%m',
  },
}

-- Set grepprg based on available tools
local function setup_grep(opts)
  local wildignore = vim.o.wildignore

  if vim.fn.executable 'rg' == 1 then
    vim.o.grepprg = string.format(opts.rg.cmd, wildignore)
    vim.g.grep_literal_flag = opts.rg.literal_flag
    vim.o.grepformat = opts.rg.format
  elseif vim.fn.executable 'ag' == 1 then
    vim.o.grepprg = string.format(opts.ag.cmd, wildignore)
    vim.g.grep_literal_flag = opts.ag.literal_flag
    vim.o.grepformat = opts.ag.format
  else
    vim.o.grepprg = string.format(opts.grep.cmd, vim.fn.shellescape(wildignore))
    vim.g.grep_literal_flag = opts.grep.literal_flag
    vim.o.grepformat = opts.grep.format
  end
end

local function rip_grep_cword(bang, visualmode, search_word)
  if visualmode then
    search_word = require('user.utils').get_visual_selection()
  end

  if not search_word or search_word == '' then
    search_word = vim.fn.expand '<cword>'
  end

  local search_message_literally = 'for ' .. search_word
  if bang then
    search_message_literally = 'literally for ' .. search_word
    search_word = (vim.g.grep_literal_flag or '') .. ' -- ' .. vim.fn.shellescape(search_word)
  end

  vim.api.nvim_echo({ { ('Searching ' .. search_message_literally), 'None' } }, false, {})
  vim.cmd('silent grep! ' .. search_word)
end

function M.setup(opts)
  opts = vim.tbl_deep_extend('force', default_opts, opts or {})

  setup_grep(opts)

  -- Create user commands
  vim.api.nvim_create_user_command('RipGrepCWORD', function(cmd_opts)
    rip_grep_cword(cmd_opts.bang, false, cmd_opts.args)
  end, { bang = true, range = true, nargs = '?', complete = 'file_in_path' })

  vim.api.nvim_create_user_command('RipGrepCWORDVisual', function(cmd_opts)
    rip_grep_cword(cmd_opts.bang, true, cmd_opts.args)
  end, { bang = true, range = true, nargs = '?', complete = 'file_in_path' })

  -- Map keys
  vim.keymap.set({ 'n', 'v' }, opts.keymap.search, function()
    return vim.fn.mode() == 'v' and ':RipGrepCWORDVisual!<cr>' or ':RipGrepCWORD!<Space>'
  end, { remap = false, expr = true })
end

return M
