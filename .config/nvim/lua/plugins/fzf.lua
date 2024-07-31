return {
  'ibhagwan/fzf-lua',
  keys = {
    { '<c-p>', ':FzfLua files<cr>', silent = true },
    { '<c-b>', ':FzfLua buffers<cr>', silent = true },
    { '<leader>hh', ':FzfLua help_tags<cr>', silent = true },
    { '<leader>i', ':FzfLua oldfiles<cr>', silent = true },
    {
      '<F4>',
      function()
        local utils = require 'fzf-lua.utils'
        local path = require 'fzf-lua.path'
        require('fzf-lua').git_branches {
          actions = {
            ['ctrl-r'] = {
              fn = function(selected)
                local branch = selected[1]
                vim.ui.input({ prompt = 'Rename branch: ', default = selected[1] }, function(new_name)
                  if new_name == '' then
                    utils.warn 'Action aborted'
                    return
                  end
                  -- Rename the branch
                  local toplevel = vim.trim(vim.system({ 'git', 'rev-parse', '--show-toplevel' }, { text = true }):wait().stdout)
                  local _, ret, stderr = require('user.utils').get_os_command_output({ 'git', 'branch', '-m', branch, new_name }, toplevel)
                  if ret == 0 then
                    utils.info('Renamed branch ' .. branch .. ' to ' .. new_name)
                    return
                  else
                    local msg = string.format('Error when renaming branch: %s. Git returned:\n%s', branch, table.concat(stderr or {}, '\n'))
                    utils.err(msg)
                  end
                end)
              end,
              reload = true,
              header = 'rename',
            },
            ['ctrl-x'] = {
              fn = function(selected)
                local branch = selected[1]
                vim.ui.select({ 'Yes', 'No' }, { prompt = 'Are you sure you want to delete the branch ' .. branch }, function(yes_or_no)
                  if yes_or_no == 'No' then
                    utils.warn 'Action aborted'
                    return
                  end
                  -- Delete the branch
                  local toplevel = vim.trim(vim.system({ 'git', 'rev-parse', '--show-toplevel' }, { text = true }):wait().stdout)
                  local _, ret, stderr = require('user.utils').get_os_command_output({ 'git', 'branch', '-D', branch }, toplevel)
                  if ret == 0 then
                    utils.info('Deleted branch ' .. branch)
                    vim.ui.select({ 'Yes', 'No' }, { prompt = 'Delete also from remote?' }, function(yes_or_no_remote)
                      if yes_or_no_remote == 'No' then
                        return
                      end
                      -- Delete the branch from remote
                      local _, ret_remote, stderr_remote =
                        require('user.utils').get_os_command_output({ 'git', 'push', 'origin', '--delete', branch }, toplevel)
                      if ret_remote == 0 then
                        utils.info('Deleted branch ' .. branch .. ' from remote')
                        return
                      else
                        local msg =
                          string.format('Error when deleting branch from remote: %s. Git returned:\n%s', branch, table.concat(stderr_remote or {}, '\n'))
                        utils.err(msg)
                      end
                    end)
                    return
                  else
                    local msg = string.format('Error when deleting branch: %s. Git returned:\n%s', branch, table.concat(stderr or {}, '\n'))
                    utils.err(msg)
                  end
                end)
              end,
              reload = true,
              header = 'delete',
            },
          },
          cmd = [=[git for-each-ref --sort=-committerdate --format="%(refname:short)" | grep -n . | sed "s?origin/??g" | sort -t: -k2 -u | sort -n | cut -d: -f2]=],
        }
      end,
    },
    {
      '<leader>/',
      function()
        require('fzf-lua').live_grep {
          keymap = { fzf = { ['ctrl-q'] = 'select-all+accept' } },
          multiprocess = true,
          rg_opts = [=[--column --line-number --hidden --no-heading --color=always --smart-case --max-columns=4096 -g '!.git' -e]=],
        }
      end,
    },
  },
  cmd = 'FzfLua',
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
  end,
}
