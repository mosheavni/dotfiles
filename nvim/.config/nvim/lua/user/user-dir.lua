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

-- Mappings have no plugin dependency: call this synchronously and early
-- (before DeferredPluginsLoaded) so its `FileType directory` autocmd exists
-- ahead of any directory buffer Neovim might open during startup.
function M.setup()
  if vim.g.loaded_user_dir then
    return
  end
  vim.g.loaded_user_dir = true

  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('UserDir', { clear = true }),
    pattern = 'directory',
    desc = 'Prefill ex-commands for the entry under the cursor',
    callback = function(ev)
      local function map(lhs, fn, desc)
        vim.keymap.set('n', lhs, fn, { buffer = ev.buf, silent = true, desc = desc })
      end
      map('r', rename_prompt, 'Prefill :!mv rename command for entry under cursor')
      map('a', new_file_prompt, 'Prefill :edit %/ to create a new file')
      map('d', delete_prompt, 'Prefill :!rm delete command for entry under cursor')
      map('Z', extract_prompt, 'Extract archive under cursor')
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
