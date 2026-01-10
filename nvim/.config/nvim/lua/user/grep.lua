local M = {}

-- Default options
local default_opts = {
  keymap = {
    search = '<C-f>', -- The keybinding to trigger search
  },
  grep = {
    literal_flag = '-F', -- Default literal search flag
    format = '%f:%l:%m', -- Default grep format
    -- Built-in grep command fallback
    cmd = 'grep -inr %s $* .',
  },
  -- ripgrep configuration
  rg = {
    cmd = "rg --vimgrep --no-heading --smart-case --hidden --no-ignore-vcs --follow -g '!{%s}' $*",
    literal_flag = '-F',
    format = '%f:%l:%c:%m,%f:%l:%m',
  },
  -- silver searcher configuration
  ag = {
    cmd = 'ag --vimgrep --smart-case --hidden --skip-vcs-ignores --follow %s $*',
    literal_flag = '-Q',
    format = '%f:%l:%c:%m',
  },
}

-- Convert wildignore glob pattern to base name for ag
-- e.g., "**/.git/**" -> ".git", "**/node_modules/**" -> "node_modules"
local function glob_to_ag_pattern(pattern)
  -- Extract base name from **/.name/** patterns
  local base = pattern:match '%*%*/(%.?[^/]+)/%*%*'
  if base then
    return base
  end
  -- Return pattern as-is for file patterns like *.pyc
  return pattern
end

-- Convert wildignore to ag --ignore flags
local function wildignore_to_ag_ignores(wildignore)
  local ignores = {}
  for pattern in wildignore:gmatch '[^,]+' do
    local ag_pattern = glob_to_ag_pattern(pattern)
    table.insert(ignores, '--ignore ' .. vim.fn.shellescape(ag_pattern))
  end
  return table.concat(ignores, ' ')
end

-- Convert wildignore to grep --exclude/--exclude-dir flags
local function wildignore_to_grep_excludes(wildignore)
  local excludes = {}
  for pattern in wildignore:gmatch '[^,]+' do
    -- Check if it's a directory pattern like **/.git/**
    local dir = pattern:match '%*%*/(%.?[^/]+)/%*%*'
    if dir then
      table.insert(excludes, '--exclude-dir=' .. vim.fn.shellescape(dir))
    else
      -- File pattern like *.pyc
      table.insert(excludes, '--exclude=' .. vim.fn.shellescape(pattern))
    end
  end
  return table.concat(excludes, ' ')
end

-- Set grepprg based on available tools
local function setup_grep(opts)
  local wildignore = vim.o.wildignore

  if vim.fn.executable 'rg' == 1 then
    vim.o.grepprg = string.format(opts.rg.cmd, wildignore)
    vim.g.grep_literal_flag = opts.rg.literal_flag
    vim.o.grepformat = opts.rg.format
  elseif vim.fn.executable 'ag' == 1 then
    local ag_ignores = wildignore_to_ag_ignores(wildignore)
    vim.o.grepprg = string.format(opts.ag.cmd, ag_ignores)
    vim.g.grep_literal_flag = opts.ag.literal_flag
    vim.o.grepformat = opts.ag.format
  else
    local grep_excludes = wildignore_to_grep_excludes(wildignore)
    vim.o.grepprg = string.format(opts.grep.cmd, grep_excludes)
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

  local search_message = 'for ' .. search_word
  if bang then
    search_message = 'literally for ' .. search_word
    search_word = (vim.g.grep_literal_flag or '') .. ' -- ' .. vim.fn.shellescape(search_word)
  else
    search_word = '-- ' .. vim.fn.shellescape(search_word)
  end

  local cmd = vim.o.grepprg:gsub('%$%*', search_word)
  vim.notify(cmd, vim.log.levels.INFO)
  vim.print('Searching ' .. search_message .. '...')
  vim.cmd('silent grep! ' .. search_word)
  vim.cmd 'cwindow'
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
