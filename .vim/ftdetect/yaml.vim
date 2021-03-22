autocmd BufNewFile,BufRead *yaml setf yaml
function s:DetectKubernetes() abort
  if did_filetype() || &ft != ''
    return
  endif
  let l:first_line = getline(1)
  if l:first_line =~# '^\(kind\|apiVersion\): '
    set filetype=yaml
  endif
endfunction
autocmd BufNewFile,BufRead,BufEnter * call s:DetectKubernetes()
