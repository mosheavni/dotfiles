local T = vim.keycode

local actions_pretty_print = function(message)
  require('user.utils').pretty_print(message, 'Git Actions', '')
end

local function get_remotes()
  return vim.split(vim.trim(vim.system({ 'git', 'remote' }):wait().stdout), '\n')
end

local function get_branches(remote_name)
  if not remote_name then
    remote_name = 'origin'
  end
  local cmd_output = vim.system({ 'git', 'ls-remote', '--heads', remote_name }):wait()
  cmd_output = vim.split(cmd_output.stdout, '\n')
  local branches = {}
  for _, line in ipairs(cmd_output) do
    table.insert(branches, string.match(line, 'heads/(.*)$'))
  end
  return branches
end

local function get_tags()
  return vim.split(vim.trim(vim.system({ 'git', 'tag' }):wait().stdout), '\n')
end

local function with_ui_select(items, opts, cb)
  vim.ui.select(items, opts, function(selection)
    if not selection then
      actions_pretty_print 'Canceled.'
      return
    end
    cb(selection)
  end)
end

local function ui_select_branches(remote_name, cb)
  with_ui_select(get_branches(remote_name), { prompt = 'Select branch: ' }, cb)
end

local function ui_select_remotes(cb)
  local remotes = get_remotes()
  if #remotes == 1 then
    cb(remotes[1])
  else
    with_ui_select(remotes, { prompt = 'Select remote: ' }, cb)
  end
end

local function ui_select_tags(cb)
  with_ui_select(get_tags(), { prompt = 'Select tag: ' }, cb)
end

local function create_new_branch(branch_opts)
  if branch_opts.args ~= '' then
    return vim.cmd('Git checkout -b ' .. branch_opts.args)
  end
  vim.ui.input({ prompt = 'Enter new branch name: ' }, function(input)
    if not input then
      return
    end
    -- validate branch name regex in lua
    if not string.match(input, '^[a-zA-Z0-9_-]+$') then
      return vim.notify('Invalid branch name', vim.log.levels.ERROR)
    end
    vim.cmd('Git checkout -b ' .. input)
  end)
end

local actions = function()
  return {
    ['Change branch (F4)'] = function()
      vim.fn.feedkeys(vim.keycode '<F4>')
    end,
    ['Checkout new branch (:Gcb {new_branch})'] = function()
      create_new_branch { args = '' }
    end,
    ['Set upstream to HEAD'] = function()
      ui_select_remotes(function(remote)
        vim.cmd('Git branch --set-upstream-to=' .. remote .. '/' .. vim.fn.FugitiveHead())
      end)
    end,
    ['Blame'] = function()
      vim.cmd 'Git blame'
    end,
    ['Print current branch to buffer (<leader>gb)'] = function()
      vim.fn.feedkeys(T '<leader>' .. 'gb')
    end,
    ['Copy current branch to clipboard (<leader>gB)'] = function()
      vim.fn.feedkeys(T '<leader>' .. 'gB')
    end,
    ['Fetch (all remotes and tags)'] = function()
      vim.cmd 'silent Git fetch --all --tags'
    end,
    ['Pull origin master (:Gpom)'] = function()
      vim.cmd 'Gpom'
      actions_pretty_print 'Pulled from origin master.'
    end,
    ['Revert last commit (soft)'] = function()
      vim.cmd 'Git reset --soft HEAD^'
      actions_pretty_print 'Reset to HEAD^'
    end,
    ['Pull {remote} {branch}'] = function()
      ui_select_remotes(function(remote)
        ui_select_branches(remote, function(branch)
          vim.cmd('silent Git pull ' .. remote .. ' ' .. branch)
          actions_pretty_print('Pulled from ' .. remote .. ' ' .. branch)
        end)
      end)
    end,
    ['Merge {remote} {branch}'] = function()
      ui_select_remotes(function(remote)
        ui_select_branches(remote, function(branch)
          with_ui_select({ 'Yes', 'No' }, { prompt = 'Squash? ' }, function(choice)
            if choice == 'No' then
              vim.cmd('silent Git merge ' .. remote .. '/' .. branch)
              actions_pretty_print('Merged with ' .. remote .. '/' .. branch)
              return
            end
            local commit_msg = string.format('"Squashed commits from %s/%s" ', remote, branch)
            vim.cmd('Git merge --squash ' .. remote .. '/' .. branch)
            vim.cmd('Git commit -m ' .. commit_msg)
            actions_pretty_print('Squashed and merged with ' .. remote .. '/' .. branch)
          end)
        end)
      end)
    end,
    ['Merge origin/master (:Gmom)'] = function()
      vim.cmd 'Gmom'
      actions_pretty_print 'Merged with origin/master. (might need to fetch new commits)'
    end,
    ['Open Status / Menu (<leader>gg / :G)'] = function()
      vim.cmd 'Git'
    end,
    ['Open GitHub on this line (<leader>gh or :ToGithub)'] = function()
      vim.cmd 'ToGithub'
    end,
    ['Log'] = function()
      vim.cmd 'Git log --all --decorate --oneline'
    end,
    ['See all tags'] = function()
      ui_select_tags(function(tag)
        vim.fn.setreg('+', tag)
        actions_pretty_print('Copied ' .. tag .. ' to clipboard.')
      end)
    end,
    ['Create tag'] = function()
      vim.ui.input({ prompt = 'Enter tag name to create: ' }, function(tag)
        if not tag then
          actions_pretty_print 'Canceled.'
          return
        end
        vim.cmd('Git tag ' .. tag)
        with_ui_select({ 'Yes', 'No' }, { prompt = 'Push?' }, function(choice)
          if choice == 'Yes' then
            vim.cmd 'Git push --tags'
            actions_pretty_print('Tag ' .. tag .. ' created and pushed.')
          else
            actions_pretty_print('Tag ' .. tag .. ' created.')
          end
        end)
      end)
    end,
    ['Delete tag'] = function()
      ui_select_tags(function(tag)
        actions_pretty_print('Deleting tag ' .. tag .. ' locally...')
        vim.cmd('Git tag -d ' .. tag)
        with_ui_select({ 'Yes', 'No' }, { prompt = 'Delete tag ' .. tag .. ' from remote?' }, function(choice)
          if choice == 'Yes' then
            ui_select_remotes(function(remote)
              actions_pretty_print('Deleting tag ' .. tag .. ' from remote ' .. remote .. '...')
              vim.cmd('Git push ' .. remote .. ' :refs/tags/' .. tag)
              actions_pretty_print('Tag ' .. tag .. ' deleted from local and remote.')
            end)
          else
            actions_pretty_print('Tag ' .. tag .. ' deleted only locally.')
          end
        end)
      end)
    end,
    ['Find in all commits'] = function()
      local rev_list = vim.fn.FugitiveExecute({ 'rev-list', '--all' }).stdout
      vim.ui.input({ prompt = 'Enter search term: ' }, function(search_term)
        if not search_term then
          actions_pretty_print 'Canceled.'
          return
        end
        actions_pretty_print('Searching for ' .. search_term .. ' in all commits...')
        vim.cmd('silent Ggrep ' .. vim.fn.fnameescape(search_term) .. ' ' .. table.concat(rev_list, ' '))
      end)
    end,
    ['Push (:Gp)'] = function()
      vim.cmd.Gp()
    end,
    ['Pull (:Gl)'] = function()
      vim.cmd.Gl()
    end,
    ['Add (Stage) All'] = function()
      vim.cmd 'Git add -A'
    end,
    ['Unstage All'] = function()
      vim.cmd 'Git reset'
    end,
  }
