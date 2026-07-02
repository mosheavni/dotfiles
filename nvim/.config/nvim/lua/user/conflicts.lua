local git = require 'user.git'
local utils = require 'user.utils'

local M = {}

--------------------------------------------------------------------------------
-- Config
--------------------------------------------------------------------------------

local default_config = {
  enabled = true,
  highlights = true,
  keymaps = true,
}

local config = vim.deepcopy(default_config)

local buffer_keymaps = {
  { lhs = '[x', fn = 'prev_conflict', desc = 'Previous Git conflict' },
  { lhs = ']x', fn = 'next_conflict', desc = 'Next Git conflict' },
  { lhs = '<leader>go', fn = 'take_head', desc = 'Take HEAD in conflict' },
  { lhs = '<leader>gt', fn = 'take_origin', desc = 'Take ORIGIN in conflict' },
  { lhs = '<leader>gb', fn = 'take_both', desc = 'Take BOTH in conflict' },
  { lhs = '<leader>gq', fn = 'populate_quickfix', desc = 'List Git conflicts' },
}

local MARKER_HEAD = '^<<<<<<<'
local MARKER_BASE = '^|||||||'
local MARKER_SEP = '^======='
local MARKER_END = '^>>>>>>>'

local HL_HEAD = 'DiffText'
local HL_BASE = 'DiffChange'
local HL_ORIGIN = 'DiffAdd'
local HL_SEPARATOR = 'NonText'

local hl_ns = vim.api.nvim_create_namespace 'user.conflicts'
local augroup = vim.api.nvim_create_augroup('UserConflicts', { clear = true })

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

local nav_index = 0

local watcher_state = {
  current_dir = nil,
  handles = {},
}

---@class ConflictBufferCache
---@field blocks { start_line: integer, end_line: integer }[]
---@field tick integer
---@field bufnr integer|nil

local function create_visited_buffers()
  return setmetatable({}, {
    __index = function(t, k)
      if type(k) == 'number' then
        local name = vim.api.nvim_buf_get_name(k)
        if name ~= '' then
          return rawget(t, name)
        end
      end
    end,
  })
end

---@type table<string, ConflictBufferCache>
local visited_buffers = create_visited_buffers()

--------------------------------------------------------------------------------
-- Parse (pure, testable)
--------------------------------------------------------------------------------

function M.find_conflict_bounds(lines, cursor_line)
  for i = cursor_line, 1, -1 do
    if lines[i]:match(MARKER_HEAD) then
      for j = i, #lines do
        if lines[j]:match(MARKER_END) then
          if cursor_line >= i and cursor_line <= j then
            return i, j
          end
          break
        end
      end
    end
  end
end

function M.parse_conflict_block(lines, start_line, end_line)
  local head_lines, origin_lines = {}, {}
  local mode = nil

  for i = start_line, end_line do
    local line = lines[i]
    if line:match(MARKER_HEAD) then
      mode = 'head'
    elseif line:match(MARKER_BASE) then
      mode = 'base'
    elseif line:match(MARKER_SEP) then
      mode = 'origin'
    elseif not line:match(MARKER_END) then
      if mode == 'head' then
        table.insert(head_lines, line)
      elseif mode == 'origin' then
        table.insert(origin_lines, line)
      end
    end
  end

  return head_lines, origin_lines
end

function M.find_all_conflict_blocks(lines)
  local blocks = {}
  local i = 1
  while i <= #lines do
    if lines[i]:match(MARKER_HEAD) then
      local found_end = false
      for j = i, #lines do
        if lines[j]:match(MARKER_END) then
          table.insert(blocks, { start_line = i, end_line = j })
          i = j + 1
          found_end = true
          break
        end
      end
      if not found_end then
        break
      end
    else
      i = i + 1
    end
  end
  return blocks
end

