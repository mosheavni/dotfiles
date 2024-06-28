local M = {
  schemas_catalog = 'datreeio/CRDs-catalog',
  schema_catalog_branch = 'main',
  github_base_api_url = 'https://api.github.com/repos',
  github_headers = {
    Accept = 'application/vnd.github+json',
    ['X-GitHub-Api-Version'] = '2022-11-28',
  },
}

M.schema_url = 'https://raw.githubusercontent.com/' .. M.schemas_catalog .. '/' .. M.schema_catalog_branch

M.list_github_tree = function()
  local url = M.github_base_api_url .. '/' .. M.schemas_catalog .. '/git/trees/' .. M.schema_catalog_branch
  local headers_in_curl_format = {}
  for key, value in pairs(M.github_headers) do
    table.insert(headers_in_curl_format, '-H')
    table.insert(headers_in_curl_format, key .. ': ' .. value)
  end
  local cmd = vim.iter({ 'curl', '--location', '--silent', '--fail', headers_in_curl_format, url .. '?recursive=1' }):flatten():totable()
  local response = vim.fn.systemlist(cmd)
  local body = vim.fn.json_decode(response)
  local trees = {}
  for _, tree in ipairs(body.tree) do
    if tree.type == 'blob' and tree.path:match '%.json$' then
      table.insert(trees, tree.path)
    end
  end
  return trees
end

M.all_crds = M.list_github_tree()

M.crds_as_schemas = function()
  local schemas = {}
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

M.init = function()
  vim.ui.select(M.all_crds, { prompt = 'Select schema: ' }, function(selection)
    if not selection then
      require('user.utils').pretty_print 'Canceled.'
      return
    end
    local schema_url = M.schema_url .. '/' .. selection
    local schema_modeline = '# yaml-language-server: $schema=' .. schema_url
    vim.api.nvim_buf_set_lines(0, 0, 0, false, { schema_modeline })
    vim.notify('Added schema modeline: ' .. schema_modeline)
  end)
end

return M
