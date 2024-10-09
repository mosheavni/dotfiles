local commands = require 'kubectl.actions.commands'
local tables = require 'kubectl.utils.tables'

local ingress_host
commands.shell_command_async(
  'kubectl',
  { 'get', 'ingress', '-n', 'argocd', '-l', 'app.kubernetes.io/component=server', '-o', 'jsonpath={.items[].spec.rules[].host}' },
  function(response)
    ingress_host = response
  end
)

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

        if not ingress_host then
          vim.notify('Ingress host not found yet.', vim.log.levels.WARN)
          return
        end
        local final_host = string.format('https://%s/applications/argocd/%s', ingress_host, name)
        vim.notify('Opening ' .. final_host)
        pcall(vim.ui.open, final_host)
      end
    end,
  })
end)
