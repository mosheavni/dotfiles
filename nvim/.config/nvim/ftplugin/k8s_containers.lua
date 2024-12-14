local mappings = require 'kubectl.mappings'
local pod_view = require 'kubectl.views.pods'
local tables = require 'kubectl.utils.tables'

vim.api.nvim_buf_set_keymap(0, 'n', '<Plug>(kubectl.browse)', '', {
  noremap = true,
  silent = true,
  desc = 'Copy exec command',
  callback = function()
    local container_name = tables.getCurrentSelection(unpack { 1 })
    local exec_cmd = string.format('kubectl exec -it %s -n %s -c %s -- /bin/sh', pod_view.selection.pod, pod_view.selection.ns, container_name)
    vim.notify(exec_cmd)
    vim.fn.setreg('+', exec_cmd)
  end,
})

vim.schedule(function()
  mappings.map_if_plug_not_set('n', 'gx', '<Plug>(kubectl.browse)')
end)
