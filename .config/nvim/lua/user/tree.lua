local status_ok, nvim_tree = pcall(require, 'nvim-tree')
if not status_ok then
  return vim.notify 'Module nvim_tree not installed'
end
nvim_tree.setup {
  view = {
    mappings = {
      custom_only = false,
      list = {
        { key = 'x', action = 'close_node' },
        { key = '<c-e>', action = '' },
      },
    },
  },
}
