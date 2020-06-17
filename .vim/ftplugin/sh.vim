autocmd BufNewFile,BufReadPost *.sh
setlocal filetype=sh
setlocal foldmethod=indent

inoreabbrev <buffer> while while ;do<cr><tab><cr><c-d><c-d>done<esc>2k0f;hxi

inoreabbrev <buffer> #! #!/bin/bash

inoreabbrev <buffer> case case ~ in<cr><tab>* )  ;;<cr><c-d><c-d>esac<esc>2k0f~hxcw

inoreabbrev <buffer> for for i in ~;do<cr><tab><cr><c-d><c-d>done<esc>2k0f~hxct;

inoreabbrev <buffer> if if [[ ~ ]];then<cr><tab><cr><c-d><c-d>fi<esc>2k0f~hxcw

