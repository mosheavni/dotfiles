local M = {
  {
    'tpope/vim-dadbod',
    enabled = false,
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
      vim.g.db_ui_use_nerd_fonts = 1
      local sql_helpers = {
        Count = 'SELECT COUNT(*) FROM `{table}`;',
        List = 'SELECT * FROM `{table}` LIMIT 10;',
        Indexes = 'SHOW INDEXES FROM `{table}`;',
        ForeignKeys = 'SHOW CREATE TABLE `{table}`;',
        PrimaryKeys = 'SHOW KEYS FROM `{table}` WHERE Key_name = "PRIMARY";',
      }
      vim.g.db_ui_table_helpers = {
        sqlite = sql_helpers,
        mysql = sql_helpers,
        mongodb = {
          Count = 'db.{table}.countDocuments({});',
          List = 'db.{table}.find().limit(10).toArray();',
          Indexes = 'db.{table}.getIndexes();',
          Collections = 'db.getCollectionNames();',
          DatabaseInfo = 'db.stats();',
        },
        redis = {
          Keys = 'KEYS *;',
          List = 'LRANGE {table} 0 10;', -- Assuming you're using a list type
          Hash = 'HGETALL {table};', -- Assuming you're using a hash type
          DatabaseInfo = 'INFO;',
        },
      }
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
      { 'kristijanhusak/vim-dadbod-ui' },
      { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true },
    },
  },
}

return M
