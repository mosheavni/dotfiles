export WORDCHARS=""
setopt menu_complete
unsetopt auto_menu
unsetopt case_glob
setopt glob_complete
setopt multios             # enable redirect to multiple streams: echo >file1 >file2
setopt long_list_jobs      # show long list format job notifications
setopt interactivecomments # recognize comments
setopt autocd
setopt complete_in_word

bindkey '^q' push-line

copy-line-to-clipboard() {
    echo -n "$BUFFER" | pbcopy
}
zle -N copy-line-to-clipboard
bindkey '^Y' copy-line-to-clipboard

