return {
  'NeogitOrg/neogit',
  dependencies = {
    'nvim-lua/plenary.nvim', -- required
    'sindrets/diffview.nvim', -- optional - Diff integration
    'ibhagwan/fzf-lua', -- optional
  },
  opts = {
    graph_style = 'unicode',
    integrations = {
      diffview = true,
      fzf_lua = true,
    },
  },
}
