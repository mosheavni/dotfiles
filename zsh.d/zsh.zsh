export WORDCHARS=""
setopt menu_complete
unsetopt auto_menu
unsetopt case_glob
setopt glob_complete
setopt multios             # enable redirect to multiple streams: echo >file1 >file2
setopt long_list_jobs      # show long list format job notifications
setopt interactivecomments # recognize comments
setopt autocd
zstyle ':completion:*:*:*:*:*' menu select

bindkey '^q' push-line
