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
  exe 'Git! push -u origin ' . FugitiveHead()
  let l:exit_status = get(FugitiveResult(), 'exit_status', 1)
  if l:exit_status != 0
    echo 'Failed pushing 😒'
  else
    echo 'Pushed! 🤩'
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
    echo 'Failed pulling 😒'
  else
    echo 'Pulled! 😎'
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
  let l:commit_message = l:random_emoji . ' wip ' . l:time_now
  echom "Committing: " . l:commit_message
  exe "G commit --quiet -m '" . l:commit_message . "'"
  exe 'Git! push -u origin ' . FugitiveHead()
endfunction

" Autocmd
function! s:ftplugin_fugitive() abort
  nnoremap <buffer> <silent> cc :Git commit --quiet<CR>
  nnoremap <buffer> <silent> gl :Gl<CR>
  nnoremap <buffer> <silent> gp :Gp<CR>
  nnoremap <buffer> <silent> pr :silent! !cpr<CR>
  nnoremap <buffer> <silent> wip :call Enter_Wip_Moshe()<cr>

endfunction
augroup moshe_fugitive
  autocmd!
  autocmd FileType fugitive call s:ftplugin_fugitive()
augroup END

" Git merge origin master
command! -bang Gmom exe 'G merge origin/' . 'master'
command! -bang Gpom exe 'G pull origin ' . 'master'

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
nmap <silent><expr> <leader>gf bufname('.git/index') ? ':exe bufwinnr(bufnr(bufname(".git/index"))) . "wincmd w"<cr>' : ':Git<cr>'

nnoremap <leader>gc :Gcd <bar> echom "Changed directory to Git root"<bar>pwd<cr>

" Gdiffrev
nmap <leader>dh :DiffHistory<Space>
command! -nargs=? DiffHistory call s:view_git_history('<args>')
command! DiffFile call s:view_git_history('current_file')
nmap <silent> <leader>gh :DiffFile<cr>

function! s:view_git_history(...) abort
  let branch_name = a:1
  if branch_name ==# 'current_file'
    0Gclog
  elseif branch_name !=? ''
    execute 'Git difftool --name-only ' . branch_name . '...@'
  else
    Git difftool --name-only ! !^@
  endif
  call s:diff_current_quickfix_entry()
  " Bind <CR> for current quickfix window to properly set up diff split layout after selecting an item
  " There's probably a better way to map this without changing the window
  copen
  nnoremap <buffer> <CR> <CR><BAR>:call <sid>diff_current_quickfix_entry()<CR>
  wincmd p
endfunction

function s:diff_current_quickfix_entry() abort
  " Cleanup windows
  for window in getwininfo()
    if window.winnr !=? winnr() && bufname(window.bufnr) =~? '^fugitive:'
      exe 'bdelete' window.bufnr
    endif
  endfor
  cc
  call s:add_mappings()
  let qf = getqflist({'context': 0, 'idx': 0})
  if get(qf, 'idx') && type(get(qf, 'context')) == type({}) && type(get(qf.context, 'items')) == type([])
    let diff = get(qf.context.items[qf.idx - 1], 'diff', [])
    for i in reverse(range(len(diff)))
      exe (i ? 'leftabove' : 'rightbelow') 'vert diffsplit' fnameescape(diff[i].filename)
      call s:add_mappings()
    endfor
  endif
endfunction

function! s:add_mappings() abort
  nnoremap <buffer>]q :cnext <BAR> :call <sid>diff_current_quickfix_entry()<CR>
  nnoremap <buffer>[q :cprevious <BAR> :call <sid>diff_current_quickfix_entry()<CR>
  " Reset quickfix height. Sometimes it messes up after selecting another item
  11copen
  wincmd p
endfunction
]]

local new_branch = function(branch_opts)
  if branch_opts.args ~= '' then
    return vim.cmd('Git checkout -b ' .. branch_opts.args)
  end
  vim.ui.input({ prompt = 'Enter new branch name: ' }, function(input)
    if not input then
      return
    end
    vim.cmd('Git checkout -b ' .. input)
  end)
end
vim.api.nvim_create_user_command('Gcb', new_branch, { nargs = '?' })
vim.keymap.set('n', '<leader>gb', '<cmd>call append(".",FugitiveHead())<cr>')
-- redir @">|silent scriptnames|redir END|enew|put