function M.build_highlights(lines)
  local highlights = {}
  local section_hl = {
    head = HL_HEAD,
    base = HL_BASE,
    origin = HL_ORIGIN,
  }

  for _, block in ipairs(M.find_all_conflict_blocks(lines)) do
    local mode = nil
    for i = block.start_line, block.end_line do
      local line = lines[i]
      if line:match(MARKER_HEAD) then
        mode = 'head'
        table.insert(highlights, { line = i, hl = HL_HEAD })
      elseif line:match(MARKER_BASE) then
        mode = 'base'
        table.insert(highlights, { line = i, hl = HL_BASE })
      elseif line:match(MARKER_SEP) then
        mode = 'origin'
        table.insert(highlights, { line = i, hl = HL_SEPARATOR })
      elseif line:match(MARKER_END) then
        table.insert(highlights, { line = i, hl = HL_ORIGIN })
      elseif mode then
        table.insert(highlights, { line = i, hl = section_hl[mode] })
      end
    end
  end

  return highlights
end

local function conflict_replacement(lines, cursor_line, mode)
  local start_line, end_line = M.find_conflict_bounds(lines, cursor_line)
  if not start_line then
    return
  end

  local head_lines, origin_lines = M.parse_conflict_block(lines, start_line, end_line)
  local replacement = {}
  if mode == 'head' then
    replacement = head_lines
  elseif mode == 'origin' then
    replacement = origin_lines
  elseif mode == 'both' then
    vim.list_extend(replacement, head_lines)
    vim.list_extend(replacement, origin_lines)
  end

  return replacement, start_line, end_line
end

function M.apply_conflict_resolution(lines, cursor_line, mode)
  local replacement, start_line, end_line = conflict_replacement(lines, cursor_line, mode)
  if not replacement then
    return nil
  end

  local result = {}
  for i = 1, start_line - 1 do
    table.insert(result, lines[i])
  end
  vim.list_extend(result, replacement)
  for i = end_line + 1, #lines do
    table.insert(result, lines[i])
  end

  return result, start_line
end

--------------------------------------------------------------------------------
-- Buffer (highlights, attach/detach, decoration provider)
--------------------------------------------------------------------------------

local detach_buffer

local function clear_highlights(bufnr)
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_clear_namespace(bufnr, hl_ns, 0, -1)
  end
end

local function apply_highlights(bufnr, lines)
  clear_highlights(bufnr)
  if not config.highlights then
    return
  end
  for _, item in ipairs(M.build_highlights(lines)) do
    vim.api.nvim_buf_set_extmark(bufnr, hl_ns, item.line - 1, 0, {
      line_hl_group = item.hl,
      priority = 100,
    })
  end
end

local function attach_buffer_keymaps(bufnr)
  if not config.keymaps or vim.b[bufnr].conflicts_mappings_set then
    return
  end

  for _, map in ipairs(buffer_keymaps) do
    vim.keymap.set('n', map.lhs, M[map.fn], { buffer = bufnr, desc = map.desc })
  end
  vim.b[bufnr].conflicts_mappings_set = true
end

local function detach_buffer_keymaps(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) or not vim.b[bufnr].conflicts_mappings_set then
    return
  end

  for _, map in ipairs(buffer_keymaps) do
    pcall(vim.keymap.del, 'n', map.lhs, { buffer = bufnr })
  end
  vim.b[bufnr].conflicts_mappings_set = false
end

detach_buffer = function(bufnr)
  clear_highlights(bufnr)
  detach_buffer_keymaps(bufnr)
end

local function parse_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  if not visited_buffers[name] then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local blocks = M.find_all_conflict_blocks(lines)
  local cache = visited_buffers[name]

  cache.blocks = blocks
  cache.bufnr = bufnr
  cache.tick = vim.b[bufnr].changedtick

  if #blocks > 0 then
    apply_highlights(bufnr, lines)
    attach_buffer_keymaps(bufnr)
  else
    detach_buffer(bufnr)
  end
end

local function process_buffer(bufnr)
  if not visited_buffers[bufnr] then
    return
  end
  if visited_buffers[bufnr].tick == vim.b[bufnr].changedtick then
    return
  end
  parse_buffer(bufnr)
end

local function register_decoration_provider()
  vim.api.nvim_set_decoration_provider(hl_ns, {
    on_win = function(_, _, bufnr, _, _)
      if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= '' then
        return
      end
      if visited_buffers[bufnr] then
        process_buffer(bufnr)
      end
    end,
  })
end

--------------------------------------------------------------------------------
-- Git cache (unmerged file list, watcher)
--------------------------------------------------------------------------------

local function unmerged_diff_args(git_root)
  return {
    '-C',
    git_root,
    'diff',
    ('--line-prefix=%s/'):format(git_root),
    '--name-only',
    '--diff-filter=U',
  }
