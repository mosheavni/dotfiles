local pack = require 'user.pack.add'
pack.add { src = 'https://github.com/Ramilito/kubectl.nvim', version = vim.version.range '2.x' }

return function()
  require('kubectl').setup {
    auto_refresh = { enabled = true, interval = 300 },
    lsp = { enabled = true },
    headers = { enabled = true, hints = true, context = true, heartbeat = true },
    diff = { bin = 'kdiff' },
    filter = { apply_on_select_from_history = false, max_history = 30 },
    logs = { since = '30s', timestamps = false, prefix = false },
    statusline = { enabled = true },
    alias = { apply_on_select_from_history = true, max_history = 30 },
  }

  local group = vim.api.nvim_create_augroup('kubectl_user', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = 'k8s_*',
    callback = function(event)
      vim.o.relativenumber = false
      vim.opt.titlestring = '❄️ k8s: %t'
      if vim.bo.filetype:match '^k8s_.*yaml$' then
        vim.treesitter.start(0, 'yaml')
      end

      local opts = { buffer = event.buf, silent = true }
      vim.keymap.set('n', '7', '<Plug>(kubectl.view_nodes)', vim.tbl_extend('force', opts, { desc = 'View nodes' }))
      vim.keymap.set('n', '8', '<Plug>(kubectl.view_daemonsets)', vim.tbl_extend('force', opts, { desc = 'View Daemonsets' }))
      vim.keymap.set('n', '9', '<Plug>(kubectl.view_statefulsets)', vim.tbl_extend('force', opts, { desc = 'View Statefulsets' }))
      vim.keymap.set('n', '<C-t>', '<Plug>(kubectl.view_top)', vim.tbl_extend('force', opts, { desc = 'Top (pods/nodes)' }))
      vim.keymap.set('n', 'Z', function()
        local state = require 'kubectl.state'
        local current = state.getFilter()
        local faults_filter = '!1/1,!2/2,!3/3,!4/4,!5/5,!6/6,!7/7,!Completed,!Terminating'
        if current == faults_filter then
          state.setFilter ''
        else
          state.setFilter(faults_filter)
        end
        vim.api.nvim_input '<Plug>(kubectl.refresh)'
      end, vim.tbl_extend('force', opts, { desc = 'Toggle faults' }))
      vim.keymap.set('n', '<C-y>', function()
        local _, buf_name = pcall(vim.api.nvim_buf_get_var, event.buf, 'buf_name')
        local view = require('kubectl.views').resource_and_definition(vim.trim(buf_name))
        if not view then
          return
        end
        local name, ns = view.getCurrentSelection()
        local txt = ns and (name .. ' -n ' .. ns) or name
        vim.fn.setreg('+', txt)
        vim.notify('Copied to clipboard: ' .. txt, vim.log.levels.INFO)
      end, vim.tbl_extend('force', opts, { desc = 'Copy resource name to clipboard' }))
    end,
  })

  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'K8sContextChanged',
    callback = function(ctx)
      vim.system({ 'kubectl', 'config', 'use-context', ctx.data.context }, { text = true }, function(results)
        if not results then
          vim.notify(results, vim.log.levels.INFO)
        end
      end)
    end,
  })

  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'K8sResourceSelected',
    callback = function(ctx)
      local kubectl_user = require 'user.kubectl'
      local kind = ctx.data.kind
      if kubectl_user[kind] and kubectl_user[kind].select then
        kubectl_user[kind].select(ctx.data.name, ctx.data.ns)
      end
    end,
  })

  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'K8sCacheLoaded',
    callback = function()
      vim.notify('Kubernetes api-resources cache loaded', vim.log.levels.INFO)
    end,
  })

  vim.api.nvim_create_user_command('KubectlOpen', function()
    require('kubectl').open()
  end, {})
end
