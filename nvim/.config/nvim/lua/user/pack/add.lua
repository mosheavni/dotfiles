local DEV = {
  ['yaml-companion.nvim'] = 'YAMLC_DEV',
  ['github-pr-reviewer.nvim'] = 'PR_REVIEW_DEV',
  ['search-replace.nvim'] = 'SAR_DEV',
  ['kubectl.nvim'] = 'K8S_DEV',
}

local function apply_dev(spec)
  local name = type(spec) == 'table' and (spec.name or spec.src:match '([^/]+)$') or spec:match '([^/]+)$'
  local env = DEV[name]
  local src = env and vim.env[env] == 'true' and vim.fn.expand('~/Repos/' .. name) or nil
  if not src then
    return spec
  end
  return type(spec) == 'table' and vim.tbl_extend('force', spec, { src = src }) or src
end

local M = {}

---Add one or more plugin specs with dev-override support.
---Accepts a single string/table spec or an array of specs.
---@param spec string|table
---@param opts? table
function M.add(spec, opts)
  opts = vim.tbl_extend('force', { confirm = false }, opts or {})
  if type(spec) == 'table' and not spec.src then
    vim.pack.add(vim.tbl_map(apply_dev, spec), opts)
  else
    vim.pack.add({ apply_dev(spec) }, opts)
  end
end

return M
