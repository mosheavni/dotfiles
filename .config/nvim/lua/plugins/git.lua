local T = vim.keycode
local actions_pretty_print = function(message)
  require('user.utils').pretty_print(message, 'Git Actions', '')
end

local function get_branches(remote_name)
  local cmd_output = vim.system({ 'git', 'ls-remote', '--heads', remote_name }):wait()
  -- split cmd_output.stdout by new line
  cmd_output = vim.split(cmd_output.stdout, '\n')
  local branches = {}
  for _, line in ipairs(cmd_output) do
    table.insert(branches, string.match(line, 'heads/(.*)$'))
  end
  return branches
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

local function get_remotes(cb)
  local remotes = vim.fn.FugitiveExecute('remote').stdout
  if #remotes == 2 then
    cb(remotes[1])
  else
    -- remove empty items of the remotes
    for i = #remotes, 1, -1 do
      if remotes[i] == '' then
        table.remove(remotes, i)
      end
    end

    vim.ui.select(remotes, { prompt = 'Select remote: ' }, function(selection)
      if not selection then
        actions_pretty_print 'Canceled.'
        return
      end
      cb(selection)
    end)
  end
end

local actions = function()
  return {
    ['Change branch (F4)'] = function()
      vim.fn.feedkeys(vim.keycode '<F4>')
    end,
    ['Checkout new branch (:Gcb {new_branch})'] = function()
      create_new_branch { args = '' }
    end,
    ['Work in Progress commit (on git window - wip)'] = function()
      vim.cmd 'call Enter_Wip_Moshe()'
      actions_pretty_print 'Created a work in progress commit.'
    end,
    ['First commit of a new branch'] = function()
      vim.cmd 'call First_Commit_Moshe()'
    end,
    ['Set upstream to HEAD'] = function()
      get_remotes(function(remote)
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
      vim.cmd 'Git fetch --all --tags'
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
      get_remotes(function(remote)
        vim.ui.select(get_branches(remote), { prompt = 'Select branch to pull from on ' .. remote .. 'remote: ' }, function(branch_to_pull)
          if not branch_to_pull then
            actions_pretty_print 'Canceled.'
            return
          end
          vim.cmd('Git pull ' .. remote .. ' ' .. branch_to_pull)
          actions_pretty_print('Pulled from ' .. remote .. ' ' .. branch_to_pull)
        end)
      end)
    end,
    ['Merge {remote} {branch}'] = function()
      get_remotes(function(remote)
        vim.ui.select(get_branches(remote), { prompt = 'Select branch to merge with on ' .. remote .. ' remote: ' }, function(branch_to_merge)
          if not branch_to_merge then
            actions_pretty_print 'Canceled.'
            return
          end
          vim.cmd('Git merge ' .. remote .. '/' .. branch_to_merge)
          actions_pretty_print('Merged with ' .. remote .. '/' .. branch_to_merge)
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
      local tags = vim.fn.FugitiveExecute('tag').stdout
      vim.ui.select(tags, { prompt = 'Select tag to copy to clipboard' }, function(selection)
        if not selection then
          actions_pretty_print 'Canceled.'
          return
        end
        vim.fn.setreg('+', selection)
        actions_pretty_print('Copied ' .. selection .. ' to clipboard.')
      end)
    end,
    ['Create tag'] = function()
      vim.ui.input({ prompt = 'Enter tag name to create: ' }, function(input)
        if not input then
          actions_pretty_print 'Canceled.'
          return
        end
        vim.cmd('Git tag ' .. input)
        vim.ui.select({ 'Yes', 'No' }, { prompt = 'Push?' }, function(choice)
          if choice == 'Yes' then
            vim.cmd 'Git push --tags'
            actions_pretty_print('Tag ' .. input .. ' created and pushed.')
          else
            actions_pretty_print('Tag ' .. input .. ' created.')
          end
        end)
      end)
    end,
    ['Delete tag'] = function()
      local tags = vim.fn.FugitiveExecute('tag').stdout

      vim.ui.select(tags, { prompt = 'Enter tag name to delete' }, function(input)
        if not input then
          actions_pretty_print 'Canceled.'
          return
        end
        actions_pretty_print('Deleting tag ' .. input .. ' locally...')
        vim.cmd('Git tag -d ' .. input)
        vim.ui.select({ 'Yes', 'No' }, { prompt = 'Remove from remote?' }, function(choice)
          if choice == 'Yes' then
            get_remotes(function(remote)
              actions_pretty_print('Deleting tag ' .. input .. ' from remote ' .. remote .. '...')
              vim.cmd('Git push ' .. remote .. ' :refs/tags/' .. input)
              actions_pretty_print('Tag ' .. input .. ' deleted from local and remote.')
            end)
          else
            actions_pretty_print('Tag ' .. input .. ' deleted locally.')
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
      get_remotes(function(remote)
        vim.ui.select(get_branches(remote), { prompt = 'Select branch to diff with on ' .. remote .. ' remote: ' }, function(branch_to_diff)
          if not branch_to_diff then
            actions_pretty_print 'Canceled.'
            return
          end
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
  --------------
  -- Fugitive --
  --------------
  vim.cmd [[
" Remove all conflict markers command
"Delete all Git conflict markers
"Creates the command :GremoveConflictMarkers
function! RemoveConflictMarkers() range
  echom a:firstline.'-'.a:lastline
  execute a:firstline.','.a:lastline . ' g/^<\{7}\|^|\{7}\|^=\{7}\|^>\{7}/d'
endfunction
"-range=% default is whole file
command! -range=% GremoveConflictMarkers <line1>,<line2>call RemoveConflictMarkers()


" Better branch choosing using :Gbranch
function! s:changebranch(...)
  let name = a:1
  if name ==? ''
    call inputsave()
    let name = input('Enter branch name: ')
    call inputrestore()
  endif
  execute 'Git checkout ' . name
endfunction

command! -nargs=? Gco call s:changebranch("<args>")

" Push
function! s:MosheGitPush() abort
  echo 'Pushing to ' . FugitiveHead() . '...'
  exe 'Git push -u origin ' . FugitiveHead()
  let l:exit_status = get(FugitiveResult(), 'exit_status', 1)
  if l:exit_status != 0
    echo '🔴 Failed pushing'
  else
    echo '🟢 Pushed!'
  endif
endfunction
command! Gp call <sid>MosheGitPush()
nmap <silent> <leader>gp :Gp<cr>

" Pull
function! s:MosheGitPull() abort
  echo 'Pulling...'
  Git pull --quiet
  let l:exit_status = get(FugitiveResult(), 'exit_status', 1)
  if l:exit_status != 0
    echo '🔴 Failed pulling'
  else
    echo '🟢 Pulled!'
  endif
endfunction
command! -bang Gl call <sid>MosheGitPull()
nmap <silent> <leader>gl :Gl<cr>

function! RandomEmoji() abort
  let l:emojis = [
    \ '🤩',
    \ '👻',
    \ '😈',
    \ '✨',
    \ '👰',
    \ '👑',
    \ '💯',
    \ '💖',
    \ '🌒',
    \ '🇮🇱',
    \ '★',
    \ '⚓️',
    \ '🙉',
    \ '☘️',
    \ '🌍',
    \ '🥨',
    \ '🔥',
    \ '🚀'
  \ ]
  return l:emojis[localtime() % len(l:emojis)]
endfunction

function! Enter_Wip_Moshe() abort
  let l:random_emoji = RandomEmoji()
  let l:time_now = strftime('%c')
  let l:commit_message = l:random_emoji . ' work in progress ' . l:time_now
  echom "Committing: " . l:commit_message
  exe "Git commit --quiet -m '" . l:commit_message . "'"
  exe 'Git push -u origin ' . FugitiveHead()
endfunction

function! First_Commit_Moshe() abort
  let l:head = FugitiveHead()
  echom "Committing: " . l:head
  execute "Git commit --quiet -m " . l:head
  Gp
  silent! !cpr
endfunction

" Autocmd
function! s:ftplugin_fugitive() abort
  " resize 20
  nnoremap <buffer> <silent> <leader>t :vert term<cr>
  nnoremap <buffer> <silent> cc :Git commit --quiet<CR>
  nnoremap <buffer> <silent> gl :Gl<CR>
  nnoremap <buffer> <silent> gp :Gp<CR>
  nnoremap <buffer> <silent> gf :Git fetch --all --tags<CR>
  nnoremap <buffer> <silent> pr :silent! !cpr<CR>
  nnoremap <buffer> <silent> wip :call Enter_Wip_Moshe()<cr>
  nnoremap <buffer> <silent> fc :call First_Commit_Moshe()<cr>
  nnoremap <buffer> <silent> R :e<cr>

endfunction
augroup moshe_fugitive
  autocmd!
  autocmd FileType fugitive call s:ftplugin_fugitive()
augroup END

" Git merge origin master
command! -bang Gmom exe 'Git merge origin/' . 'master'
command! -bang Gpom exe 'Git pull origin ' . 'master'

function! ToggleGStatus()
  if buflisted(bufname('.git/'))
    bd .git/
  else
    Git
    " 17wincmd_
  endif
endfunction
command! ToggleGStatus :call ToggleGStatus()
nnoremap <silent> <leader>gg :ToggleGStatus<cr>
nmap <silent><expr> <leader>gf bufname('.git/index') ? ':exe bufwinnr(bufnr(bufname(".git/index"))) . "wincmd w"<cr>' : '<cmd>Git<cr>'

nnoremap <leader>gc :Gcd <bar> echom "Changed directory to Git root"<bar>pwd<cr>
]]

  -------------------------
  -- Create a new branch --
  -------------------------
  vim.api.nvim_create_user_command('Gcb', create_new_branch, { nargs = '?' })
  vim.keymap.set('n', '<leader>gb', '<cmd>call append(".",FugitiveHead())<cr>')
  vim.keymap.set('n', '<leader>gB', function()
    vim.cmd 'let @+ = FugitiveHead()'
    actions_pretty_print('Copied current branch "' .. vim.fn.FugitiveHead() .. '" to clipboard.')
  end)
  -- redir @">|silent scriptnames|redir END|enew|put

  ----------------------
  -- Git actions menu --
  ----------------------
  -- add default git actions
  require('user.menu').add_actions('Git', vim.tbl_extend('force', actions(), diff_actions()))
  vim.keymap.set('n', '<leader>gm', function()
    local git_actions = require('user.menu').get_actions { prefix = 'Git' }
    vim.ui.select(vim.tbl_keys(git_actions), { prompt = 'Choose git action: ' }, function(choice)
      if choice then
        git_actions[choice]()
      end
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
    'mosheavni/vim-to-github',
    keys = {
      { '<leader>gh', ':ToGithub<cr>', mode = { 'n', 'v' }, desc = 'Open GitHub on this line' },
    },
    cmd = { 'ToGithub' },
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
