return {
  dir = '/Users/mavni/Repos/kubectl.nvim',
  -- 'Ramilito/kubectl.nvim',
  opts = {
    log_level = vim.log.levels.DEBUG,
    diff = { bin = 'kdiff' },
    context = true,
    filter = {
      apply_on_select_from_history = false,
    },
  },
  cmd = { 'Kubectl', 'Kubectx', 'Kubens' },
  keys = {
    { '<leader>k', '<cmd>lua require("kubectl").toggle()<cr>' },
    { '<C-k>', '<Plug>(kubectl.kill)', ft = 'k8s_*' },
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
    },
  },
}
