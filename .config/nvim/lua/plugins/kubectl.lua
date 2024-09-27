return {
  dir = '/Users/mavni/Repos/kubectl.nvim',
  -- 'mosheavni/kubectl.nvim',
  opts = {
    diff = { bin = 'kdiff' },
    -- logging = {
    --   level = 'trace',
    -- },
    -- namespace_fallback = {
    --   'default',
    --   'kube-system',
    -- },
    filter = {
      apply_on_select_from_history = false,
    },
  },
  cmd = { 'Kubectl', 'Kubectx', 'Kubens' },
  keys = {
    { '<leader>k', '<cmd>lua require("kubectl").toggle()<cr>' },
    { '<C-k>', '<Plug>(kubectl.kill)', ft = 'k8s_*' },
  },
}
