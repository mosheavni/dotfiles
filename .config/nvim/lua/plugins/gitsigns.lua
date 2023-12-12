local M = {
  'lewis6991/gitsigns.nvim',
  event = 'BufReadPre',
  cmd = { 'Gitsigns' },
  opts = {
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      map('n', ']c', function()
        if vim.wo.diff then
          return ']c'
        end
        vim.schedule(function()
          gs.next_hunk()
        end)
        return '<Ignore>'
      end, { expr = true })

      map('n', '[c', function()
        if vim.wo.diff then
          return '[c'
        end
        vim.schedule(function()
          gs.prev_hunk()
        end)
        return '<Ignore>'
      end, { expr = true })

      -- Actions
      map('n', '<leader>hp', gs.preview_hunk)
      map('n', '<leader>hb', gs.toggle_current_line_blame)
      map('n', '<leader>hd', gs.toggle_deleted)

      -- Text object
      map({ 'o', 'x' }, 'ih', '<cmd>Gitsigns select_hunk<CR>')
    end,
  },
  init = function()
    require('user.menu').add_actions('Git', {
      ['Preview hunk (<leader>hp)'] = function()
        vim.cmd.Gitsigns 'preview_hunk'
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
