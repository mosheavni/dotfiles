#!/bin/zsh

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ll='ls -lh'

### General aliases ###
alias zshrc='${=EDITOR} ${ZDOTDIR:-$HOME}/.zshrc' # Quick access to the .zshrc file
alias watch='watch --color '
alias vim="nvim"
alias v='nvim'
alias vi='nvim'
alias sudoedit="nvim"
alias lvim='NVIM_APPNAME=LazyVim nvim'
alias sed=gsed
alias grep=ggrep
alias sort=gsort
alias awk=gawk
alias myip='curl ipv4.icanhazip.com'

alias dotfiles='cd ~/Repos/dotfiles'
alias dc='cd '

# global aliases
alias -g Wt='while :;do '
alias -g Wr=' | while read -r line;do echo "=== $line ==="; '
alias -g D=';done'
alias -g S='| sort'
alias -g SRT='+short | sort'
alias -g Sa='--sort-by=.metadata.creationTimestamp'
alias -g Srt='--sort-by=.metadata.creationTimestamp'
alias -g SECRET='-ojson | jq ".data | with_entries(.value |= @base64d)"'
alias -g IMG='-oyaml | sed -n '\''s/^\s*image:\s\(.*\)/\1/gp'\'' | sort -u'
alias -g YML='-oyaml | vim -c "set filetype=yaml | nnoremap <buffer> q :qall<cr>"'
alias -g NM=' --no-headers -o custom-columns=":metadata.name"'
alias -g RC='--sort-by=".status.containerStatuses[0].restartCount" -A | grep -v "\s0\s"'
alias -g BAD='| grep -v "1/1\|2/2\|3/3\|4/4\|5/5\|6/6\|Completed\|Evicted"'
alias -g IP='-ojsonpath="{.spec.nodeName}"'
alias -g dollar_1_line='$(awk "{print \$1}"<<<"${line}")'
alias -g dollar_2_line='$(awk "{print \$2}"<<<"${line}")'
## Command line head / tail shortcuts
alias -g H='| head'
alias -g T='| tail'
alias -g G='| grep'
alias -g L="| less"
alias -g NE="2> /dev/null"
alias -g NUL="> /dev/null 2>&1"

# see recently pushed branches
# alias gb="git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads | fzf | xargs git checkout && git pull"
alias gb='git for-each-ref --sort=-committerdate --format="%(refname:short)" | grep -n . | sed "s?origin/??g" | sort -t: -k2 -u | sort -n | cut -d: -f2 | fzf | xargs git checkout'

### Shortcuts to directories ###
alias repos="~/Repos"
alias difff='code --diff'

# Common Used tools:
alias tf='terraform'
alias tg='terragrunt'

alias kgevents='kubectl get event --sort-by=.metadata.creationTimestamp | grep -E -v "(Successfully (pulled|assigned)|(Started|Created) container|(Deleted|Created) pod)"'

alias update-nvim-nightly='asdf uninstall neovim nightly && asdf install neovim nightly'
