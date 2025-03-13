local M = {}

local layout = {
  left_win = nil,
  right_win = nil,
}

-- Set up a consistent layout with two diff windows and quickfix at bottom
local function setup_layout()
  if layout.left_win and vim.api.nvim_win_is_valid(layout.left_win) then
    return false
  end

  -- Save current window as left window
  layout.left_win = vim.api.nvim_get_current_win()

  -- Create right window
  vim.cmd 'vsplit'
  layout.right_win = vim.api.nvim_get_current_win()
end

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
local function diff_files(left_file, right_file)
  setup_layout()

  edit_in(layout.left_win, left_file)
  edit_in(layout.right_win, right_file)

  vim.cmd 'diffoff!'
  vim.api.nvim_win_call(layout.left_win, vim.cmd.diffthis)
  vim.api.nvim_win_call(layout.right_win, vim.cmd.diffthis)
end

-- Diff two directories
local function diff_directories(left_dir, right_dir)
  setup_layout()

  -- Create a map of all relative paths
  local all_paths = {}

  -- Process left files
  local left_files = vim.fs.find(function()
    return true
  end, { limit = math.huge, path = left_dir, follow = false })
  for _, full_path in ipairs(left_files) do
    local rel_path = full_path:sub(#left_dir + 1)
    full_path = vim.fn.resolve(full_path)

    if vim.fn.isdirectory(full_path) == 0 then
      all_paths[rel_path] = all_paths[rel_path] or { left = nil, right = nil }
      all_paths[rel_path].left = full_path
    end
  end

  -- Process right files
  local right_files = vim.fs.find(function()
    return true
  end, { limit = math.huge, path = right_dir, follow = false })
  for _, full_path in ipairs(right_files) do
    local rel_path = full_path:sub(#right_dir + 1)
    full_path = vim.fn.resolve(full_path)

    if vim.fn.isdirectory(full_path) == 0 then
      all_paths[rel_path] = all_paths[rel_path] or { left = nil, right = nil }
      all_paths[rel_path].right = full_path
    end
  end

  -- Convert to quickfix entries
  local qf_entries = {}
  for rel_path, files in pairs(all_paths) do
    local status = 'M' -- Modified (both files exist)
    if not files.left then
      status = 'A' -- Added (only in right)
      files.left = left_dir .. rel_path
    elseif not files.right then
      status = 'D' -- Deleted (only in left)
      files.right = right_dir .. rel_path
    end

    table.insert(qf_entries, {
      filename = files.right,
      text = status,
      user_data = {
        diff = true,
        rel = rel_path,
        left = files.left,
        right = files.right,
      },
    })
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
      for item = info.start_idx, info.end_idx do
        local entry = items[item]
        table.insert(out, entry.text .. ' ' .. entry.user_data.rel)
      end
      return out
    end,
  })

  vim.cmd 'botright copen'
  vim.cmd.cfirst()
end

function M.setup()
  local ns_id = vim.api.nvim_create_namespace 'difftool_qf'

  -- Define the highlight groups in the namespace
  vim.api.nvim_set_hl(ns_id, 'DiffToolAdd', { link = 'DiffAdd' })
  vim.api.nvim_set_hl(ns_id, 'DiffToolDelete', { link = 'DiffDelete' })
  vim.api.nvim_set_hl(ns_id, 'DiffToolText', { link = 'DiffText' })

  vim.api.nvim_create_autocmd('BufWinEnter', {
    pattern = 'quickfix',
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      for i, line in ipairs(lines) do
        local hl_group
        if line:match '^A ' then
          hl_group = 'DiffToolAdd'
        elseif line:match '^D ' then
          hl_group = 'DiffToolDelete'
        elseif line:match '^M ' then
          hl_group = 'DiffToolText'
        end

        if hl_group then
          vim.api.nvim_buf_set_extmark(bufnr, ns_id, i - 1, 0, {
            line = i - 1,
            hl_group = hl_group,
            end_line = i,
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
      if not entry or not entry.user_data or not entry.user_data.diff or args.buf ~= entry.bufnr then
        return
      end

      vim.schedule(function()
        diff_files(entry.user_data.left, entry.user_data.right)
      end)
    end,
  })

  vim.api.nvim_create_user_command('DiffTool', function(opts)
    if #opts.fargs >= 2 then
      local left = opts.fargs[1]
      local right = opts.fargs[2]

      if vim.fn.isdirectory(left) == 1 and vim.fn.isdirectory(right) == 1 then
        diff_directories(left, right)
      elseif vim.fn.filereadable(left) == 1 and vim.fn.filereadable(right) == 1 then
        diff_files(left, right)
      else
        vim.notify('Both arguments must be files or directories', vim.log.levels.ERROR)
      end
    else
      vim.notify('Usage: DiffTool <left> <right>', vim.log.levels.ERROR)
    end
  end, { nargs = '*', force = true })
end

return M