end

---@param stdout string|nil
---@return table<string, boolean>
function M.parse_unmerged_paths(stdout)
  local files = {}
  for line in (stdout or ''):gmatch '[^\r\n]+' do
    if #line > 0 then
      files[line] = true
    end
  end
  return files
end

local function get_unmerged_sync(git_root)
  if not git_root or git_root == '' then
    return {}
  end
  local result = vim.system({ 'git', unpack(unmerged_diff_args(git_root)) }, { text = true }):wait()
  if result.code ~= 0 then
    return {}
  end
  return M.parse_unmerged_paths(result.stdout)
end

local function get_unmerged_async(git_root, cb)
  if not git_root or git_root == '' then
    return cb {}
  end
  vim.system({ 'git', unpack(unmerged_diff_args(git_root)) }, { text = true }, function(obj)
    vim.schedule(function()
      if obj.code ~= 0 then
        cb {}
      else
        cb(M.parse_unmerged_paths(obj.stdout))
      end
    end)
  end)
end

local function apply_repo_unmerged(files, repo)
  for name, cache in pairs(visited_buffers) do
    if type(name) == 'string' and vim.startswith(name, repo) and not files[name] then
      if cache.bufnr then
        detach_buffer(cache.bufnr)
      end
      visited_buffers[name] = nil
    end
  end
  for path in pairs(files) do
    visited_buffers[path] = visited_buffers[path] or { blocks = {}, tick = -1 }
  end
end

local function sync_fetch_conflicts()
  local git_root = git.get_toplevel_sync()
  if git_root == '' then
    return
  end
  apply_repo_unmerged(get_unmerged_sync(git_root), git_root)
end

function M.fetch_conflicts(_buf)
  local git_root = git.get_toplevel_sync()
  if git_root == '' then
    return
  end
  get_unmerged_async(git_root, function(files)
    apply_repo_unmerged(files, git_root)
  end)
end

local function stop_other_watchers(curr_dir)
  for prev_dir, handle in pairs(watcher_state.handles) do
    if handle ~= watcher_state.handles[curr_dir] then
      handle:stop()
      watcher_state.handles[prev_dir] = nil
    end
  end
end

local function watch_gitdir(dir)
  if watcher_state.handles[dir] then
    return
  end
  watcher_state.handles[dir] = vim.uv.new_fs_event()
  watcher_state.handles[dir]:start(
    dir,
    { recursive = true },
    vim.schedule_wrap(function()
      M.fetch_conflicts()
    end)
  )
  watcher_state.current_dir = dir
end

local throttled_watcher = utils.throttle(1000, watch_gitdir)

local on_repo_autocmd = utils.throttle(1000, function(buf)
  local gitdir = vim.fn.getcwd() .. '/.git'
  if not vim.uv.fs_stat(gitdir) or watcher_state.current_dir == vim.fn.getcwd() then
    M.fetch_conflicts(buf)
    return
  end
  stop_other_watchers(gitdir)
  M.fetch_conflicts(buf)
  throttled_watcher(gitdir)
end)

local function stop_all_watchers()
  for key, handle in pairs(watcher_state.handles) do
    handle:stop()
    watcher_state.handles[key] = nil
  end
  watcher_state.current_dir = nil
end

--------------------------------------------------------------------------------
-- Navigation
--------------------------------------------------------------------------------

function M.list_conflicts()
  local conflicts_list = {}
  for path, cache in pairs(visited_buffers) do
    if type(path) == 'string' then
      if cache.blocks and #cache.blocks > 0 then
        for _, block in ipairs(cache.blocks) do
          table.insert(conflicts_list, { file = path, lnum = block.start_line, bufnr = cache.bufnr })
        end
      else
        table.insert(conflicts_list, { file = path, lnum = 1, bufnr = cache.bufnr })
      end
    end
  end

  table.sort(conflicts_list, function(a, b)
    if a.file == b.file then
      return a.lnum < b.lnum
    end
    return a.file < b.file
  end)

  return conflicts_list
end

