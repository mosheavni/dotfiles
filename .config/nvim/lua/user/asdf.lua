local M = {
  tools_exists = false,
  tools = {},
}

local function read_tools(file_path)
  local f = io.open(file_path, 'r')
  if f == nil then
    return false
  end
  local file_unparsed = f:read '*a'
  file_unparsed = vim.split(file_unparsed, '\n')

  for _, line in ipairs(file_unparsed) do
    local tool = vim.split(line, ' ')
    M.tools[tool[1]] = tool[2]
  end
  io.close(f)
  return true
end

local function check_if_theres_tool()
  -- get git root
  local git_root = vim.system({ 'git', 'rev-parse', '--show-toplevel' }, { text = true }):wait().stdout
  -- trim newline at the end
  git_root = string.gsub(git_root, '%s+$', '')
  --  check if there's .tool-versions in the root of the project
  --  if there is, then read it and save it to a table
  M.tools_exists = read_tools(git_root .. '/.tool-versions')
  return M.tools_exists
end

M.setup = function()
  if not check_if_theres_tool() then
    P 'no tools'
    return
  end
  for tool, _ in pairs(M.tools) do
    local installed = vim.system({ 'asdf', 'where', tool }, { text = true }):wait().stdout
    installed = string.gsub(installed, '%s+$', '')
    P(tool .. ' installed: ' .. installed)
    if installed == 'Version not installed' then
      P(tool .. ' is not installed')
      return vim.ui.select({ 'All', 'Only ' .. tool, 'No' }, {
        prompt = 'asdf detected, ' .. tool .. ' is not installed, do you want to install the tools?',
      }, function(selected)
        if not selected or selected == 'No' then
          return
        end
        local install_cmd = { 'asdf', 'install' }
        if selected ~= 'All' then
          table.insert(install_cmd, tool)
        end
        P(install_cmd)
        vim.system(install_cmd, { text = true }, function(a)
          P(a.stdout)
          vim.notify('Installed ' .. selected)
        end)
      end)
    end
  end
end

return M
