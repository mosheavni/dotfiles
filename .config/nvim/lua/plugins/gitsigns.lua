local M = {
  'echasnovski/mini.diff',
  version = false,
  event = 'BufReadPre',
  opts = {
    view = {
      style = 'number',
      signs = {
        add = '┃',
        change = '┃',
        delete = '▁',
      },
    },
  },
  init = function()
    require('user.menu').add_actions('Git', {
      ['Toggle signs (mini.diff)'] = function()
        MiniDiff.toggle(0)
      end,
      ['Toggle current line blame (<leader>hb)'] = function()
        vim.cmd.Gitsigns 'toggle_current_line_blame'
      end,
      ['Toggle deleted (<leader>hd)'] = function()
        vim.cmd.Gitsigns 'toggle_deleted'
      end,
      ['Select hunk'] = function()
        vim.cmd.Gitsigns 'select_hunk'
      end,
    })
  end,
}

return M
