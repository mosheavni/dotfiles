local M = {
  {
    'tpope/vim-dadbod',
    cmd = {
      'DB',
      'DBUI',
      'DBUIClose',
      'DBUIToggle',
      'DBUIFindBuffer',
      'DBUIRenameBuffer',
      'DBUIAddConnection',
      'DBUILastQueryInfo',
      'DBUIHideNotifications',
      'DBCompletionClearCache',
    },
    init = function()
      require('user.menu').add_actions('Database', {
        ['Add Connection'] = function()
          vim.cmd 'DBUIAddConnection'
        end,
        ['Rename Buffer'] = function()
          vim.cmd 'DBUIRenameBuffer'
        end,
        ['Find Buffer'] = function()
          vim.cmd 'DBUIFindBuffer'
        end,
        ['Last Query Info'] = function()
          vim.cmd 'DBUILastQueryInfo'
        end,
        ['Toggle UI'] = function()
          vim.cmd 'DBUIToggle'
        end,
        ['Close UI'] = function()
          vim.cmd 'DBUIClose'
        end,
        ['Hide UI Notifications'] = function()
          vim.cmd 'DBUIHideNotifications'
        end,
      })
    end,
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
