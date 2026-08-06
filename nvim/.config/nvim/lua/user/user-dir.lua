-- Icon adornment + ex-command mappings for the native `nvim.dir` directory
-- listing (`:h dir`). Icons come from nvim-web-devicons; override with
-- `vim.g.user_dir_icon_provider(line) -> icon, icon_hl`.

local M = {}

-- icon resolution ============================================================

local FOLDER_ICON, FOLDER_HL = '', 'Directory'

---@type fun(line: string): string[]
local get_line_chunk = vim.func._memoize('concat', function(line)
  local icon, icon_hl
  if vim.g.user_dir_icon_provider then
    icon, icon_hl = vim.g.user_dir_icon_provider(line)
  elseif line:sub(-1) == '/' then
    icon, icon_hl = FOLDER_ICON, FOLDER_HL
  else
    icon, icon_hl = require('nvim-web-devicons').get_icon(line, vim.fs.ext(line), { default = true })
  end
  return { { icon, icon_hl }, { ' ' } }
end)

---@type table<integer, table<integer, integer>>
local extmark_ids = {}

-- ex-command mappings =========================================================

-- The buffer's own name is the listing's absolute directory, which may
-- differ from Neovim's cwd -- build full paths so shell commands land on
-- the right file regardless.
---@param name string
---@return string
local function entry_path(name)
  return vim.fs.joinpath(vim.api.nvim_buf_get_name(0), name)
end

-- Prefill the command line with `:!mv {entry} {entry}`, cursor at the end,
-- ready to backspace the destination name and retype it.
local function rename_prompt()
  local name = vim.api.nvim_get_current_line()
  if name == '' then
    return
  end
  local escaped = vim.fn.fnameescape(entry_path(name))
  vim.fn.feedkeys((':!mv %s %s'):format(escaped, escaped), 'n')
end

-- Prefill the command line with `:edit %/`, ready to type the new file's
-- name; `%` expands to the listing's directory on execution.
local function new_file_prompt()
  vim.fn.feedkeys(':edit %/', 'n')
end

-- Prefill the command line with `:!rm {entry}` (`-r` for directories);
-- nothing happens until the user reviews it and presses <CR>.
local function delete_prompt()
  local name = vim.api.nvim_get_current_line()
  if name == '' then
    return
  end
  local is_dir = name:sub(-1) == '/'
  local escaped = vim.fn.fnameescape(entry_path(name))
  vim.fn.feedkeys((':!rm %s%s'):format(is_dir and '-r ' or '', escaped), 'n')
end

-- Extract the archive under the cursor into the listing's directory.
-- Adapted from the `Z` mapping in plugins/tree.lua.
local function extract_prompt()
  local name = vim.api.nvim_get_current_line()
  if name == '' or name:sub(-1) == '/' then
    return
  end
  local dir = vim.api.nvim_buf_get_name(0)
  local file_path = entry_path(name)
  local file_type = vim.trim(vim.system({ 'file', '--mime-type', '-b', file_path }, { text = true }):wait().stdout)

  local function run(cmd)
    local ok = vim.system(cmd, { text = true }):wait()
    if ok.code ~= 0 then
      vim.notify('Extraction failed: ' .. table.concat(cmd, ' '), vim.log.levels.ERROR)
      return false
    end
    return true
  end

  if file_type == 'application/gzip' then
    run { 'tar', 'xzf', file_path, '-C', dir }
  elseif file_type == 'application/zip' then
    run { 'unzip', file_path, '-d', dir }
  elseif file_type == 'application/x-bzip2' then
    run { 'tar', 'xjf', file_path, '-C', dir }
  else
    vim.notify('Unsupported file type for extraction: ' .. file_type, vim.log.levels.WARN)
    return
  end
  vim.notify('Extracted: ' .. file_path)
end

-- open entry (nvim-tree-style) ================================================

-- Label each other normal window in the tab with a letter (via winbar --
-- 'laststatus=3' makes per-window statusline unusable for this) and block
-- for one keypress to pick a target.
-- Returns a winid, `nil` when there's nothing to pick from (caller should
-- split instead), or `false` when the user cancelled the pick.
---@return integer|false|nil
local function pick_window()
  local other_wins = vim.tbl_filter(function(w)
    return w ~= vim.api.nvim_get_current_win() and vim.fn.win_gettype(w) == ''
  end, vim.api.nvim_tabpage_list_wins(0))

  if #other_wins <= 1 then
    return other_wins[1]
  end

  local letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  local by_letter = {}
  local saved_winbar = {}
  for i, w in ipairs(other_wins) do
    local letter = letters:sub(i, i)
    by_letter[letter] = w
    saved_winbar[w] = vim.wo[w].winbar
    vim.wo[w].winbar = '%#IncSearch#%=' .. letter .. '%='
  end
  vim.cmd 'redraw'
  local ok, char = pcall(vim.fn.getcharstr)
  for w, winbar in pairs(saved_winbar) do
    if vim.api.nvim_win_is_valid(w) then
      vim.wo[w].winbar = winbar
    end
  end
  return ok and (by_letter[char:upper()] or false) or false
end

-- Directories navigate the listing in place; files open in another window --
-- the sole other window if there's exactly one, a picked one if there are
-- several, or a new split to the right if the listing is the only window.
local function open_entry()
  local name = vim.api.nvim_get_current_line()
  if name == '' then
    return
  end
  local path = entry_path(name)
  if name:sub(-1) == '/' then
    vim.api.nvim_cmd({ cmd = 'edit', args = { path } }, {})
    return
  end

  local win = pick_window()
  if win == false then
    return
  end
  if win == nil then
    vim.api.nvim_cmd({ cmd = 'vsplit', args = { path }, mods = { split = 'botright' } }, {})
  else
    vim.api.nvim_set_current_win(win)
    vim.api.nvim_cmd({ cmd = 'edit', args = { path } }, {})
  end
