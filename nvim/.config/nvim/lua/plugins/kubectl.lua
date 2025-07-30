return {
  'Ramilito/kubectl.nvim',
  version = '2.*',
  dependencies = 'saghen/blink.download',
  dev = true,
  opts = {
    kubectl_cmd = {
      persist_context_change = true,
    },
    auto_refresh = {
      enabled = true,
      interval = 300, -- milliseconds
    },

    headers = {
      enabled = true,
      hints = true,
      context = true,
      heartbeat = true,
    },
    -- log_level = vim.log.levels.DEBUG,
    -- diff = { bin = 'kdiff' },
    -- headers = true,
    -- hints = true,
    -- context = true,
    -- heartbeat = true,
    -- kubernetes_versions = true,
    -- auto_refresh = {
    --   enabled = true,
    -- },
    -- filter = {
    --   apply_on_select_from_history = false,
    --   max_history = 100,
    -- },
    -- logs = {
    --   since = '30s',
    --   timestamps = false,
    --   prefix = false,
    -- },
    -- lineage = {
    --   enabled = false,
    -- },
    -- completion = {
    --   follow_cursor = false,
    -- },
  },
  cmd = { 'Kubectl', 'Kubectx', 'Kubens' },
  keys = {
    { '<leader>k', '<cmd>lua require("kubectl").toggle()<cr>' },
    -- { '<C-k>', '<Plug>(kubectl.kill)', ft = 'k8s_*' },
    { '7', '<Plug>(kubectl.view_nodes)', ft = 'k8s_*' },
    { '8', '<Plug>(kubectl.view_overview)', ft = 'k8s_*' },
    { '<C-t>', '<Plug>(kubectl.view_top)', ft = 'k8s_*' },
    {
      'Z',
      function()
        local state = require 'kubectl.state'
        local current = state.getFilter()
        local faults_filter = '!1/1,!2/2,!3/3,!4/4,!5/5,!6/6,!7/7,!Completed,!Terminating'
        if current == faults_filter then
          state.setFilter ''
          return
        end
        state.setFilter(faults_filter)
      end,
      desc = 'Toggle faults',
      ft = 'k8s_*',
    },
  },
  init = function()
    local group = vim.api.nvim_create_augroup('kubectl_user', { clear = true })
    vim.api.nvim_create_autocmd('FileType', {
      group = group,
      pattern = 'k8s_*',
      callback = function()
        vim.opt.titlestring = 'k8s: %t'
        if vim.bo.filetype == 'k8s_yaml' then
          vim.bo.filetype = 'yaml'
        end
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
  end,
}
