local M = {
  'lewis6991/gitsigns.nvim',
  event = 'BufReadPre',
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
}

return M