end

local diff_actions = function()
  return {
    ['[Diffview] Diff File History'] = function()
      vim.ui.input({ prompt = 'Enter file path (empty for current file): ' }, function(file_to_check)
        if file_to_check == '' then
          file_to_check = '%'
        end

        vim.cmd('DiffviewFileHistory ' .. file_to_check)
      end)
    end,
    ['[Diffview] Diff with branch'] = function()
      ui_select_remotes(function(remote)
        ui_select_branches(remote, function(branch_to_diff)
          vim.cmd('DiffviewOpen ' .. remote .. '/' .. branch_to_diff .. '..HEAD')
        end)
      end)
    end,
    ['[Diffview] Diff close'] = function()
      vim.cmd 'DiffviewClose'
    end,
  }
end

local fugitive_config = function()
  -----------------
  -- Pull / Push --
  -----------------
  vim.api.nvim_create_user_command('Gp', function()
    local head = vim.fn.FugitiveHead()
    actions_pretty_print('Pushing to ' .. head .. '...')
    vim.cmd 'silent Git push'
    actions_pretty_print('Pushed to ' .. head)
  end, {})
  vim.api.nvim_create_user_command('Gl', function()
    local head = vim.fn.FugitiveHead()
    actions_pretty_print('Pulling from ' .. head .. '...')
    vim.cmd 'silent Git pull'
    actions_pretty_print('Pulled from ' .. head)
  end, {})
  vim.keymap.set('n', '<leader>gp', '<cmd>Gp<cr>')
  vim.keymap.set('n', '<leader>gl', '<cmd>Gl<cr>')
  vim.keymap.set('n', '<leader>gl', '<cmd>Gl<cr>')
  vim.keymap.set('n', '<leader>gf', ':silent Git fetch --all --tags<cr>')

  ---------------------
  -- Toggle fugitive --
  ---------------------
  vim.keymap.set('n', '<leader>gg', function()
    local _, fugitive_buf = pcall(vim.fn.bufname, '.git/')
    if fugitive_buf == '' then
      vim.cmd 'Git'
    else
      local bufnr = vim.fn.bufnr(fugitive_buf)
      if vim.bo[bufnr].buflisted then
        vim.cmd('bd ' .. fugitive_buf)
      else
        vim.cmd 'Git'
      end
    end
  end)

  --------------------------------
  -- Pull / Merge origin master --
  --------------------------------
  vim.api.nvim_create_user_command('Gmom', function()
    vim.cmd 'silent Git merge origin/master'
  end, {})
  vim.api.nvim_create_user_command('Gpom', function()
    vim.cmd 'silent Git pull origin master'
  end, {})

  -------------------------
  -- Create a new branch --
  -------------------------
  vim.api.nvim_create_user_command('Gcb', create_new_branch, { nargs = '?' })
  vim.keymap.set('n', '<leader>gb', '<cmd>call append(".",FugitiveHead())<cr>')
  vim.keymap.set('n', '<leader>gB', function()
    vim.cmd 'let @+ = FugitiveHead()'
    actions_pretty_print('Copied current branch "' .. vim.fn.FugitiveHead() .. '" to clipboard.')
  end)

  ------------------
  -- Git checkout --
  ------------------
  -- TODO: completion not working
  vim.api.nvim_create_user_command('Gco', function(d)
    vim.cmd('Git checkout ' .. d.args)
  end, { nargs = '+', complete = get_branches })

  ----------------------------
  -- Git cd to root of repo --
  ----------------------------
  vim.keymap.set('n', '<leader>gc', function()
    vim.cmd 'Gcd'
    local cwd = vim.fn.getcwd()
    actions_pretty_print('Changed directory to Git root' .. cwd)
  end)

  ----------------------
  -- Git actions menu --
  ----------------------
  -- add default git actions
  require('user.menu').add_actions('Git', vim.tbl_extend('force', actions(), diff_actions()))
  vim.keymap.set('n', '<leader>gm', function()
    local git_actions = require('user.menu').get_actions { prefix = 'Git' }
    with_ui_select(vim.tbl_keys(git_actions), { prompt = 'Choose git action: ' }, function(choice)
      git_actions[choice]()
    end)
  end)