local function build_quickfix_entries(conflicts_list)
  local entries = {}
  for _, conflict in ipairs(conflicts_list) do
    local bufnr = conflict.bufnr or vim.fn.bufadd(conflict.file)
    table.insert(entries, {
      bufnr = bufnr,
      filename = vim.fn.fnamemodify(conflict.file, ':.'),
      lnum = conflict.lnum,
      col = 1,
      text = 'Merge conflict marker',
    })
  end
  return entries
end

local function navigate_conflict(direction)
  sync_fetch_conflicts()
  local conflicts_list = M.list_conflicts()

  if #conflicts_list == 0 then
    print 'No conflicts found ✅'
    return
  end

  nav_index = nav_index + direction
  if nav_index > #conflicts_list then
    nav_index = 1
  elseif nav_index < 1 then
    nav_index = #conflicts_list
  end

  local conflict = conflicts_list[nav_index]
  vim.cmd('edit ' .. vim.fn.fnameescape(conflict.file))
  vim.api.nvim_win_set_cursor(0, { conflict.lnum, 0 })
end

function M.prev_conflict()
  navigate_conflict(-1)
end

function M.next_conflict()
  navigate_conflict(1)
end

function M.populate_quickfix()
  sync_fetch_conflicts()
  local conflicts_list = M.list_conflicts()
  if #conflicts_list == 0 then
    vim.fn.setqflist({}, 'r')
    print 'No conflicts found ✅'
    return
  end

  vim.fn.setqflist(build_quickfix_entries(conflicts_list), 'r')
  vim.cmd 'copen'
end

--------------------------------------------------------------------------------
-- Resolution
--------------------------------------------------------------------------------

local function apply_resolution(mode)
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  local replacement, start_line, end_line = conflict_replacement(lines, cursor_line, mode)
  if not replacement or not start_line or not end_line then
    vim.notify('Cursor is not inside a merge conflict', vim.log.levels.WARN)
    return
  end

  vim.api.nvim_buf_set_lines(bufnr, start_line - 1, end_line, false, replacement)
  vim.api.nvim_win_set_cursor(0, { start_line, 0 })

  local buf_name = vim.api.nvim_buf_get_name(bufnr)
  if buf_name ~= '' then
    visited_buffers[buf_name] = visited_buffers[buf_name] or { blocks = {}, tick = -1 }
  end
  parse_buffer(bufnr)
  M.fetch_conflicts(bufnr)
end

function M.take_head()
  apply_resolution 'head'
end

function M.take_origin()
  apply_resolution 'origin'
end

function M.take_both()
  apply_resolution 'both'
end

--------------------------------------------------------------------------------
-- Setup
--------------------------------------------------------------------------------

function M.setup(user_config)
  config = vim.tbl_deep_extend('force', vim.deepcopy(default_config), user_config or {})

  if config.enabled == false then
    return
  end

  stop_all_watchers()
  vim.api.nvim_create_augroup('UserConflicts', { clear = true })

  register_decoration_provider()

  vim.api.nvim_create_autocmd({ 'VimEnter', 'BufRead', 'SessionLoadPost', 'DirChanged' }, {
    group = augroup,
    callback = function(args)
      on_repo_autocmd(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = augroup,
    callback = stop_all_watchers,
  })

  vim.api.nvim_create_user_command('ConflictsPrevious', M.prev_conflict, { desc = 'Go to previous Git conflict' })
  vim.api.nvim_create_user_command('ConflictsNext', M.next_conflict, { desc = 'Go to next Git conflict' })
  vim.api.nvim_create_user_command('ConflictsTakeHead', M.take_head, { desc = 'Take changes from HEAD' })
  vim.api.nvim_create_user_command('ConflictsTakeOrigin', M.take_origin, { desc = 'Take changes from origin' })
  vim.api.nvim_create_user_command('ConflictsTakeBoth', M.take_both, { desc = 'Take both changes' })
  vim.api.nvim_create_user_command('ConflictsQuickfix', M.populate_quickfix, { desc = 'List Git conflicts in quickfix' })
  vim.api.nvim_create_user_command('ConflictsRefresh', function()
    M.fetch_conflicts()
  end, { desc = 'Refresh git unmerged conflict file list' })

  vim.api.nvim_create_user_command('ConflictsReload', function()
    package.loaded['user.conflicts'] = nil
    require('user.conflicts').setup()
  end, {})

  on_repo_autocmd(vim.api.nvim_get_current_buf())
end

return M