-- Git actions menu
local pretty_print = function(message)
  vim.notify(message, 2, { title = 'Git Actions', icon = '' })
end
local git_actions = {
  ['Change branch'] = function()
    require('user.git-branches').open()
  end,
  ['Checkout new branch'] = function()
    new_branch { args = '' }
  end,
  ['Work in Progress commit'] = function()
    vim.cmd 'call Enter_Wip_Moshe()'
    pretty_print 'Created a work in progress commit.'
  end,
  ['Diff File History'] = function()
    vim.cmd 'DiffviewFileHistory %'
  end,
  ['Diff with branch'] = function()
    vim.ui.input({ prompt = 'Enter branch to diff with' }, function(branch_to_diff)
      if not branch_to_diff then
        pretty_print 'Canceled.'
        return
      end
      vim.cmd('DiffviewOpen ' .. branch_to_diff)
    end)
  end,
  ['Diff close'] = function()
    vim.cmd 'DiffviewClose'
  end,
  ['Pull origin master'] = function()
    vim.cmd 'Gpom'
    pretty_print 'Pulled from origin master.'
  end,
  ['Pull origin {branch}'] = function()
    vim.ui.input({ prompt = 'Enter branch to pull from' }, function(branch_to_pull)
      if not branch_to_pull then
        pretty_print 'Canceled.'
        return
      end
      vim.cmd('G pull origin ' .. branch_to_pull)
      pretty_print('Pulled from origin ' .. branch_to_pull)
    end)
  end,
  ['Merge origin/master'] = function()
    vim.cmd 'Gmom'
    pretty_print 'Merged with origin/master. (might need to fetch new commits)'
  end,
  ['Status'] = function()
    vim.cmd 'Git'
  end,
  ['Log'] = function()
    vim.cmd 'G log --all --decorate --oneline'
  end,
  ['Create tag'] = function()
    vim.ui.input({ prompt = 'Enter tag name' }, function(input)
      if not input then
        pretty_print 'Canceled.'
        return
      end
      vim.cmd('G tag ' .. input)
      vim.ui.select({ 'Yes', 'No' }, { prompt = 'Push?' }, function(choice)
        if choice == 'Yes' then
          vim.cmd 'G push --tags'
          pretty_print('Tag ' .. input .. ' created and pushed.')
        else
          pretty_print('Tag ' .. input .. ' created.')
        end
      end)
    end)
  end,
  ['Delete tag'] = function()
    local tags_unparsed = vim.api.nvim_exec('for i in FugitiveExecute("tag").stdout|echo i|endfor', true)
    local tags = vim.split(vim.trim(tags_unparsed), '\n')

    vim.ui.select(tags, { prompt = 'Enter tag name' }, function(input)
      if not input then
        pretty_print 'Canceled.'
        return
      end
      vim.cmd('G tag -d ' .. input)
      vim.ui.select({ 'Yes', 'No' }, { prompt = 'Remove from remote?' }, function(choice)
        if choice == 'Yes' then
          vim.cmd 'G push --tags'
          if not vim.g.default_branch then
            pretty_print 'default_branch is not set'
            return
          end
          vim.cmd('G push origin ' .. vim.g.default_branch .. ' :refs/tags/' .. input)
          pretty_print('Tag ' .. input .. ' deleted from local and remote.')
        else
          pretty_print('Tag ' .. input .. ' deleted locally.')
        end
      end)
    end)
  end,
}
vim.keymap.set('n', '<leader>gm', function()
  vim.ui.select(vim.tbl_keys(git_actions), { prompt = 'Choose git action' }, function(choice)
    if choice then
      git_actions[choice]()
    end
  end)
end)
-- pcall(require, 'vim-fugitive')
-- vim.fn.FugitiveExecute({ 'remote', 'show', vim.fn.FugitiveRemote().remote_name }, function(res)
--   local default_branch = 'master'
--   local remote_output = res.stdout
--   for _, value in pairs(remote_output) do
--     local found = value:match 's*HEAD.*'
--     if found then
--       local splitted = vim.split(found, ' ')
--       default_branch = splitted[#splitted]
--     end
--   end
--   vim.g.default_branch = default_branch
-- end)
