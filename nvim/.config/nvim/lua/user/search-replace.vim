if exists('g:loaded_search_replace')
  finish
endif
let g:loaded_search_replace = 1

let s:chars = ['/', '?', '#', ':', '@']
let s:magic_list = ['\v', '\m', '\M', '\V', '']
let s:available_flags = ['g', 'c', 'i']

function! s:should_sar() abort
  return getcmdtype() ==# ':' && get(g:, 'sar_active', v:false)
endfunction

function! s:find_unique_char(chars, str) abort
  for char in a:chars
    if stridx(a:str, char) == -1
      return char
    endif
  endfor
  return ''
endfunction

function! SarPopulateSearchline(mode) abort
  let g:sar_cword = a:mode ==# 'n' ? expand('<cword>') : GetMotion('gv')
  let g:sar_sep = s:find_unique_char(s:chars, g:sar_cword)
  let g:sar_magic = '\V'
  let cmd = '.,$s' . g:sar_sep
    \ . g:sar_magic . g:sar_cword . g:sar_sep
    \ . g:sar_cword . g:sar_sep
    \ . 'gc'
  call setcmdpos(strlen(cmd) - 2)
  let g:sar_active = v:true
  return cmd
endfunction

nnoremap <leader>r :<C-\>eSarPopulateSearchline('n')<CR>
vnoremap <leader>r :<C-\>eSarPopulateSearchline('v')<CR>

function! SarToggleChar(char) abort
  let cmd = getcmdline()
  if !s:should_sar()
    return cmd
  endif

  let sep = get(g:, 'sar_sep', '/')
  let cmd_splitted = split(cmd, sep, 1)
  let cmd_flags = cmd_splitted[-1]
  let cmd_pos = getcmdpos()

  if cmd_flags =~ a:char
    let new_flags = substitute(cmd_flags, a:char, '', '')
  else
    " add the flag
    let new_flags = ''
    for flag in s:available_flags
      if cmd_flags =~ flag || a:char == flag
        let new_flags .= flag
      endif
    endfor
  endif

  let cmd_splitted[-1] = new_flags
  let cmd = join(cmd_splitted, sep)
  call setcmdpos(cmd_pos)
  return cmd
endfunction

function! SarToggleReplaceTerm() abort
  let cmd = getcmdline()
  if !s:should_sar()
    return cmd
  endif

  let sep = get(g:, 'sar_sep', '/')
  let cmd_splitted = split(cmd, sep, 1)
  let g:sar_cword = get(g:, 'sar_cword', cmd_splitted[1])
  let replace_term = cmd_splitted[-2] ==# '' ? g:sar_cword : ''
  let cmd_splitted[-2] = replace_term

  let cmd = join(cmd_splitted, sep)
  call setcmdpos(len(cmd) - len(cmd_splitted[-1]))
  return cmd
endfunction

function! SarToggleAllFile() abort
  let cmd = getcmdline()
  if !s:should_sar()
    return cmd
  endif

  let sep = get(g:, 'sar_sep', '/')
  let cmd_splitted = split(cmd, sep, 1)
  let all_file = cmd_splitted[0]
  let all_file = all_file ==# '%s' ? '.,$s' :
      \ all_file ==# '.,$s' ? '0,.s' : '%s'
  let cmd_splitted[0] = all_file

  let cmd = join(cmd_splitted, sep)
  call setcmdpos(len(cmd) - len(cmd_splitted[-1]))
  return cmd
endfunction

function! SarToggleSeparator() abort
  let cmd = getcmdline()
  if !s:should_sar()
    return cmd
  endif

  let sep = get(g:, 'sar_sep', '/')
  let cmd_splitted = split(cmd, sep, 1)
  let cmd_pos = getcmdpos()
  let new_char_idx = index(s:chars, sep) + 1
  let g:sar_sep = new_char_idx >= len(s:chars) ? s:chars[0] : s:chars[new_char_idx]

  let cmd = join(cmd_splitted, g:sar_sep)
  call setcmdpos(cmd_pos)
  return cmd
endfunction

function! SarToggleMagic() abort
  let cmd = getcmdline()
  if !s:should_sar()
    return cmd
  endif

  let sep = get(g:, 'sar_sep', '/')
  let cmd_splitted = split(cmd, sep, 1)
  let cmd_pos = getcmdpos()
  let g:sar_cword = get(g:, 'sar_cword', cmd_splitted[1])
  let magic = get(g:, 'sar_magic', '\V')
  let new_magic_idx = index(s:magic_list, magic) + 1
  let g:sar_magic = new_magic_idx >= len(s:magic_list) ? s:magic_list[0] : s:magic_list[new_magic_idx]

  let cmd_splitted[1] = g:sar_magic . g:sar_cword
  let cmd = join(cmd_splitted, sep)
  call setcmdpos(cmd_pos)
  return cmd
endfunction

cmap <M-g> <C-\>eSarToggleChar('g')<CR>
cmap <M-c> <C-\>eSarToggleChar('c')<CR>
cmap <M-i> <C-\>eSarToggleChar('i')<CR>
cmap <M-d> <C-\>eSarToggleReplaceTerm()<CR>
cmap <M-5> <C-\>eSarToggleAllFile()<CR>
cmap <M-/> <C-\>eSarToggleSeparator()<CR>
cmap <M-m> <C-\>eSarToggleMagic()<CR>
