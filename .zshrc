#export PATH=$PATH:$HOME/bin:/usr/local/bin:$PATH:~/Library/Python/2.7/bin:~/bin:~/.npm-global/bin:${KREW_ROOT:-$HOME/.krew}/bin
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
# ZSH_THEME_RANDOM_CANDIDATES=(
#     "robbyrussell"
#     "dracula"
# )
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
plugins=(
    git
    ansible
    docker
    common-aliases
    zsh-autosuggestions
    aws
    kubectl
    minikube
    dircycle
    autoupdate
    zsh-syntax-highlighting
    zsh-nvm
    z
)


source $ZSH/oh-my-zsh.sh
if [[ -f ~/Repos/devops_scripts/aliases/aliases.sh ]];then
    source ~/Repos/devops_scripts/aliases/aliases.sh
fi

autoload -U +X bashcompinit && bashcompinit
alias vim="nvim"
export EDITOR="nvim"
alias sudoedit="nvim"
alias sed=gsed
alias cat='bat'
alias mdl='mdless README.md'
alias tf='terraform'

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
if [[ -f ~/.kube/ctx ]];then
    alias ctx="source ~/.kube/ctx"
    local context
    context=$(cat ~/.kube/ctx.conf || ~/.kube/config)
    export KUBECONFIG=$context
fi

##alias cinfo='kubectl cluster-info'
##function ctx () { kubectx $* && cinfo }
##export KUBECONFIG=~/.kube/config
##for ctx in ~/Dropbox/DevOps/k8s-cluster-contexts/*.config;do
##  export KUBECONFIG=${KUBECONFIG}:${ctx}
##done
#
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

if [[ -f /usr/local/opt/kube-ps1/share/kube-ps1.sh ]];then
    source "/usr/local/opt/kube-ps1/share/kube-ps1.sh"
    # PS1=$PS1'$(kube_ps1): '
    unset POWERLEVEL9K_KUBECONTEXT_SHOW_ON_COMMAND

fi

