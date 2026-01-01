export WORDCHARS=""
setopt menu_complete
unsetopt auto_menu
unsetopt case_glob
setopt glob_complete
setopt multi_os             # enable redirect to multiple streams: echo >file1 >file2
setopt long_list_jobs       # show long list format job notifications
setopt interactive_comments # recognize comments
setopt auto_cd
setopt complete_in_word
setopt notify
setopt numeric_glob_sort # sort numerically when possible (file1 file2 file10)

bindkey '^q' push-line

copy-line-to-clipboard() {
  echo -n "$BUFFER" | pbcopy
}
zle -N copy-line-to-clipboard
bindkey '^Y' copy-line-to-clipboard
