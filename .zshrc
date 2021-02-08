# # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# # Initialization code that may require console input (password prompts, [y/n]
# # confirmations, etc.) must go above this block; everything else may go below.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

#export PATH=$PATH:$HOME/bin:/usr/local/bin:$PATH:~/Library/Python/2.7/bin:~/bin:~/.npm-global/bin:${KREW_ROOT:-$HOME/.krew}/bin
export PATH="$HOME/.local/alt/shims:$PATH"
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="nirrussell"
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="false"

# Set Locale
export LANG=en_US
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

plugins=(
    ansible
    autoupdate
    aws
    common-aliases
    dircycle
    docker
    git
    kubectl
    minikube
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# Source kube_ps1
if [[ -f /usr/local/opt/kube-ps1/share/kube-ps1.sh ]];then
    source "/usr/local/opt/kube-ps1/share/kube-ps1.sh"
    function get_cluster_short() {
        echo "$1" | gsed -e 's?arn:aws:eks:[a-zA-Z0-9\-]*:[0-9]*:cluster/??g' -e 's?\.k8s\.local??g'
    }
    KUBE_PS1_CLUSTER_FUNCTION=get_cluster_short
fi

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
alias dotfiles='cd ~/src/dotfiles'

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

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

# Appearance
# nvm use stable &

# Fortune cowsay
# if command -v fortune >/dev/null && command -v cowsay > /dev/null;then
#     fortune -a | cowsay -f tux
# fi
# if command -v jq >/dev/null && command -v cowsay > /dev/null;then
#     curl -s -m3 https://official-joke-api.appspot.com/jokes/random | jq -r '"\(.setup)\n\(.punchline)"' | cowsay -f tux
# fi


# EMOJI=${emojis[$RANDOM % ${#emojis[@]} ]}
# PS1="$EMOJI $PS1"
# ZSH_THEME_GIT_PROMPT_PREFIX="${ZSH_THEME_GIT_PROMPT_PREFIX} "

cnf() {
  open "https://command-not-found.com/$*"
}
