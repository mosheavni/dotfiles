return {
  'ibhagwan/fzf-lua',
  opts = {},
  keys = {
    { '<c-p>', ':FzfLua files<cr>' },
    { '<c-b>', ':FzfLua buffers<cr>' },
    { '<leader>hh', ':FzfLua help_tags<cr>' },
    { '<leader>i', ':FzfLua oldfiles<cr>' },
    '<F4>',
    '<leader>/',
  },
  config = function()
    require('fzf-lua').setup {
      oldfiles = {
        cwd_only = true,
      },
      actions = {
        live_grep = {
          ['ctrl-q'] = require('fzf-lua.actions').buf_sel_to_qf,
        },
      },
    }
    require('fzf-lua').register_ui_select(function(_, items)
      local min_h, max_h = 0.15, 0.70
      local h = (#items + 4) / vim.o.lines
      if h < min_h then
        h = min_h
      elseif h > max_h then
        h = max_h
      end
      return { winopts = { height = h, width = 0.60, row = 0.40 } }
    end)

    vim.keymap.set('n', '<leader>/', function()
      require('fzf-lua').live_grep {
        multiprocess = true,
        cmd = [=[rg --column --line-number --hidden --no-heading --color=always --smart-case --max-columns=4096 -g '!.git' -e]=],
      }
    end)
    vim.keymap.set('n', '<F4>', function()
      require('fzf-lua').git_branches {
        cmd = [=[git for-each-ref --sort=-committerdate --format="%(refname:short)" | grep -n . | sed "s?origin/??g" | sort -t: -k2 -u | sort -n | cut -d: -f2]=],
      }
    end)
  end,
}
