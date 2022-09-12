local curl = require 'plenary.curl'
local open_url = require('user.open-url').open_url
local M = {}

M.readme = 'https://raw.githubusercontent.com/rockerBOO/awesome-neovim/main/README.md'
M.plugins = {}

M.find_default_branch = function(url)
  local new_url = url:gsub('github.com', 'api.github.com/repos')
  local result = vim.fn.json_decode(curl.get(new_url).body)
  return (result or {}).default_branch or 'master'
end

M.get_all_plugins = function()
  local result = vim.split(curl.get(M.readme).body, '\n')
  local plugins = {}
  local category = ''
  for _, a in ipairs(result) do
    if a:match '^%s-#+%s%a+' then
      category = a:match '^%s-#+%s*(.-)$'
    elseif a:match '^- .-https://.*' then
      local plugin_name = a:match '%[(.-)%]'
      local plugin_url = a:match '%((.-)%)'
      local plugin_description = a:match '%) %- (.-)$'
      table.insert(plugins, { name = plugin_name, url = plugin_url, description = plugin_description, category = category })
    end
    ::continue::
  end
  return plugins
end

M.display_select = function()
  if vim.tbl_isempty(M.plugins) then
    M.plugins = M.get_all_plugins()
  end
  vim.ui.select(M.plugins, {
    prompt = 'Plugins',
    format_item = function(entry)
      return string.format('[%s] %s - %s', entry.category, entry.name, entry.description)
    end,
  }, function(plugin_chosen)
    if not plugin_chosen then
      return
    end
    -- local default_branch = M.find_default_branch(plugin_chosen.url)
    -- local readme_url = plugin_chosen.url:gsub('github.com', 'raw.githubusercontent.com') .. '/' .. default_branch .. '/README.md'
    open_url(plugin_chosen.url)
  end)
end

return M
