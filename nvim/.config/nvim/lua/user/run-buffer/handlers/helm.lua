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
      local template = 'helm template ' .. vim.fn.shellescape(chart_name) .. ' .'
      return {
        cmd = dependency_build_prefix(chart_root) .. template,
        spawn = true,
        cwd = chart_root,
      }
    end,
  },
}
