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
      fzf = {
        ['ctrl-q'] = 'select-all+accept',
        ['ctrl-d'] = 'half-page-down',
        ['ctrl-u'] = 'half-page-up',
      },
      builtin = {
        ['<C-w>'] = 'focus-preview',
      },
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
    require('fzf-lua').complete_path { cmd = 'fd --strip-cwd-prefix --hidden --no-ignore' }
  end, { silent = true, desc = 'Fuzzy complete path' })

  local FZF_UI_DEFER = 100

  local function fzf_resume_later()
    vim.defer_fn(function()
      require('fzf-lua').resume()
    end, FZF_UI_DEFER)
  end

  local function fzf_exit_then(fn)
    require('fzf-lua.utils').fzf_exit()
    vim.defer_fn(fn, FZF_UI_DEFER)
  end

  vim.keymap.set('n', '<F4>', function()
    local actions = require 'fzf-lua.actions'
    local git = require 'user.git'
    require('fzf-lua').git_branches {
      header_prefix = '',
      header_separator = '\n',
      actions = {
        ['default'] = {
          fn = function(selected, opts)
            actions.git_switch(selected, opts)
            git.reload_fugitive_index()
          end,
          header = 'switch',
        },
        ['ctrl-s'] = {
          fn = function(selected)
            git.checkout(vim.trim(selected[1]))
          end,
          reload = true,
          header = 'checkout',
        },
        ['ctrl-y'] = {
          fn = function(selected)
            local branch = vim.trim(selected[1])
            vim.fn.setreg('+', branch)
            git.prnt('Yanked branch name ' .. branch)
          end,
          reload = true,
          header = 'yank branch name',
        },
        ['ctrl-r'] = {
          fn = function(selected)
            local branch = vim.trim(selected[1])
            fzf_exit_then(function()
              vim.ui.input({ prompt = 'Rename branch❯ ', default = branch }, function(new_name)
                if not new_name or new_name == '' then
                  git.prnt 'Action aborted'
                  fzf_resume_later()
                  return
                end
                local toplevel = git.get_toplevel_sync()
                git.run_git({ 'branch', '-m', branch, new_name }, 'Renaming branch ' .. branch .. ' to ' .. new_name, function()
                  fzf_resume_later()
                end, { cwd = toplevel })
              end)
            end)
          end,
          header = 'rename',
        },
        ['ctrl-x'] = {
          fn = function(selected)
            local branch = vim.trim(selected[1])
            fzf_exit_then(function()
              vim.ui.select({ 'Yes', 'No' }, { prompt = 'Are you sure you want to delete the branch ' .. branch .. '? ' }, function(yes_or_no)
                if not yes_or_no or yes_or_no == 'No' then
                  git.prnt 'Action aborted'
                  fzf_resume_later()
                  return
                end
                local toplevel = git.get_toplevel_sync()
                git.run_git({ 'branch', '-D', branch }, 'Deleting branch ' .. branch, function(_, code)
                  if code ~= 0 then
                    fzf_resume_later()
                    return
                  end
                  vim.ui.select({ 'Yes', 'No' }, { prompt = 'Delete also from remote? ' }, function(yes_or_no_remote)
                    if not yes_or_no_remote or yes_or_no_remote == 'No' then
                      fzf_resume_later()
                      return
                    end
                    git.run_git({ 'push', 'origin', '--delete', branch }, 'Deleting branch ' .. branch .. ' from remote', function()
                      fzf_resume_later()
                    end, { cwd = toplevel })
                  end)
                end, { cwd = toplevel })
              end)
            end)
          end,
          header = 'delete',
        },
      },
      cmd = 'git-branches.zsh',
    }
  end, { desc = 'Git Branches' })
end