end

-- Open the entry under the cursor in a new split, ignoring other windows.
---@param split_cmd 'vsplit'|'split'
---@param mods? table forced placement (e.g. `{ split = 'botright' }`)
---@return fun()
local function open_entry_split(split_cmd, mods)
  return function()
    local name = vim.api.nvim_get_current_line()
    if name == '' then
      return
    end
    vim.api.nvim_cmd({ cmd = split_cmd, args = { entry_path(name) }, mods = mods }, {})
  end
end

-- Guards the `FileType directory` handler below against redirecting a split
-- this function is itself in the middle of creating (a brand-new directory
-- opens through the same nvim.dir setup chain, synchronously, from within
-- the `vim.cmd(...)` call below).
local creating_sidebar = false

-- Open `dir` in the tab's directory-listing sidebar: reuses one if it's
-- already open, otherwise creates a new narrow split on the left (nvim-tree
-- style).
---@param dir string
---@param select_name? string entry to position the cursor on
function M.open_sidebar(dir, select_name)
  local dir_win
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == 'directory' then
      dir_win = w
      break
    end
  end

  if dir_win then
    vim.api.nvim_set_current_win(dir_win)
    vim.cmd('edit ' .. vim.fn.fnameescape(dir))
  else
    local width = math.floor(vim.o.columns * 0.2)
    creating_sidebar = true
    vim.cmd(('leftabove %dvsplit %s'):format(width, vim.fn.fnameescape(dir)))
    creating_sidebar = false
    vim.w[0].user_dir_sidebar = true
  end

  if select_name then
    vim.fn.search([[\C\m^\V]] .. vim.fn.escape(select_name, [[\]]) .. [[\m$]], 'cw')
  end
end

-- Overriding this Plug (rather than buffer-local `<CR>`) is the documented
-- customization point (`:h dir-mappings`) and, critically, the only one that
-- sticks: nvim.dir's own `set_maps()` unconditionally re-sets buffer-local
-- `<CR>` -> `<Plug>(nvim-dir-open)` on every listing open, so a buffer-local
-- `<CR>` override loses that race. Deferred to VimEnter so it runs after
-- plugin/dir.lua's own registration (`:h startup` step 12 vs. 19).
local function override_open_plug()
  vim.keymap.set('n', '<Plug>(nvim-dir-open)', open_entry, {
    silent = true,
    desc = 'Open entry (dirs in place, files in another window)',
  })
end

-- Mappings have no plugin dependency: call this synchronously and early
-- (before DeferredPluginsLoaded) so its `FileType directory` autocmd exists
-- ahead of any directory buffer Neovim might open during startup.
function M.setup()
  if vim.g.loaded_user_dir then
    return
  end
  vim.g.loaded_user_dir = true

  if vim.v.vim_did_enter == 1 then
    override_open_plug()
  else
    vim.api.nvim_create_autocmd('VimEnter', { once = true, callback = override_open_plug })
  end

  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('UserDir', { clear = true }),
    pattern = 'directory',
    desc = 'Route a bare `:edit dir` into the sidebar; prefill ex-commands',
    callback = function(ev)
      -- A directory opened in a window that isn't the sidebar (e.g. a bare
      -- `:edit .`) -- restore what was there and route it into the sidebar.
      if not creating_sidebar and not vim.w[0].user_dir_sidebar then
        local dir = vim.api.nvim_buf_get_name(ev.buf)
        local alt = vim.fn.bufnr '#'
        if alt > 0 and alt ~= ev.buf and vim.fn.buflisted(alt) == 1 then
          vim.api.nvim_win_set_buf(0, alt)
        else
          vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(true, false))
        end
        M.open_sidebar(dir)
      end

      local function map(lhs, fn, desc)
        vim.keymap.set('n', lhs, fn, { buffer = ev.buf, silent = true, desc = desc })
      end
      map('r', rename_prompt, 'Prefill :!mv rename command for entry under cursor')
      map('a', new_file_prompt, 'Prefill :edit %/ to create a new file')
      map('d', delete_prompt, 'Prefill :!rm delete command for entry under cursor')
      map('Z', extract_prompt, 'Extract archive under cursor')
      map('v', open_entry_split('vsplit', { split = 'botright' }), 'Open entry in a vertical split (rightmost)')
      map('s', open_entry_split('split', nil), 'Open entry in a horizontal split')
    end,
  })
end

-- Icons depend on nvim-web-devicons: call this once it's loaded (from
-- DeferredPluginsLoaded), so the decoration provider never races the plugin.
function M.setup_icons()
  local ns = vim.api.nvim_create_namespace 'user-dir'
  vim.api.nvim_set_decoration_provider(ns, {
    on_win = function(_, _, buf, _, _)
      if vim.bo[buf].filetype ~= 'directory' then
        return false
      end
    end,
    on_range = function(_, _, buf, start_row, _, end_row, _)
      if not extmark_ids[buf] then
        extmark_ids[buf] = {}
        vim.api.nvim_create_autocmd('BufDelete', {
          buf = buf,
          callback = function()
            extmark_ids[buf] = nil
          end,
        })
      end
      local lines = vim.api.nvim_buf_get_lines(buf, start_row, end_row, false)
      for i, line in ipairs(lines) do
        local lnum = start_row + i - 1
        extmark_ids[buf][lnum] = vim.api.nvim_buf_set_extmark(buf, ns, lnum, 0, {
          virt_text = get_line_chunk(line),
          virt_text_pos = 'inline',
          id = extmark_ids[buf][lnum],
        })
      end
    end,
  })
end

return M
