local ResourceBuilder = require 'kubectl.resourcebuilder'
local commands = require 'kubectl.actions.commands'
local pod_view = require 'kubectl.views.pods'

vim.schedule(function()
  vim.api.nvim_buf_set_keymap(0, 'n', 'gk', '', {
    noremap = true,
    silent = true,
    desc = 'Kill prompt',
    callback = function()
      local name, ns = pod_view.getCurrentSelection()
      local builder = ResourceBuilder:new 'kubectl_drain'
      local pod_def = {
        ft = 'k8s_kill_pod',
        display = string.format('Kill pod: %s/%s?', ns, name),
        resource = ns .. '/' .. name,
        cmd = { 'delete', 'pod', name, '-n', ns },
      }
      local data = {
        { text = 'cascade:', value = 'background', options = { 'background', 'orphan', 'foreground' }, cmd = '--cascade', type = 'option' },
        { text = 'dry run:', value = 'none', options = { 'none', 'server', 'client' }, cmd = '--dry-run', type = 'option' },
        { text = 'grade period:', value = '-1', cmd = '--grace-period', type = 'option' },
        { text = 'timeout:', value = '0s', cmd = '--timeout', type = 'option' },
        { text = 'force:', value = 'false', options = { 'false', 'true' }, cmd = '--force', type = 'flag' },
      }

      builder:action_view(pod_def, data, function(args)
        commands.shell_command_async('kubectl', args)
      end)
    end,
  })
end)
