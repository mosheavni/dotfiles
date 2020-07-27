# # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# # Initialization code that may require console input (password prompts, [y/n]
# # confirmations, etc.) must go above this block; everything else may go below.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

#export PATH=$PATH:$HOME/bin:/usr/local/bin:$PATH:~/Library/Python/2.7/bin:~/bin:~/.npm-global/bin:${KREW_ROOT:-$HOME/.krew}/bin
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="random"
ZSH_THEME_RANDOM_CANDIDATES=(
    "robbyrussell"
    "dracula"
)
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
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
    z
    zsh-autosuggestions
    zsh-syntax-highlighting
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
alias dotfiles='cd ~/src/dotfiles'

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

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Appearance
if command -v jq >/dev/null && command -v cowsay > /dev/null;then
    curl -s -m3 https://official-joke-api.appspot.com/jokes/random | jq -r '"\(.setup)\n\(.punchline)"' | cowsay -f tux
fi

emojis=(🚀 🔥 🍕 👾 🏖 🍔 👻 ⚓ 💥 🌎 ⛄ 🔵 💈 🎲 🌀 🌐)

EMOJI=${emojis[$RANDOM % ${#emojis[@]} ]}
if [[ -f /usr/local/opt/kube-ps1/share/kube-ps1.sh ]];then
    source "/usr/local/opt/kube-ps1/share/kube-ps1.sh"
    function get_cluster_short() {
        echo "$1" | cut -d . -f1
    }
    KUBE_PS1_CLUSTER_FUNCTION=get_cluster_short
    PS1="$PROMPT"'$(kube_ps1)'$'\n'"$EMOJI%b "
else
    PS1="$EMOJI $PROMPT%b  "
fi
ZSH_THEME_GIT_PROMPT_PREFIX="${ZSH_THEME_GIT_PROMPT_PREFIX} "
nvm use stable &

