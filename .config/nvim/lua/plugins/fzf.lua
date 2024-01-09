return {
  'ibhagwan/fzf-lua',
  keys = {
    { '<c-p>', ':FzfLua files<cr>', silent = true },
    { '<c-b>', ':FzfLua buffers<cr>', silent = true },
    { '<leader>hh', ':FzfLua help_tags<cr>', silent = true },
    { '<leader>i', ':FzfLua oldfiles<cr>', silent = true },
    '<F4>',
    '<leader>/',
  },
  config = function()
    require('fzf-lua').setup {
      oldfiles = {
        cwd_only = true,
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
        keymap = { fzf = { ['ctrl-q'] = 'select-all+accept' } },
        multiprocess = true,
        rg_opts = [=[--column --line-number --hidden --no-heading --color=always --smart-case --max-columns=4096 -g '!.git' -e]=],
      }
    end)
    vim.keymap.set('n', '<F4>', function()
      require('fzf-lua').git_branches {
        actions = {
          ['ctrl-d'] = function(selected)
            vim.ui.select({ 'Yes', 'No' }, { prompt = 'Are you sure you want to delete the branch ' .. selected[1] }, function(yes_or_no)
              if yes_or_no == 'No' then
                require('fzf-lua.utils').warn 'Action aborted'
                return
              end
              -- Delete the branch
              local toplevel = vim.trim(vim.system({ 'git', 'rev-parse', '--show-toplevel' }, { text = true }):wait().stdout)
              local _, ret, stderr = require('user.utils').get_os_command_output({ 'git', 'branch', '-D', selected[1] }, toplevel)
              if ret == 0 then
                require('fzf-lua.utils').info('Deleted branch ' .. selected[1])
                return
              else
                local msg = string.format('Error when deleting branch: %s. Git returned:\n%s', branch, table.concat(stderr, '\n'))
                require('fzf-lua.utils').err(msg)
              end
              return ret == 0
            end)
          end,
        },
        cmd = [=[git for-each-ref --sort=-committerdate --format="%(refname:short)" | grep -n . | sed "s?origin/??g" | sort -t: -k2 -u | sort -n | cut -d: -f2]=],
      }
    end)
  end,
}
