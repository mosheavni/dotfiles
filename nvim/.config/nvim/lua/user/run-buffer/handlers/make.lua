-- Makefile run handler: parse targets and prompt for `make <target>`.
local M = {}

M.ft = 'make'

--- Return the Makefile rule target on `line`, or nil for recipes, comments, and assignments.
--- Recipe lines (leading tab) and `https://` in recipes are ignored.
---@param line string Single line from a Makefile.
---@return string|nil target Target name before `:`, without `.PHONY`.
function M.makefile_target_name(line)
  -- Recipe lines must start with TAB; skip them (avoids false positives like https:// in recipes).
  if line:match '^\t' or line:match '^%s*#' then
    return nil
  end
  -- Target rules start at column 0: "target:" or "target: deps" (not "VAR := value").
  local target = line:match '^([^:#=]+):'
  if not target then
    return nil
  end
  target = vim.trim(target)
  if target == '' or target:match '^%.PHONY$' then
    return nil
  end
  return target
end

--- Parse rule targets from a Makefile into vim.ui.select options.
---@param path string Absolute path to the Makefile.
---@return { text: string, value: string }[] Options like `{ text = "1 - all", value = "all" }`.
function M.get_makefile_options(path)
  local options = {}

  local file = io.open(path, 'r')
  if not file then
    vim.notify('Unable to open a Makefile in the current working dir.', vim.log.levels.ERROR, {
      title = 'Makeit.nvim',
    })
    return options
  end

  local count = 0
  for line in file:lines() do
    local target = M.makefile_target_name(line)
    if target then
      count = count + 1
      table.insert(options, { text = count .. ' - ' .. target, value = target })
    end
  end
  file:close()

  return options
end

--- Prompt for a Makefile target and invoke `on_done` with `make <target>` or nil.
---@param file_name string Absolute path to the Makefile.
---@param on_done fun(cmd: string|nil)
function M.get_make_async(file_name, on_done)
  local options = M.get_makefile_options(file_name)
  if #options == 0 then
    on_done(nil)
    return
  end
  local labels = vim.tbl_map(function(option)
    return option.text
  end, options)
  vim.ui.select(labels, { prompt = 'Select make target❯ ' }, function(_, idx)
    if not idx then
      on_done(nil)
      return
    end
    on_done('make ' .. options[idx].value)
  end)
end

--- Run handler: interactive target picker; calls `on_done(nil, true)` when cancelled.
---@type RunHandler
M.handler = {
  resolve = function(ctx, on_done)
    M.get_make_async(ctx.file_name, function(cmd)
      if not cmd then
        on_done(nil, true)
        return
      end
      on_done(cmd, false)
    end)
  end,
}

return M
