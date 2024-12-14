local T = vim.keycode
local git_funcs = require 'user.git'
local utils = require 'user.utils'

local actions = function()
  return {
    ['Change branch (F4)'] = function()
      vim.fn.feedkeys(vim.keycode '<F4>')
    end,
    ['Create Pull Request'] = function()
      git_funcs.create_pull_request()
    end,
    ['Checkout new branch (:Gcb {new_branch})'] = function()
      git_funcs.create_new_branch { args = '' }
    end,
    ['Set upstream to HEAD'] = function()
      git_funcs.set_upstream_head()
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
      git_funcs.fetch_all()
    end,
    ['Pull origin master (:Gpom)'] = function()
      git_funcs.pull_remote_branch('origin', 'master')
    end,
    ['Revert last commit (soft)'] = function()
      git_funcs.soft_revert()
    end,
    ['Pull {remote} {branch}'] = function()
      git_funcs.ui_select_pull_remote_branch()
    end,
    ['Merge {remote} {branch}'] = function()
      git_funcs.ui_select_merge_remote_branch()
    end,
    ['Merge origin/master (:Gmom)'] = function()
      git_funcs.merge_remote_branch('origin', 'master')
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
      git_funcs.ui_select_tags(function(tag)
        vim.fn.setreg('+', tag)
        git_funcs.prnt('Copied ' .. tag .. ' to clipboard.')
      end)
    end,
    ['Create tag'] = function()
      git_funcs.ui_select_create_tag()
    end,
    ['Delete tag'] = function()
      git_funcs.ui_select_delete_tag()
    end,
    ['Find in all commits'] = function()
      local rev_list = vim.fn.FugitiveExecute({ 'rev-list', '--all' }).stdout
      vim.ui.input({ prompt = 'Enter search term: ' }, function(search_term)
        if not search_term then
          git_funcs.prnt 'Canceled.'
          return
        end
        git_funcs.prnt('Searching for ' .. search_term .. ' in all commits...')
        vim.cmd('silent Ggrep ' .. vim.fn.fnameescape(search_term) .. ' ' .. table.concat(rev_list, ' '))
      end)
    end,
    ['Push (:Gp)'] = function()
      git_funcs.push()
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

local diff_actions = {
  ['[Diffview] Diff File History'] = function()
    vim.ui.input({ prompt = 'Enter file path (empty for all files, % for current): ' }, function(file_to_check)
      vim.cmd('DiffviewFileHistory ' .. file_to_check)
    end)
  end,
  ['[Diffview] Diff with branch'] = function()
    git_funcs.ui_select_remotes(function(remote)
      git_funcs.ui_select_branches(remote, function(branch_to_diff)
        vim.cmd('DiffviewOpen ' .. remote .. '/' .. branch_to_diff .. '..HEAD')
      end)
    end)
  end,
  ['[Diffview] Diff close'] = function()
    vim.cmd 'DiffviewClose'
  end,
}

local fugitive_config = function()
  -----------------
  -- Pull / Push --
  -----------------
  vim.api.nvim_create_user_command('Gp', git_funcs.push, {})
  vim.keymap.set('n', '<leader>gp', '<cmd>Gp<cr>')
  vim.api.nvim_create_user_command('Gl', git_funcs.pull, {})
  vim.keymap.set('n', '<leader>gl', '<cmd>Gl<cr>')
  vim.api.nvim_create_user_command('Gf', git_funcs.fetch_all, {})
  vim.keymap.set('n', '<leader>gf', '<cmd>Gf<cr>')

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
    git_funcs.merge_remote_branch('origin', 'master')
  end, {})
  vim.api.nvim_create_user_command('Gpom', function()
    git_funcs.pull_remote_branch('origin', 'master')
  end, {})

  -------------------------
  -- Create a new branch --
  -------------------------
  vim.api.nvim_create_user_command('Gcb', git_funcs.create_new_branch, { nargs = '?' })
  vim.keymap.set('n', '<leader>gb', function()
    git_funcs.get_branch(function(branch)
      -- Set the new line
      vim.schedule(function()
        local current_line = vim.api.nvim_get_current_line()
        local new_line = current_line .. branch
        vim.api.nvim_set_current_line(new_line)
      end)
    end)
  end)
  vim.keymap.set('n', '<leader>gB', function()
    git_funcs.get_branch(function(branch)
      vim.schedule(function()
        vim.fn.setreg('+', branch)
        git_funcs.prnt('Copied current branch "' .. branch .. '" to clipboard.')
      end)
    end)
  end)

  ------------------
  -- Git checkout --
  ------------------
  vim.api.nvim_create_user_command('Gco', function(d)
    vim.cmd('Git checkout ' .. d.args)
  end, {
    nargs = '+',
    complete = function()
      return git_funcs.get_branches_sync()
    end,
  })

  ----------------------------
  -- Git cd to root of repo --
  ----------------------------
  vim.keymap.set('n', '<leader>gc', function()
    vim.cmd 'Gcd'
    local cwd = vim.fn.getcwd()
    git_funcs.prnt('Changed directory to Git root' .. cwd)
  end)

  -------------------------
  -- Create Pull Request --
  -------------------------
  vim.api.nvim_create_user_command('Cpr', git_funcs.create_pull_request, {})

  ----------------------
  -- Git actions menu --
  ----------------------
  -- add default git actions
  require('user.menu').add_actions('Git', vim.tbl_extend('force', actions(), diff_actions))
  vim.keymap.set('n', '<leader>gm', function()
    local git_actions = require('user.menu').get_actions { prefix = 'Git' }

    vim.ui.select(vim.tbl_keys(git_actions), { prompt = 'Choose git action: ' }, function(choice)
      if not choice then
        utils.pretty_print('Canceled.', 'Git Actions', '')
        return
      end
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
    cmd = {
      'G',
      'Gco',
      'Git',
      'Gcb',
      'Gl',
      'Gp',
      'Gmom',
      'Gpom',
      'Gread',
      'Cpr',
    },
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
    keys = {
      -- { '<leader>gd', '<cmd>DiffviewFileHistory<cr>', mode = { 'n', 'v' }, desc = 'Diffview files' },
      { '<leader>gd', diff_actions['[Diffview] Diff File History'], mode = 'n', desc = 'Diffview files' },
      { '<leader>gd', ':DiffviewFileHistory<cr>', mode = 'v', desc = 'Diffview selection' },
    },
    config = function()
      require 'diffview'
    end,
  },
}

return M
