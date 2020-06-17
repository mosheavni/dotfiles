setlocal foldmethod=marker
setlocal foldmarker={,}
setlocal fillchars=fold:\ 
setlocal foldtext=getline(v:foldstart)

if did_filetype()
  finish
endif
if getline(1) =~ '^#!.*[/\\]groovy\>'
  setf groovy
endif


