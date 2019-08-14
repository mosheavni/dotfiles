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
  aws
  kubectl
  minikube
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
alias nik8s="~/Repos/ni-k8s"
alias difff='code --diff'


alias kb="kubectl"
function kdpw () { watch "kubectl describe po $* | tail -50" }

### Kubernetes Aliases ###
# Kubectl Secrets
alias kgss='kubectl get secret'
alias kdss='kubectl describe secret'
alias kess='kubectl edit secret'
alias kdelss='kubectl delete secret'

# Kubectl Persistent Volume
alias kgpv='kubectl get persistentvolume'
alias kdpv='kubectl describe persistentvolume'
alias kepv='kubectl edit persistentvolume'
alias kdelpv='kubectl delete persistentvolume'

# Kubectl Persistent Volume Claim
alias kgpvc='kubectl get persistentvolumeclaim'
alias kdpvc='kubectl describe persistentvolumeclaim'
alias kepvc='kubectl edit persistentvolumeclaim'
alias kdelpvc='kubectl delete persistentvolumeclaim'

# Functions and more aliases
function jn () {
  open "http://$(kubectl get svc -n jenkins jenkins -o=jsonpath="{ .metadata.annotations.external-dns\.alpha\.kubernetes\.io/hostname }")" && \
        printf $(kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode) | pbcopy
}

function kubedebug () {
  kubectl run $* -i --rm --tty debug --image=ubuntu --restart=Never -- sh
}

###


function docke () { [[ $1 == "r"* ]] && docker ${1#r} }
function opengit () { git remote -v | awk 'NR==1{print $2}' | sed -e "s?:?/?g" -e 's?\.git$??' -e "s?git@?https://?" -e "s?https///?https://?g" | xargs open }
function ssh2 () { [[ $1 == "ip-"* ]] && ( in_url=$(sed -e 's/^ip-//' -e 's/-/./g' <<< "$1" ) ; echo $in_url && ssh $in_url ) || ssh $1 }
function jsonlint () { pbcopy && open https://jsonlint.com/ }
function grl () { grep -rl $* . }

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Set Locale
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

#OktaAWSCLI
if [[ -f "$HOME/.okta/bash_functions" ]]; then
    . "$HOME/.okta/bash_functions"
fi
if [[ -d "$HOME/.okta/bin" && ":$PATH:" != *":$HOME/.okta/bin:"* ]]; then
    PATH="$HOME/.okta/bin:$PATH"
  fi

# Kubectl contexts
alias ctx="source ~/.kube/ctx"
local context
context=$(cat ~/.kube/ctx.conf || ~/.kube/config)
export KUBECONFIG=$context

