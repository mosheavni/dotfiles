local M = {
  schemas_catalog = 'datreeio/CRDs-catalog',
  schema_catalog_branch = 'main',
  github_base_api_url = 'https://api.github.com/repos',
  github_headers = {
    Accept = 'application/vnd.github+json',
    ['X-GitHub-Api-Version'] = '2022-11-28',
  },
  schema_modeline = '# yaml-language-server: $schema=',
}

M.schema_url = 'https://raw.githubusercontent.com/' .. M.schemas_catalog .. '/' .. M.schema_catalog_branch

--- Get all trees from GitHub
---@param cb function
M.list_github_tree = function(cb)
  local url = M.github_base_api_url .. '/' .. M.schemas_catalog .. '/git/trees/' .. M.schema_catalog_branch
  local trees = {}
  local headers_in_curl_format = {}
  for key, value in pairs(M.github_headers) do
    table.insert(headers_in_curl_format, '-H')
    table.insert(headers_in_curl_format, key .. ': ' .. value)
  end
  local cmd = vim.iter({ 'curl', '--location', '--silent', '--fail', headers_in_curl_format, url .. '?recursive=1' }):flatten():totable()
  vim.system(cmd, { text = true }, function(data)
    vim.schedule(function()
      local body = vim.fn.json_decode(data.stdout)
      for _, tree in ipairs(body.tree) do
        if tree.type == 'blob' and tree.path:match '%.json$' then
          table.insert(trees, tree.path)
        end
      end
      cb(trees)
    end)
  end)
end

M.crds_as_schemas = function()
  local schemas = {}
  if not M.all_crds or #M.all_crds == 0 then
    M.init()
  end
  for _, crd in ipairs(M.all_crds) do
    local crd_name = '[datreeio] ' .. crd:gsub('%.json$', ''):gsub('/', '-'):gsub('_', '-')
    local schema_url = {
      uri = M.schema_url .. '/' .. crd,
      name = crd_name,
    }
    table.insert(schemas, schema_url)
  end
  return schemas
end

M.list_schemas = function()
  vim.ui.select(M.all_crds, { title = 'Schemas', prompt = 'Select schema❯ ' }, function(selection)
    if not selection then
      require('user.utils').pretty_print 'Canceled.'
      return
    end
    local schema_url = M.schema_url .. '/' .. selection
    local schema_modeline = M.schema_modeline .. schema_url
    vim.api.nvim_buf_set_lines(0, 0, 0, false, { schema_modeline })
    vim.notify('Added schema modeline: ' .. schema_modeline)
  end)
end

M.init = function()
  if not M.all_crds or #M.all_crds == 0 then
    M.list_github_tree(function(trees)
      M.all_crds = trees
      M.list_schemas()
    end)
    return
  else
    M.list_schemas()
  end
end

return M
