vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-----------------
-- Colorscheme --
-----------------
require('user.colorscheme').setup()

--------------
-- Put Text --
--------------
function _G.put_text(...)
  local objects = {}
  for i = 1, select('#', ...) do
    local v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  local lines = vim.split(table.concat(objects, '\n'), '\n')
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  vim.fn.append(lnum, lines)
  return ...
end

------------------------
-- Write to temp file --
------------------------
---Write a temporary file with specified options
---@param opts? {should_delete?: boolean, ft?: string, new?: boolean, vertical?: boolean}
---@return string tmp The path to the temporary file
function _G.tmp_write(opts)
  opts = opts or {}
  local final_opts = vim.tbl_deep_extend('force', {
    should_delete = true,
    ft = nil,
    new = true,
    vertical = false,
  }, opts)

  local tmp = vim.fn.tempname()

  if final_opts.new then
    vim.cmd(final_opts.vertical and 'vnew' or 'new')
  end

  if final_opts.ft then
    local extension = require('user.utils').filetype_to_extension[final_opts.ft] or final_opts.ft
    vim.bo.filetype = final_opts.ft
    tmp = tmp .. '.' .. extension
  end

  vim.cmd('write ' .. vim.fn.fnameescape(tmp))
  vim.cmd 'edit'

  if final_opts.should_delete then
    -- global on purpose: a buffer-local autocmd for VimLeavePre only fires
    -- when that buffer is current at exit, leaking the temp file otherwise
    vim.api.nvim_create_autocmd('VimLeavePre', {
      callback = function()
        vim.fn.delete(tmp)
      end,
    })
  end
  return tmp
end

--------------------
-- Yaml <--> Json --
--------------------
vim.api.nvim_create_user_command('Yaml2Json', function()
  vim.cmd [[%!yq -ojson]]
  vim.bo.filetype = 'json'
end, {})

vim.api.nvim_create_user_command('Json2Yaml', function()
  vim.cmd [[%!yq -P]]
  vim.bo.filetype = 'yaml'
end, {})

