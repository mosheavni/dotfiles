local M = {}

--- Run a shell command, notifying on failure.
---@param cmd string[]
---@return boolean ok
local function run(cmd)
  local result = vim.system(cmd, { text = true }):wait()
  if result.code ~= 0 then
    vim.notify('Extraction failed: ' .. table.concat(cmd, ' '), vim.log.levels.ERROR)
    return false
  end
  return true
end

--- Extract an archive into its containing directory, dispatching on mime type.
---@param path string absolute path to the archive file
function M.extract(path)
  local dir = vim.fn.fnamemodify(path, ':h')
  local mime_type = vim.trim(vim.system({ 'file', '--mime-type', '-b', path }, { text = true }):wait().stdout)

  if mime_type == 'application/gzip' then
    run { 'tar', 'xzf', path, '-C', dir }
  elseif mime_type == 'application/zip' then
    run { 'unzip', path, '-d', dir }
  elseif mime_type == 'application/x-bzip2' then
    run { 'tar', 'xjf', path, '-C', dir }
  else
    vim.notify('Unsupported file type for extraction: ' .. mime_type, vim.log.levels.WARN)
    return
  end
  vim.notify('Extracted: ' .. path)
end

return M
