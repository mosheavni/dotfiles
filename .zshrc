export PATH=$PATH:$HOME/bin:/usr/local/bin:$PATH:~/Library/Python/2.7/bin:~/bin:~/.npm-global/bin
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="random"
ZSH_THEME_RANDOM_CANDIDATES=(
  "robbyrussell"
  "dracula"
  "daveverwer"
  "af-magic"
  "dallas"
 )
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
plugins=(
  git
  docker
  common-aliases
  zsh-syntax-highlighting
  zsh-autosuggestions
  zsh-history-substring-search
  aws
  kubectl
  dircycle
  autoupdate
)

source $ZSH/oh-my-zsh.sh

alias vim="nvim"
export EDITOR="nvim"
alias sudoedit="nvim"
alias sed=gsed
alias repos="~/Repos"
alias nginx="~/Repos/boost-ssl-docker"
alias nidock="~/Repos/ni-docker"
alias devops="~/Repos/devops_scripts"
alias www="~/Repos/www.naturalint.com"
alias kb="kubectl"
function docke () { [[ $1 == "r"* ]] && docker ${1#r} }
function opengit () { git remote -v | awk 'NR==1{print $2}' | sed -e "s?:?/?g" -e 's?\.git$??' -e "s?git@?https://?" -e "s?https///?https://?g" | xargs open }
function ssh2 () { [[ $1 == "ip-"* ]] && ( in_url=$(sed -e 's/^ip-//' -e 's/-/./g' <<< "$1" ) ; echo $in_url && ssh $in_url ) || ssh $1 }
function jsonlint () { pbcopy && open https://jsonlint.com/ }

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export LC_CTYPE=en_US.UTF-8
