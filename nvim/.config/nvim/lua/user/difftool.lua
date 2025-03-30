---@class DiffLayout
---@field left_win integer|nil Window handle for left diff
---@field right_win integer|nil Window handle for right diff

---@class DiffToolModule
local M = {}

---@type DiffLayout
local layout = {
  left_win = nil,
  right_win = nil,
}

-- Set up a consistent layout with two diff windows and quickfix at bottom
---@return boolean setup_needed True if new layout needed to be created
local function setup_layout()
  if layout.left_win and vim.api.nvim_win_is_valid(layout.left_win) then
    return false
  end

  -- Save current window as left window
  layout.left_win = vim.api.nvim_get_current_win()

  -- Create right window
  vim.cmd 'vsplit'
  layout.right_win = vim.api.nvim_get_current_win()
  return true
end

---@param winnr integer Window handle
---@param file string File path
local function edit_in(winnr, file)
  vim.api.nvim_win_call(winnr, function()
    local current = vim.fs.abspath(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(winnr)))

    -- Check if the current buffer is already the target file
    if current == (file and vim.fs.abspath(file) or '') then
      return
    end

    -- Read the file into the buffer
    vim.cmd.edit(vim.fn.fnameescape(file))
  end)
end

-- Diff two files
---@param left_file string Path to left file
---@param right_file string Path to right file
local function diff_files(left_file, right_file)
  setup_layout()
  edit_in(layout.left_win, left_file)
  edit_in(layout.right_win, right_file)

  -- Apply diff settings efficiently
  vim.cmd 'diffoff!'
  local diffthis = vim.cmd.diffthis
  vim.api.nvim_win_call(layout.left_win, diffthis)
  vim.api.nvim_win_call(layout.right_win, diffthis)
end

---@class FileMapping
---@field left string|nil
---@field right string|nil

---@param dir string Directory path
---@param is_left boolean Whether this is the left directory
---@param all_paths table<string, FileMapping> Accumulated path mappings
local function process_directory(dir, is_left, all_paths)
  local files = vim.fs.find(function()
    return true
  end, {
    limit = math.huge,
    path = dir,
    follow = false,
  })

  for _, full_path in ipairs(files) do
    if vim.fn.isdirectory(full_path) == 0 then
      local rel_path = full_path:sub(#dir + 1)
      full_path = vim.fn.resolve(full_path)
      all_paths[rel_path] = all_paths[rel_path] or { left = nil, right = nil }
      if is_left then
        all_paths[rel_path].left = full_path
      else
        all_paths[rel_path].right = full_path
      end
    end
  end
end

---@param left_dir string Left directory path
---@param right_dir string Right directory path
local function diff_directories(left_dir, right_dir)
  setup_layout()

  ---@type table<string, FileMapping>
  local all_paths = {}

  -- Process both directories
  process_directory(left_dir, true, all_paths)
  process_directory(right_dir, false, all_paths)

  -- Convert to quickfix entries
  ---@type table[] Quickfix entries
  local qf_entries = {}

  for rel_path, files in pairs(all_paths) do
    local status, left_file, right_file = 'M', files.left, files.right

    if not left_file then
      status = 'A' -- Added (only in right)
      left_file = left_dir .. rel_path
    elseif not right_file then
      status = 'D' -- Deleted (only in left)
      right_file = right_dir .. rel_path
    end

    qf_entries[#qf_entries + 1] = {
      filename = right_file,
      text = status,
      user_data = {
        diff = true,
        rel = rel_path,
        left = left_file,
        right = right_file,
      },
    }
  end

  -- Sort entries by filename for consistency
  table.sort(qf_entries, function(a, b)
    return a.user_data.rel < b.user_data.rel
  end)

  vim.fn.setqflist({}, 'r', {
    ---@diagnostic disable-next-line: assign-type-mismatch
    nr = '$',
    title = 'DiffTool',
    items = qf_entries,
    quickfixtextfunc = function(info)
      local items = vim.fn.getqflist({ id = info.id, items = 1 }).items
      local out = {}
      for i = info.start_idx, info.end_idx do
        local entry = items[i]
        out[#out + 1] = entry.text .. ' ' .. entry.user_data.rel
      end
      return out
    end,
  })

  vim.cmd 'botright copen'
  vim.cmd.cfirst()
end

---Setup the difftool with highlighting and commands
function M.setup()
  local ns_id = vim.api.nvim_create_namespace 'difftool_qf'

  -- Pre-compile patterns for performance
  local patterns = {
    add = '^A ',
    delete = '^D ',
    modify = '^M ',
  }

  -- Define highlight groups
  local highlights = {
    DiffToolAdd = { link = 'DiffAdd' },
    DiffToolDelete = { link = 'DiffDelete' },
    DiffToolText = { link = 'DiffText' },
  }

  for group, def in pairs(highlights) do
    vim.api.nvim_set_hl(ns_id, group, def)
  end

  vim.api.nvim_create_autocmd('BufWinEnter', {
    pattern = 'quickfix',
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      for i, line in ipairs(lines) do
        local hl_group
        if line:match(patterns.add) then
          hl_group = 'DiffToolAdd'
        elseif line:match(patterns.delete) then
          hl_group = 'DiffToolDelete'
        elseif line:match(patterns.modify) then
          hl_group = 'DiffToolText'
        end

        if hl_group then
          vim.api.nvim_buf_set_extmark(bufnr, ns_id, i - 1, 0, {
            hl_group = hl_group,
            end_row = i,
            end_col = 0,
            strict = false,
          })
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd('BufWinEnter', {
    pattern = '*',
    callback = function(args)
      local qf_info = vim.fn.getqflist { idx = 0 }
      local qf_list = vim.fn.getqflist()
      local entry = qf_list[qf_info.idx]

      -- Check if the entry is a diff entry
      if not (entry and entry.user_data and entry.user_data.diff and args.buf == entry.bufnr) then
        return
      end

      vim.schedule(function()
        diff_files(entry.user_data.left, entry.user_data.right)
      end)
    end,
  })

  vim.api.nvim_create_user_command('DiffTool', function(opts)
    if #opts.fargs < 2 then
      vim.notify('Usage: DiffTool <left> <right>', vim.log.levels.ERROR)
      return
    end

    local left, right = opts.fargs[1], opts.fargs[2]
    local is_dir = vim.fn.isdirectory(left) == 1 and vim.fn.isdirectory(right) == 1
    local is_file = vim.fn.filereadable(left) == 1 and vim.fn.filereadable(right) == 1

    if is_dir then
      diff_directories(left, right)
    elseif is_file then
      diff_files(left, right)
    else
      vim.notify('Both arguments must be files or directories', vim.log.levels.ERROR)
    end
  end, {
    nargs = '*',
    force = true,
    complete = 'file',
  })
end

return M
