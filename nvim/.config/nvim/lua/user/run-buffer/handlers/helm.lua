-- Helm chart: template from the chart root (directory containing Chart.yaml).
local function dependency_build_prefix(chart_root)
  local charts_path = vim.fs.joinpath(chart_root, 'charts')
  if vim.fn.isdirectory(charts_path) == 1 and vim.fs.dir(charts_path)() then
    return ''
  end
  local in_deps = false
  for _, line in ipairs(vim.fn.readfile(vim.fs.joinpath(chart_root, 'Chart.yaml'))) do
    if line:match '^dependencies:%s*$' then
      in_deps = true
    elseif in_deps and line:match '^%s*- name:' then
      return 'helm dependency build; '
    elseif in_deps and line ~= '' and not line:match '^%s' and not line:match '^%s*#' then
      in_deps = false
    end
  end
  return ''
end

---@param chart_root string
---@param file_name string
---@return string Suffix for `helm template`, e.g. ` --show-only templates/foo.yaml`.
local function show_only_suffix(chart_root, file_name)
  if vim.fs.basename(file_name) == 'Chart.yaml' then
    return ''
  end
  local rel = vim.fs.relpath(chart_root, file_name)
  if not rel or not rel:match '^templates/' then
    return ''
  end
  return ' --show-only ' .. vim.fn.shellescape(rel)
end

return {
  ft = 'helm',
  ---@type RunHandler
  handler = {
    resolve = function(ctx)
      local chart_root = vim.fs.root(ctx.file_name, 'Chart.yaml')
      if not chart_root then
        vim.notify('helm: no Chart.yaml found above ' .. ctx.file_name, vim.log.levels.ERROR, { title = 'run-buffer' })
        return { spawn = false }
      end
      local chart_name = vim.fs.basename(chart_root)
      local template = 'helm template ' .. vim.fn.shellescape(chart_name) .. ' .' .. show_only_suffix(chart_root, ctx.file_name)
      return {
        cmd = dependency_build_prefix(chart_root) .. template,
        spawn = true,
        cwd = chart_root,
      }
    end,
  },
}
