-- Buffer path and working-directory helpers for run-buffer.
local resolve = require 'user.run-buffer.resolve'

local M = {}

--- Ensure the current buffer has a runnable path and return it with the filetype.
--- Unnamed buffers call `_G.start_ls(true)`. Modified buffers prompt to save.
---@return string|nil file_name Absolute path, or `nil` when the user cancelled or prep failed.
---@return string|nil ft Filetype used for handler lookup (defaults to `sh`).
function M.filename_and_ft()
  local ft = vim.bo.filetype ~= '' and vim.bo.filetype or 'sh'
  local file_name = vim.fn.expand '%:p'
  if file_name == '' then
    vim.api.nvim_set_option_value('filetype', ft, { buf = 0 })
    if type(_G.start_ls) ~= 'function' then
      vim.notify('run-buffer: _G.start_ls is not defined; cannot run an unnamed buffer', vim.log.levels.ERROR)
      return
    end
    local temp_name = _G.start_ls(true)
    if type(temp_name) ~= 'string' or temp_name == '' then
      vim.notify('run-buffer: _G.start_ls(true) did not return a filepath; cannot run an unnamed buffer', vim.log.levels.ERROR)
      return
    end
    file_name = temp_name
  end

  if vim.bo.modified then
    local save = vim.fn.confirm(('Save changes to %q before running?'):format(file_name), '&Yes\n&No\n&Cancel')
    if save == 3 then
      return
    elseif save == 1 then
      vim.cmd.write()
    end
  end
  return file_name, ft
end

--- Working directory for running the buffer (handler `cwd` or parent of the buffer file).
---@param ft string Filetype used to look up an optional `cwd` handler.
---@return string
function M.run_cwd(ft)
  local h = resolve.get(ft)
  if h and h.cwd then
    return h.cwd()
  end
  return vim.fn.expand '%:p:h'
end

return M
