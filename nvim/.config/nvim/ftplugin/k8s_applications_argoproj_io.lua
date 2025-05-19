local commands = require 'kubectl.actions.commands'
local tables = require 'kubectl.utils.tables'
vim.print 'in here'

vim.schedule(function()
  vim.api.nvim_buf_set_keymap(0, 'n', '<Plug>(kubectl.select)', '', {
    noremap = true,
    silent = true,
    desc = 'Go to application',
    callback = function()
      local _, buf_name = pcall(vim.api.nvim_buf_get_var, 0, 'buf_name')
      local lower_buf_name = string.lower(buf_name)

      if lower_buf_name == 'applications' or lower_buf_name == 'applications.argoproj.io' then
        local name = tables.getCurrentSelection(2)
        if not name then
          return
        end
        local ingress_host = commands.shell_command(
          'kubectl',
          { 'get', 'ingress', '-n', 'argocd', '-l', 'app.kubernetes.io/component=server', '-o', 'jsonpath={.items[].spec.rules[].host}' }
        )

        local final_host = string.format('https://%s/applications/argocd/%s', ingress_host, name)
        vim.notify('Opening ' .. final_host)
        vim.ui.open(final_host)
      end
    end,
  })
end)
