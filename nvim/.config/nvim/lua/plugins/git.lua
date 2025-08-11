local T = vim.keycode
local git_funcs = require 'user.git'
local utils = require 'user.utils'

local actions = function()
  return {
    ['Change branch (F4)'] = function()
      vim.fn.feedkeys(vim.keycode '<F4>')
    end,
    ['Create Pull Request (pr in git buffer)'] = git_funcs.create_pull_request,
    ['Checkout new branch (:Gcb {new_branch})'] = function()
      vim.defer_fn(function()
        git_funcs.create_new_branch { args = '' }
      end, 100)
    end,
    ['Set upstream to HEAD'] = git_funcs.set_upstream_head,
    ['Blame'] = function()
      vim.cmd 'Git blame'
    end,
    ['Print current branch to buffer (<leader>gb)'] = function()
      vim.fn.feedkeys(T '<leader>' .. 'gb')
    end,
    ['Copy current branch to clipboard (<leader>gB)'] = function()
      vim.fn.feedkeys(T '<leader>' .. 'gB')
    end,
    ['Fetch (all remotes and tags)'] = git_funcs.fetch_all,
    ['Pull origin master (:Gpom)'] = function()
      git_funcs.pull_remote_branch('origin', 'master')
    end,
    ['Revert last commit (soft)'] = git_funcs.soft_revert,
    ['Pull {remote} {branch}'] = git_funcs.ui_select_pull_remote_branch,
    ['Merge {remote} {branch}'] = git_funcs.ui_select_merge_remote_branch,
    ['Merge origin/master (:Gmom)'] = function()
      git_funcs.merge_remote_branch('origin', 'master')
    end,
    ['Open Status / Menu (<leader>gg / :Git)'] = function()
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
    ['Create tag'] = git_funcs.ui_select_create_tag,
    ['Delete tag'] = git_funcs.ui_select_delete_tag,
    ['Find in all commits'] = function()
      local rev_list = vim.fn.FugitiveExecute({ 'rev-list', '--all' }).stdout
      vim.defer_fn(function()
        vim.ui.input({ prompt = 'Enter search term: ' }, function(search_term)
          if not search_term then
            git_funcs.prnt 'Canceled.'
            return
          end
          git_funcs.prnt('Searching for ' .. search_term .. ' in all commits...')
          vim.cmd('silent Ggrep ' .. vim.fn.fnameescape(search_term) .. ' ' .. table.concat(rev_list, ' '))
        end)
      end, 100)
    end,
    ['Push (:Gp)'] = git_funcs.push,
    ['Pull (:Gl)'] = git_funcs.pull,
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
    vim.defer_fn(function()
      vim.ui.input({ prompt = 'Enter file path (empty for all files, % for current): ' }, function(file_to_check)
        if not file_to_check then
          return
        end
        vim.cmd('DiffviewFileHistory ' .. file_to_check)
      end)
    end, 100)
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
  ['[Diffview] stashes'] = function()
    vim.cmd 'DiffviewFileHistory -g --range=stash'
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
    local to_close = {}
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == 'fugitive' then
        to_close[#to_close + 1] = win
      end
    end
    if #to_close > 0 then
      for _, win in ipairs(to_close) do
        if vim.api.nvim_win_is_valid(win) then
          pcall(vim.api.nvim_win_close, win, true)
        end
      end
      return
    end
    vim.cmd 'Git'
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

    vim.ui.select(vim.tbl_keys(git_actions), { title = 'Git actions', prompt = 'Choose git action: ' }, function(choice)
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
      'Gco',
      'Git',
      'Gcb',
      'Gl',
      'Gp',
      'Gmom',
      'Gpom',
      'Gread',
      'Gvsplit',
      'Cpr',
    },
  },
  {
    'akinsho/git-conflict.nvim',
    version = '*',
    event = 'BufReadPre',
    config = function()
      ---@diagnostic disable-next-line: missing-fields
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
      {
        '<leader>gd',
        diff_actions['[Diffview] Diff File History'],
        mode = 'n',
        desc = 'Diffview files',
      },
      {
        '<leader>gd',
        ':DiffviewFileHistory<cr>',
        mode = 'v',
        desc = 'Diffview selection',
      },
    },
    config = function()
      require 'diffview'
    end,
  },
}

return M
