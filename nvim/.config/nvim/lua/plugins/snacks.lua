--# selene: allow(undefined_variable)
return {
  'folke/snacks.nvim',
  -- priority = 1000,
  -- lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    quickfile = { enabled = true },
    words = { enabled = true },
    dashboard = { enabled = false },
    indent = { enabled = false },
    input = { enabled = false, win = { row = 12 } },
    notifier = { enabled = false, timeout = 3000 },
    scope = { enabled = false },
    lazygit = { configure = false },
    scroll = { enabled = false },
    statuscolumn = { enabled = false },
  },
  cmd = 'Rename',
  keys = {
    {
      '<leader>bd',
      function()
        Snacks.bufdelete()
      end,
      desc = 'Delete Buffer',
    },
    {
      '<leader>bh',
      function()
        Snacks.bufdelete {
          filter = function(buf)
            return #vim.fn.win_findbuf(buf) == 0
          end,
        }
      end,
      desc = 'Delete Hidden Buffers',
    },
    {
      '<leader>bo',
      function()
        Snacks.bufdelete.other()
      end,
      desc = 'Delete Hidden Buffers',
    },
    {
      '<c-/>',
      function()
        if vim.api.nvim_get_mode().mode == 't' or vim.bo.buftype == 'terminal' then
          vim.api.nvim_feedkeys(vim.keycode '<C-\\><C-n>', 'n', true)
          vim.cmd.close()
        else
          Snacks.terminal.toggle(nil, { cwd = vim.fn.expand '%:p:h' })
        end
      end,
      mode = { 'n', 't' },
      desc = 'Toggle Terminal',
    },
    {
      ']]',
      function()
        Snacks.words.jump(vim.v.count1)
      end,
      desc = 'Next Reference',
      mode = { 'n', 't' },
    },
    {
      '[[',
      function()
        Snacks.words.jump(-vim.v.count1)
      end,
      desc = 'Prev Reference',
      mode = { 'n', 't' },
    },
  },
  init = function()
    vim.api.nvim_create_user_command('Rename', function()
      Snacks.rename.rename_file()
    end, {
      desc = 'Rename file',
    })
  end,
}
