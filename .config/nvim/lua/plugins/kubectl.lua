return {
  dir = '/Users/mavni/Repos/kubectl.nvim',
  -- 'mosheavni/kubectl.nvim',
  opts = {
    diff = { bin = 'kdiff' },
    -- logging = {
    --   level = 'trace',
    -- },
    notifications = {
      enabled = true,
      verbose = true,
      blend = 0,
    },
  },
  cmd = { 'Kubectl', 'Kubectx', 'Kubens' },
  keys = {
    { '<leader>k', '<cmd>lua require("kubectl").toggle()<cr>' },
  },
}
