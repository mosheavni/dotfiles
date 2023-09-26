local M = {
  {
    'tpope/vim-dadbod',
    cmd = { 'DB', 'DBUI' },
    dependencies = {
      {
        'kristijanhusak/vim-dadbod-ui',
        config = function()
          vim.g.db_ui_table_helpers = {
            sqlite = {
              Schema = '.schema "{table}"',
              Count = 'SELECT COUNT(*) FROM "{table}"',
            },
          }
        end,
      },
      'kristijanhusak/vim-dadbod-completion',
    },
  },
}

return M