-----------------
-- Where am I? --
-----------------
vim.api.nvim_create_user_command('Whereami', function()
  vim.net.request('http://ipconfig.io/json', {}, function(err, result)
    vim.schedule(function()
      if err then
        vim.notify('Failed to fetch location data: ' .. err, vim.log.levels.ERROR)
        return
      end
      local ok, country_data = pcall(vim.json.decode, result.body)
      if not ok then
        vim.notify('Failed to parse location data', vim.log.levels.ERROR)
        return
      end
      local iso = country_data.country_iso
      local country = country_data.country
      local emoji = require('user.utils').country_os_to_emoji(iso)
      if not emoji then
        emoji = '🌎'
      end
      local msg = string.format([[You're in %s %s]], country, emoji)
      vim.notify(msg, vim.log.levels.INFO, { title = 'Where am I?', icon = emoji })
    end)
  end)
end, {})

------------------------
-- Change indentation --
------------------------
vim.keymap.set('n', 'cii', function()
  vim.ui.input({ prompt = 'Enter new indent❯ ' }, function(indent_size)
    local indent_size_normalized = tonumber(indent_size)
    if not indent_size_normalized then
      return
    end
    vim.opt_local.shiftwidth = indent_size_normalized
    vim.opt_local.softtabstop = indent_size_normalized
    vim.opt_local.tabstop = indent_size_normalized
  end)
end, { desc = 'Change indentation size' })

-------------------------
-- Diff with last save --
-------------------------
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
    vim.keymap.set('n', 'q', function()
      vim.cmd 'diffoff!'
      vim.api.nvim_buf_delete(scratch, { force = true })
      vim.keymap.del('n', 'q', { buffer = start })
    end, { buffer = buf })
  end
end, {})
vim.keymap.set('n', '<leader>ds', ':DiffWithSaved<cr>', { remap = false, silent = true, desc = 'Diff with saved file' })

--------------
-- Difftool --
--------------
vim.api.nvim_create_user_command('DirDiff', function(opts)
  if vim.tbl_count(opts.fargs) ~= 2 then
    vim.notify('DirDiff requires exactly two directory arguments', vim.log.levels.ERROR)
    return
  end

  if not opts.bang then
    vim.cmd 'tabnew'
  end

  vim.cmd.packadd 'nvim.difftool'
  require('difftool').open(opts.fargs[1], opts.fargs[2], {
    method = 'auto',
    rename = { detect = false },
    ignore = { '.git' },
  })
end, { complete = 'dir', nargs = '*', bang = true, desc = 'Diff two directories (bang to not open in a new tab)' })

-----------------------
-- Visual calculator --
-----------------------
vim.cmd [[
function s:VisualCalculator() abort
  let save_pos = getpos('.')
  let first_expr = GetMotion('gv')

  " Get arithmetic operation from user input
  call inputsave()
  let operation = input('Enter operation: ')
  call inputrestore()

  " Calculate final result
  let fin_result = eval(str2nr(first_expr) . operation)

  " Replace
  call ReplaceMotion('gv', fin_result)
  call setpos('.', save_pos)
endfunction
command! -range VisualCalculator call <SID>VisualCalculator()
vmap <c-r> :VisualCalculator<cr>
]]

--------------
-- Titleize --
--------------
vim.api.nvim_create_user_command('Titleize', function(opts)
  local title_char = '-'
  if opts.args ~= '' then
    title_char = opts.args
  end
  local current_line = vim.api.nvim_get_current_line()
  local indent = string.match(current_line, '^%s*')
  current_line = vim.trim(current_line)
  local r, _ = unpack(vim.api.nvim_win_get_cursor(0))

  -- delete line
  vim.api.nvim_del_current_line()

  local top_bottom = indent .. title_char:rep(#current_line + 6)
  vim.api.nvim_buf_set_lines(0, r - 1, r - 1, false, {
    top_bottom,
    indent .. title_char:rep(2) .. ' ' .. current_line .. ' ' .. title_char:rep(2),
    top_bottom,
  })
end, { nargs = '?' })

---------
-- Say --
---------
vim.api.nvim_create_user_command('Say', function(opts)
  local text

  -- If a range is provided (visual selection or line range)
  if opts.range > 0 then
    text = require('user.utils').get_visual_selection()
  -- Otherwise use the provided arguments
  elseif opts.args ~= '' then
    text = opts.args
  else
    vim.notify('Say: No text provided', vim.log.levels.WARN)
    return
  end

  -- Pipe to say command
  vim.system({ 'say', text }, { text = true })
end, {
  range = true,
  nargs = '?',
  desc = 'Read text using macOS say command',
})

-----------------------
-- Sort inside block --
-----------------------
vim.cmd [[
function! s:SortInBlock() abort
  execute "normal viboj\<Esc>"
  '<,'>sort
endfunction
command! SortInBlock call s:SortInBlock()
]]

-----------------------
-- Parse Certificate --
-----------------------
local function parse_cert()
  local cert = require('user.utils').get_visual_selection()
  if not cert or vim.trim(cert) == '' then
    vim.notify('ParseCert: No certificate selected', vim.log.levels.WARN)
    return
  end

  -- Strip leading indentation so openssl gets a clean PEM block
  cert = table.concat(
    vim.tbl_map(function(line)
      return (line:gsub('^%s+', ''))
    end, vim.split(cert, '\n')),
    '\n'
  )

  local result = vim.system({ 'openssl', 'x509', '-noout', '-text' }, { stdin = cert, text = true }):wait()
  if result.code ~= 0 then
    vim.notify('ParseCert: Failed to parse certificate\n' .. vim.trim(result.stderr or ''), vim.log.levels.ERROR)
    return
  end

  local lines = vim.split(vim.trim(result.stdout or ''), '\n')
  local float = require('user.float').new()
  float.refresh(function()
    return lines
  end, function(buf_id)
    local width, height = float.buffer_default_dimensions(buf_id, 0.8)
    height = math.min(height, vim.o.lines - 4)
    return {
      relative = 'editor',
      width = width,
      height = height,
      col = math.floor((vim.o.columns - width) / 2),
      row = math.floor((vim.o.lines - height) / 2),
      anchor = 'NW',
      style = 'minimal',
      border = 'rounded',
      title = ' Certificate ',
    }
  end)

  -- Focus the float so it can be scrolled and closed with q/<esc>
  if float.is_shown() then
    vim.api.nvim_set_current_win(float.cache.win_id)
    for _, key in ipairs { 'q', '<esc>' } do
      vim.keymap.set('n', key, float.close, { buffer = float.cache.buf_id, nowait = true })
    end
  end
end

vim.api.nvim_create_user_command('ParseCert', parse_cert, { range = true, desc = 'Parse selected certificate and show details in a float' })

-------------
-- ACTIONS --
-------------
require('user.menu').add_actions('YAML', {
  ['Convert buffer Yaml to Json (:Yaml2Json)'] = function()
    vim.cmd [[Yaml2Json]]
  end,
})
require('user.menu').add_actions('JSON', {
  ['Convert buffer Json to Yaml (:Json2Yaml)'] = function()
    vim.cmd [[Json2Yaml]]
  end,
})
require('user.menu').add_actions('Diff', {
  ['Diff with saved file (<leader>ds | :DiffWithSaved)'] = function()
    vim.cmd [[DiffWithSaved]]
  end,
  ['Diff two directories (:DirDiff)'] = function()
    vim.ui.input({ prompt = 'Left dir❯ ', completion = 'dir' }, function(left)
      if not left or left == '' then
        return
      end
      vim.ui.input({ prompt = 'Right dir❯ ', completion = 'dir' }, function(right)
        if not right or right == '' then
          return
        end
        vim.cmd('DirDiff ' .. vim.fn.fnameescape(left) .. ' ' .. vim.fn.fnameescape(right))
      end)
    end)
  end,
})
require('user.menu').add_actions('Misc', {
  ['Where am I? (:Whereami)'] = function()
    vim.cmd [[Whereami]]
  end,
  ['Visual Calculator (<C-r> | :VisualCalculator)'] = function()
    vim.cmd [[VisualCalculator]]
  end,
  ['Titleize current line (:Titleize)'] = function()
    vim.ui.input({ prompt = 'Title char (default -)❯ ' }, function(char)
      vim.cmd('Titleize ' .. (char or ''))
    end)
  end,
  ['Say text via macOS (:Say)'] = function()
    vim.ui.input({ prompt = 'Text to say❯ ' }, function(text)
      if text and text ~= '' then
        vim.cmd('Say ' .. text)
      end
    end)
  end,
  ['Sort lines in surrounding block (:SortInBlock)'] = function()
    vim.cmd [[SortInBlock]]
  end,
  ['Parse selected certificate (:ParseCert)'] = function()
    vim.cmd [['<,'>ParseCert]]
  end,
})

------------------
-- User Modules --
------------------
require('user.input').setup()
require('user.search-count').setup()
require('user.tabular-v2').setup()
require('user.projects').setup()
require('user.number-separators').setup()
require('user.terminal').setup()
require('user.yank-ring').setup()
require('user.run-buffer').setup()
require('user.grep').setup()
require('user.lister').setup()
require('user.figlet').setup()
require('user.open-url').setup()
require('user.gitbrowse').setup()
require('user.easymotion').setup()
