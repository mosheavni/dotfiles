local mappings = require 'kubectl.mappings'
local pod_view = require 'kubectl.resources.pods'
local tables = require 'kubectl.utils.tables'

local bufnr = vim.api.nvim_get_current_buf()
vim.keymap.set('n', '<Plug>(kubectl.browse)', function()
  local container_name = tables.getCurrentSelection(unpack { 1 })
  local exec_cmd = string.format('kubectl exec -it %s -n %s -c %s -- /bin/sh', pod_view.selection.pod, pod_view.selection.ns, container_name)
  vim.notify(exec_cmd)
  vim.fn.setreg('+', exec_cmd)
end, { buffer = bufnr, desc = 'Copy exec command' })

vim.schedule(function()
  mappings.map_if_plug_not_set('n', 'gx', '<Plug>(kubectl.browse)')
end)
