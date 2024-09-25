return {
  dir = '/Users/mavni/Repos/kubectl.nvim',
  -- 'mosheavni/kubectl.nvim',
  opts = {
    diff = { bin = 'kdiff' },
    -- logging = {
    --   level = 'trace',
    -- },
    notifications = {
      enabled = false,
      verbose = false,
      blend = 0,
    },
    namespace_fallback = {
      'default',
      'kube-system',
    },
  },
  cmd = { 'Kubectl', 'Kubectx', 'Kubens' },
  keys = {
    { '<leader>k', '<cmd>lua require("kubectl").toggle()<cr>' },
    { '<C-k>', '<Plug>(kubectl.kill)', ft = 'k8s_*' },
  },
}
