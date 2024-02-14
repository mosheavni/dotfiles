local M = {
  tools_exists = false,
  tools = {},
}

local function read_tools(file_path)
  local f = io.open(file_path, 'r')
  if f ~= nil then
    local file_unparsed = f:read '*a'
    file_unparsed = vim.split(file_unparsed, '\n')

    for _, line in ipairs(file_unparsed) do
      local tool = vim.split(line, ' ')
      M.tools[tool[1]] = tool[2]
    end
    io.close(f)
  end
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
  check_if_theres_tool()
end

return M