end

local M = {
  {
    'tpope/vim-fugitive',
    config = fugitive_config,
    keys = {
      '<leader>gb',
      '<leader>gB',
      '<leader>gc',
      '<leader>gf',
      '<leader>gg',
      '<leader>gl',
      '<leader>gm',
      '<leader>gp',
    },
    cmd = { 'G', 'Git', 'Gcb', 'Gl', 'Gp', 'Gmom', 'Gpom', 'Gread' },
  },
  {
    'linrongbin16/gitlinker.nvim',
    cmd = { 'GitLink', 'ToGithub' },
    config = function()
      require('gitlinker').setup {
        add_current_line_on_normal_mode = false,
      }
      vim.api.nvim_create_user_command('ToGithub', function()
        vim.cmd 'GitLink!'
      end, { range = true })
    end,
    keys = {
      { '<leader>gy', '<cmd>GitLink<cr>', mode = { 'n', 'v' }, desc = 'Yank git link' },
      { '<leader>gh', '<cmd>GitLink!<cr>', mode = { 'n', 'v' }, desc = 'Open git link' },
    },
  },
  {
    'moyiz/git-dev.nvim',
    opts = {
      ephemeral = false,
      read_only = false,
      opener = function(dir)
        vim.cmd('NvimTreeOpen ' .. vim.fn.fnameescape(dir))
      end,
    },
    keys = {
      {
        '<leader>go',
        function()
          local repo = vim.fn.input 'Repository name / URI: '
          if repo ~= '' then
            require('git-dev').open(repo)
          end
        end,
        desc = '[O]pen a remote git repository',
      },
    },
    config = function(_, opts)
      require('user.menu').add_actions('Git', {
        ['Open a remote git repository (<leader>go)'] = function()
          vim.ui.input({ prompt = 'Enter git repository URL: ' }, function(url)
            if not url then
              return
            end
            require('git-dev').open(url)
          end)
        end,
      })
      require('git-dev').setup(opts)
    end,
  },

  {
    'akinsho/git-conflict.nvim',
    version = '*',
    event = 'BufReadPre',
    config = function()
      require('git-conflict').setup {
        default_mappings = true,
      }
      require('user.menu').add_actions('GitConflict', {
        ['Choose Ours'] = function()
          vim.cmd 'GitConflictChooseOurs'
        end,
        ['Choose Theirs'] = function()
          vim.cmd 'GitConflictChooseTheirs'
        end,
        ['Choose Both'] = function()
          vim.cmd 'GitConflictChooseBoth'
        end,
        ['Choose None'] = function()
          vim.cmd 'GitConflictChooseNone'
        end,
        ['Next Conflict'] = function()
          vim.cmd 'GitConflictNextConflict'
        end,
        ['Previous Conflict'] = function()
          vim.cmd 'GitConflictPrevConflict'
        end,
        ['Send conflicts to Quickfix'] = function()
          vim.cmd 'GitConflictListQf'
        end,
      })
    end,
  },
  {
    'sindrets/diffview.nvim',
    dependencies = 'nvim-lua/plenary.nvim',
    cmd = {
      'DiffviewClose',
      'DiffviewFileHistory',
      'DiffviewFocusFiles',
      'DiffviewLog',
      'DiffviewOpen',
      'DiffviewRefresh',
      'DiffviewToggleFiles',
    },
    config = function()
      require 'diffview'
    end,
  },
}

return M
