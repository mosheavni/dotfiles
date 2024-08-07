vim.cmd [[
function! PopulateSearchline(mode)
  if a:mode == 'n'
    let cword = expand('<cword>')
  else
    let cword = GetMotion('gv')
  endif
  let g:search_and_replace_separator = '/'
  if cword =~# '/'
    let g:search_and_replace_separator = '?'
  endif
  if cword =~# '\?'
    let g:search_and_replace_separator = '#'
  endif
  let cmd = '.,$s' . g:search_and_replace_separator
    \ . '\V' . cword . g:search_and_replace_separator
    \ . cword . g:search_and_replace_separator
    \ . 'gc'
  call setcmdpos(strlen(cmd) - 2)
  return cmd
endfunction
nnoremap <leader>r :<C-\>ePopulateSearchline('n')<CR>
vnoremap <leader>r :<C-\>ePopulateSearchline('v')<CR>

func ToggleChar(char)
  let cmd = getcmdline()
  if getcmdtype() !=# ':'
    return cmd
  endif
  let sep = get(g:, 'search_and_replace_separator', '/')
  let cmd_splitted = split(cmd, sep, 1)
  let cmd_flags = cmd_splitted[-1]
  let cmd_pos = getcmdpos()
  let available_flags = ['g', 'c', 'i']

  if cmd_flags =~ a:char
    " remove the flag
    let new_flags = substitute(cmd_flags, a:char, '', '')
  else
    " add the flag
    let new_flags = ''
    for flag in available_flags
      if cmd_flags =~ flag || a:char == flag
        let new_flags .= flag
      endif
    endfor
  endif

  let cmd = cmd[:-len(cmd_flags) - 1] . new_flags

  " place the cursor on the )
  call setcmdpos(cmd_pos)
  return cmd
endfunc

func DeleteReplaceTerm()
  let cmd = getcmdline()
  if getcmdtype() !=# ':'
    return cmd
  endif
  let sep = get(g:, 'search_and_replace_separator')
  let cmd_splitted = split(cmd, sep, 1)
  let cmd_pos = getcmdpos()
  let cmd_splitted[-2] = ''

  let cmd = join(cmd_splitted, sep)
  call setcmdpos(len(cmd) - len(cmd_splitted[-1]))
  return cmd
endfunc

func ToggleAllFile()
  let cmd = getcmdline()
  if getcmdtype() !=# ':'
    return cmd
  endif
  let sep = get(g:, 'search_and_replace_separator')
  let cmd_splitted = split(cmd, sep, 1)
  let cmd_pos = getcmdpos()
  let all_file = cmd_splitted[0]
  if all_file == '%s'
    let all_file = '.,$s'
  elseif all_file == '.,$s'
    let all_file = '0,.s'
  else
    let all_file = '%s'
  endif
  let cmd_splitted[0] = all_file

  let cmd = join(cmd_splitted, sep)
  call setcmdpos(len(cmd) - len(cmd_splitted[-1]))
  return cmd
endfunc
cmap <M-g> <C-\>eToggleChar('g')<CR>
cmap <M-c> <C-\>eToggleChar('c')<CR>
cmap <M-i> <C-\>eToggleChar('i')<CR>
cmap <M-d> <C-\>eDeleteReplaceTerm()<CR>
cmap <M-5> <C-\>eToggleAllFile()<CR>
]]
