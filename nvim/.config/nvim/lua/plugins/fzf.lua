return {
  'ibhagwan/fzf-lua',
  keys = {
    { '<c-p>', ':FzfLua files<cr>', silent = true },
    { '<c-b>', ':FzfLua buffers<cr>', silent = true },
    { '<leader>el', ':FzfLua files cwd=' .. vim.fs.joinpath(vim.fn.stdpath 'data', 'lazy') .. '<cr>', silent = true },
    { '<leader>ee', ':FzfLua builtin<cr>', silent = true },
    { '<leader>hh', ':FzfLua help_tags<cr>', silent = true },
    { '<leader>i', ':FzfLua oldfiles<cr>', silent = true },
    {
      '<leader>ccp',
      function()
        local actions = require 'CopilotChat.actions'
        require('CopilotChat.integrations.fzflua').pick(actions.prompt_actions())
      end,
      desc = 'CopilotChat - Prompt actions',
      mode = { 'n', 'v' },
    },
    {
      '<F4>',
      function()
        local utils = require 'fzf-lua.utils'
        local actions = require 'fzf-lua.actions'

        require('fzf-lua').git_branches {
          actions = {
            ['default'] = function(selected)
              actions.git_switch(selected)
              require('user.git').reload_fugitive_index()
            end,
            -- perform checkout instead of switch
            ['ctrl-s'] = {
              fn = function(selected)
                local branch = selected[1]
                local _, ret, stderr = require('user.utils').get_os_command_output({ 'git', 'checkout', branch }, vim.fn.getcwd())
                require('user.git').reload_fugitive_index()
                if ret == 0 then
                  utils.info('Switched to branch ' .. branch)
                  return
                else
                  local msg = string.format('Error when switching to branch: %s. Git returned:\n%s', branch, table.concat(stderr or {}, '\n'))
                  utils.err(msg)
                end
              end,
              reload = false,
              header = 'switch',
            },
            ['ctrl-y'] = {
              fn = function(selected)
                local branch = selected[1]
                vim.fn.setreg('+', branch)
                utils.info('Yanked branch name ' .. branch)
              end,
              reload = false,
              header = 'yank branch name',
            },
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
          multiprocess = true,
          rg_opts = [=[--column --line-number --hidden --no-heading --color=always --smart-case --max-columns=4096 -g '!.git' -e]=],
        }
      end,
    },
  },
  cmd = { 'FzfLua', 'ListFilesFromBranch' },
  config = function()
    require('fzf-lua').setup {
      'default-title',
      previewers = {
        builtin = {
          syntax_limit_b = 1024 * 100, -- 100KB
          extensions = {
            png = { 'viu', '-b' },
            jpg = { 'viu', '-b' },
          },
        },
      },
      oldfiles = {
        cwd_only = true,
        include_current_session = true,
      },
      grep = {
        -- One thing I missed from Telescope was the ability to live_grep and the
        -- run a filter on the filenames.
        -- Ex: Find all occurrences of "enable" but only in the "plugins" directory.
        -- With this change, I can sort of get the same behaviour in live_grep.
        -- ex: > enable --*/plugins/*
        -- I still find this a bit cumbersome. There's probably a better way of doing this.
        rg_glob = true, -- enable glob parsing
        glob_flag = '--iglob', -- case insensitive globs
        glob_separator = '%s%-%-', -- query separator pattern (lua): ' --'
      },
      keymap = { fzf = { ['ctrl-q'] = 'select-all+accept' } },
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

    local list_files_from_branch_action = function(action, selected, o)
      local file = require('fzf-lua').path.entry_to_file(selected[1], o)
      local cmd = string.format('%s %s:%s', action, o.args, file.path)
      vim.cmd(cmd)
    end
    vim.api.nvim_create_user_command('ListFilesFromBranch', function(opts)
      require('fzf-lua').files {
        cmd = 'git ls-tree -r --name-only ' .. opts.args,
        prompt = opts.args .. '> ',
        actions = {
          ['default'] = function(selected, o)
            list_files_from_branch_action('Gedit', selected, o)
          end,
          ['ctrl-s'] = function(selected, o)
            list_files_from_branch_action('Gsplit', selected, o)
          end,
          ['ctrl-v'] = function(selected, o)
            list_files_from_branch_action('Gvsplit', selected, o)
          end,
          ['ctrl-t'] = function(selected, o)
            list_files_from_branch_action('Gtabedit', selected, o)
          end,
        },
        previewer = false,
        preview = {
          type = 'cmd',
          fn = function(items)
            local file = require('fzf-lua').path.entry_to_file(items[1])
            return string.format('git diff %s HEAD -- %s | delta', opts.args, file.path)
          end,
        },
      }
    end, {
      nargs = 1,
      force = true,
      complete = function()
        local branches = vim.fn.systemlist 'git branch --all --sort=-committerdate'
        if vim.v.shell_error == 0 then
          return vim.tbl_map(function(x)
            return x:match('[^%s%*]+'):gsub('^remotes/', '')
          end, branches)
        end
      end,
    })
  end,
}
