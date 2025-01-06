--# selene: allow(undefined_variable)
return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = { enabled = true },
    dashboard = { enabled = false },
    indent = { enabled = false },
    input = { enabled = true },
    notifier = {
      enabled = false,
      timeout = 3000,
    },
    scope = { enabled = false },
    lazygit = { configure = false },
    quickfile = { enabled = true },
    scroll = { enabled = false },
    statuscolumn = { enabled = false },
    words = { enabled = true },
    styles = {
      notification = {
        -- wo = { wrap = true } -- Wrap notifications
      },
    },
  },
  keys = {
    {
      '<leader>.',
      function()
        Snacks.scratch()
      end,
      desc = 'Toggle Scratch Buffer',
    },
    {
      '<leader>S',
      function()
        Snacks.scratch.select()
      end,
      desc = 'Select Scratch Buffer',
    },
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
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-\\><C-n>', true, true, true), 'n', true)
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
    {
      '<leader>N',
      desc = 'Neovim News',
      function()
        Snacks.win {
          file = vim.api.nvim_get_runtime_file('doc/news.txt', false)[1],
          width = 0.6,
          height = 0.6,
          wo = {
            spell = false,
            wrap = false,
            signcolumn = 'yes',
            statuscolumn = ' ',
            conceallevel = 3,
          },
        }
      end,
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
