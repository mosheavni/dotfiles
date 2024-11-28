if exists('g:loaded_search_replace')
  finish
endif
let g:loaded_search_replace = 1

let s:chars = ['/', '?', '#', ':', '@']

function! s:should_sar()
  if getcmdtype() !=# ':' || get(g:, 'sar_active', v:false) == v:false
    return v:false
  endif
  return v:true
endfunction

function! s:find_unique_char(chars, str)
    " Iterate through each character in the list
    for char in a:chars
        " Check if the character is not in the string
        if stridx(a:str, char) == -1
            return char
        endif
    endfor
    " If all characters are found in the string, return an appropriate value
    return ''
endfunction

function! SarPopulateSearchline(mode)
  if a:mode ==# 'n'
    let g:sar_cword = expand('<cword>')
  else
    let g:sar_cword = GetMotion('gv')
  endif
  " Define a list of characters
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

func SarToggleChar(char)
  let cmd = getcmdline()
  if !s:should_sar()
    return cmd
  endif

  let sep = get(g:, 'sar_sep', '/')
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

  let cmd_splitted[-1] = new_flags
  let cmd = join(cmd_splitted, sep)
  " let cmd = cmd[:-len(cmd_flags) - 1] . new_flags

  " place the cursor on the )
  call setcmdpos(cmd_pos)
  return cmd
endfunc

func SarToggleReplaceTerm()
  let cmd = getcmdline()
  if !s:should_sar()
    return cmd
  endif
  let sep = get(g:, 'sar_sep', '/')
  let cmd_splitted = split(cmd, sep, 1)
  let sar_cword = get(g:, 'sar_cword')
  if empty(sar_cword)
    let sar_cword = cmd_splitted[1]
    let g:sar_cword = sar_cword
  endif
  let cmd_pos = getcmdpos()
  let replace_term = cmd_splitted[-2]
  if replace_term ==# ''
    let replace_term = g:sar_cword
  else
    let replace_term = ''
  endif
  let cmd_splitted[-2] = replace_term

  let cmd = join(cmd_splitted, sep)
  call setcmdpos(len(cmd) - len(cmd_splitted[-1]))
  return cmd
endfunc

func SarToggleAllFile()
  let cmd = getcmdline()
  if !s:should_sar()
    return cmd
  endif
  let sep = get(g:, 'sar_sep', '/')
  let cmd_splitted = split(cmd, sep, 1)
  let cmd_pos = getcmdpos()
  let all_file = cmd_splitted[0]
  if all_file ==# '%s'
    let all_file = '.,$s'
  elseif all_file ==# '.,$s'
    let all_file = '0,.s'
  else
    let all_file = '%s'
  endif
  let cmd_splitted[0] = all_file

  let cmd = join(cmd_splitted, sep)
  call setcmdpos(len(cmd) - len(cmd_splitted[-1]))
  return cmd
endfunc

func SarToggleSeparator()
  let cmd = getcmdline()
  if !s:should_sar()
    return cmd
  endif
  let sep = get(g:, 'sar_sep', '/')
  let cmd_splitted = split(cmd, sep, 1)
  let cmd_pos = getcmdpos()
  let new_char_idx = index(s:chars, sep) + 1
  let new_sep = new_char_idx >= len(s:chars) ? s:chars[0] : s:chars[new_char_idx]
  let g:sar_sep = new_sep
  let cmd = join(cmd_splitted, new_sep)
  call setcmdpos(cmd_pos)
  return cmd
endfunc

func SarToggleMagic()
  let cmd = getcmdline()
  if !s:should_sar()
    return cmd
  endif
  let magic_list = ['\v', '\m', '\M', '\V', '']
  let sep = get(g:, 'sar_sep', '/')
  let cmd_splitted = split(cmd, sep, 1)
  let cmd_pos = getcmdpos()

  " cword
  let sar_cword = get(g:, 'sar_cword')
  if empty(sar_cword)
    let sar_cword = cmd_splitted[1]
    let g:sar_cword = sar_cword
  endif

  " magic
  let magic = get(g:, 'sar_magic', '\V')
  let new_magic_idx = index(magic_list, magic) + 1
  let new_magic = new_magic_idx >= len(magic_list) ? magic_list[0] : magic_list[new_magic_idx]
  let g:sar_magic = new_magic


  let cmd_splitted[1] = new_magic . sar_cword
  let cmd = join(cmd_splitted, sep)
  call setcmdpos(cmd_pos)
  return cmd
endfunc

cmap <M-g> <C-\>eSarToggleChar('g')<CR>
cmap <M-c> <C-\>eSarToggleChar('c')<CR>
cmap <M-i> <C-\>eSarToggleChar('i')<CR>
cmap <M-d> <C-\>eSarToggleReplaceTerm()<CR>
cmap <M-5> <C-\>eSarToggleAllFile()<CR>
cmap <M-/> <C-\>eSarToggleSeparator()<CR>
cmap <M-m> <C-\>eSarToggleMagic()<CR>

