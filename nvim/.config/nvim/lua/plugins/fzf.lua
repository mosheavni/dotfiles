vim.pack.add { 'https://github.com/ibhagwan/fzf-lua' }

return function()
  require('fzf-lua').setup {
    header_separator = '\n',
    fzf_opts = {
      ['--cycle'] = true,
      ['--history'] = vim.fn.stdpath 'data' .. '/fzf-lua-history',
    },
    files = { git_icons = true },
    oldfiles = { cwd_only = true, include_current_session = true },
    grep = {
      multiprocess = true,
      RIPGREP_CONFIG_PATH = vim.env.HOME .. '/.ripgreprc',
      rg_glob = true,
      glob_flag = '--iglob',
      glob_separator = '%s%-%-',
      hidden = true,
    },
    keymap = {
      builtin = {
        ['<C-d>'] = 'preview-page-down',
        ['<C-u>'] = 'preview-page-up',
      },
      fzf = { ['ctrl-q'] = 'select-all+accept' },
    },
  }

  require('fzf-lua').register_ui_select(function(opts, items)
    local min_h, max_h = 0.15, 0.70
    local h = (#items + 4) / vim.o.lines
    if h < min_h then
      h = min_h
    elseif h > max_h then
      h = max_h
    end
    opts.title = opts.title or 'Select'
    return { winopts = { title = opts.title, height = h, width = 0.60, row = 0.40 } }
  end)

  vim.keymap.set('n', '<c-p>', ':FzfLua files<cr>', { desc = 'Browse files', silent = true })
  vim.keymap.set('n', '<c-b>', ':FzfLua buffers<cr>', { desc = 'Browse open buffers', silent = true })
  vim.keymap.set('n', '<leader>ee', ':FzfLua builtin<cr>', { desc = 'Browse Fzf builtins', silent = true })
  vim.keymap.set('n', '<leader>hh', ':FzfLua help_tags<cr>', { desc = 'Browse help tags', silent = true })
  vim.keymap.set('n', '<leader>i', ':FzfLua oldfiles<cr>', { desc = 'Browse recent files', silent = true })
  vim.keymap.set('n', '<leader>/', ':FzfLua live_grep<cr>', { desc = 'Live Grep', silent = true })
  vim.keymap.set('n', 'z=', ':FzfLua spell_suggest<cr>', { desc = 'Spelling suggestions', silent = true })
  vim.keymap.set('i', '<C-x><C-f>', function()
    require('fzf-lua').complete_path()
  end, { silent = true, desc = 'Fuzzy complete path' })

  vim.keymap.set('n', '<F4>', function()
    local actions = require 'fzf-lua.actions'
    require('fzf-lua').git_branches {
      header_prefix = '',
      header_separator = '\n',
      actions = {
        ['default'] = {
          fn = function(selected, opts)
            actions.git_switch(selected, opts)
            require('user.git').reload_fugitive_index()
          end,
          header = 'switch',
        },
        ['ctrl-s'] = {
          fn = function(selected)
            require('user.git').checkout(vim.trim(selected[1]))
          end,
          reload = false,
          header = 'checkout',
        },
        ['ctrl-y'] = {
          fn = function(selected)
            local branch = vim.trim(selected[1])
            vim.fn.setreg('+', branch)
            vim.notify('Yanked branch name ' .. branch, vim.log.levels.INFO)
          end,
          reload = false,
          header = 'yank branch name',
        },
        ['ctrl-r'] = {
          fn = function(selected)
            require('fzf-lua.utils').fzf_exit()
            local branch = vim.trim(selected[1])
            vim.defer_fn(function()
              vim.ui.input({ prompt = 'Rename branch❯ ', default = branch }, function(new_name)
                if not new_name or new_name == '' then
                  vim.notify('Action aborted', vim.log.levels.WARN)
                  return
                end
                local toplevel = require('user.git').get_toplevel_sync()
                local result = vim.system({ 'git', 'branch', '-m', branch, new_name }, { text = true, cwd = toplevel }):wait()
                if result.code == 0 then
                  vim.notify('Renamed branch ' .. branch .. ' to ' .. new_name, vim.log.levels.INFO)
                else
                  vim.notify(string.format('Error when renaming branch: %s. Git returned:\n%s', branch, result.stderr or ''), vim.log.levels.ERROR)
                end
              end)
            end, 100)
          end,
          reload = true,
          header = 'rename',
        },
        ['ctrl-x'] = {
          fn = function(selected)
            local branch = vim.trim(selected[1])
            vim.ui.select({ 'Yes', 'No' }, { prompt = 'Are you sure you want to delete the branch ' .. branch .. '? ' }, function(yes_or_no)
              if yes_or_no == 'No' then
                vim.notify('Action aborted', vim.log.levels.WARN)
                return
              end
              local toplevel = require('user.git').get_toplevel_sync()
              local act = vim.system({ 'git', 'branch', '-D', branch }, { text = true, cwd = toplevel }):wait()
              if act.code == 0 then
                vim.notify('Deleted branch ' .. branch, vim.log.levels.INFO)
                vim.ui.select({ 'Yes', 'No' }, { prompt = 'Delete also from remote? ' }, function(yes_or_no_remote)
                  if yes_or_no_remote == 'No' then
                    return
                  end
                  local result_remote = vim.system({ 'git', 'push', 'origin', '--delete', branch }, { text = true, cwd = toplevel }):wait()
                  if result_remote.code == 0 then
                    vim.notify('Deleted branch ' .. branch .. ' from remote', vim.log.levels.INFO)
                  else
                    vim.notify(
                      string.format('Error when deleting branch from remote: %s. Git returned:\n%s', branch, result_remote.stderr or ''),
                      vim.log.levels.ERROR
                    )
                  end
                end)
              else
                vim.notify(string.format('Error when deleting branch: %s. Git returned:\n%s', branch, act.stderr or ''), vim.log.levels.ERROR)
              end
            end)
          end,
          reload = true,
          header = 'delete',
        },
      },
      cmd = 'git-branches.zsh',
    }
  end, { desc = 'Git Branches' })
end
